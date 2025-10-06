// Deno Deploy (Supabase Edge) Stripe webhook to update order status and adjust inventory
// Events handled -> status mapping:
// 'payment_intent.succeeded': 'in_queue'
// 'payment_intent.payment_failed': 'cancelled'
// 'payment_intent.canceled': 'cancelled'
// 'charge.succeeded': 'in_queue'
// 'charge.failed': 'cancelled'
// 'charge.dispute.created': 'disputed'
// 'charge.dispute.closed': 'in_queue'
// 'invoice.payment_succeeded': 'in_queue'
// 'invoice.payment_failed': 'cancelled'
// 'customer.subscription.deleted': 'cancelled'

import Stripe from "stripe";

// Use dynamic import for Supabase JS compatible with Deno
const { createClient } = await import('https://esm.sh/@supabase/supabase-js@2');

const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY") ?? "";
const STRIPE_WEBHOOK_SECRET = Deno.env.get("STRIPE_WEBHOOK_SECRET") ?? ""; // optional but recommended

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const stripe = new Stripe(STRIPE_SECRET_KEY, {
  apiVersion: "2024-06-20",
});

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

type Status = 'in_queue' | 'in_progress' | 'delivered' | 'cancelled' | 'disputed';

const eventTypeToStatus: Record<string, Status | undefined> = {
  'payment_intent.succeeded': 'in_queue',
  'payment_intent.payment_failed': 'cancelled',
  'payment_intent.canceled': 'cancelled',
  'charge.succeeded': 'in_queue',
  'charge.failed': 'cancelled',
  'charge.dispute.created': 'disputed',
  'charge.dispute.closed': 'in_queue',
  'invoice.payment_succeeded': 'in_queue',
  'invoice.payment_failed': 'cancelled',
  'customer.subscription.deleted': 'cancelled',
};

function extractPaymentIntentId(event: Stripe.Event): string | null {
  const obj = event.data?.object as any;
  if (!obj) return null;
  // Prefer payment_intent field if present
  if (typeof obj.payment_intent === 'string') return obj.payment_intent;
  if (typeof obj.id === 'string' && event.type.startsWith('payment_intent.')) return obj.id;
  // From charge events
  if (typeof obj.payment_intent === 'object' && obj.payment_intent?.id) return obj.payment_intent.id;
  // From invoice events
  if (typeof obj.payment_intent === 'string') return obj.payment_intent;
  return null;
}

function extractOrderId(event: Stripe.Event): string | null {
  const obj = event.data?.object as any;
  if (!obj) return null;
  const orderId = obj.metadata?.order_id || obj.metadata?.orderId;
  return typeof orderId === 'string' ? orderId : null;
}

async function notifyZippers(orderId: string | null): Promise<void> {
  console.log('🔔 Notifying zippers of new order...');

  // Query zippers table to get all zipper IDs
  const { data: zippers, error: zippersError } = await supabase
    .from('zippers')
    .select('id');

  if (zippersError) {
    console.error('Error fetching zippers:', zippersError.message);
    throw zippersError;
  }

  if (!zippers || zippers.length === 0) {
    console.log('No zippers found in database');
    return;
  }

  const zipperIds = zippers.map(z => z.id);
  console.log(`Found ${zipperIds.length} zipper(s)`);

  // Query fcm_tokens table to get tokens for these zipper IDs
  const { data: fcmTokens, error: tokensError } = await supabase
    .from('fcm_tokens')
    .select('token')
    .in('user_id', zipperIds);

  if (tokensError) {
    console.error('Error fetching FCM tokens:', tokensError.message);
    throw tokensError;
  }

  if (!fcmTokens || fcmTokens.length === 0) {
    console.log('No FCM tokens found for zippers');
    return;
  }

  const tokens = fcmTokens.map(t => t.token);
  console.log(`Found ${tokens.length} FCM token(s) for zippers`);

  // Invoke push edge function
  // Ensure SUPABASE_URL doesn't already end with /functions/v1
  let baseUrl = SUPABASE_URL;
  if (baseUrl.endsWith('/')) {
    baseUrl = baseUrl.slice(0, -1);
  }
  const zipPushUrl = `${baseUrl}/functions/v1/push`;
  
  console.log(`📤 Invoking push function at URL: ${zipPushUrl}`);
  
  const payload = {
    fcm_tokens: tokens,
    title: '🚀 New Order!',
    body: orderId ? `Order #${orderId.substring(0, 8)} needs to be fulfilled` : 'A new order needs to be fulfilled',
    data: {
      type: 'new_order',
      order_id: orderId || '',
      timestamp: new Date().toISOString()
    },
    priority: 'high',
    sound: 'default',
    badge: 1
  };

  console.log('📤 Payload:', JSON.stringify(payload, null, 2));
  
  const response = await fetch(zipPushUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
    },
    body: JSON.stringify(payload)
  });

  console.log(`📡 Response status: ${response.status} ${response.statusText}`);

  if (!response.ok) {
    const errorText = await response.text();
    console.error('❌ push invocation failed:', errorText);
    
    // Special handling for 404 - function might not be deployed
    if (response.status === 404) {
      console.error('❌ push function not found. Please ensure the push edge function is deployed to Supabase.');
      console.error('❌ Deploy command: supabase functions deploy push');
    }
    
    throw new Error(`push failed: ${response.status} ${errorText}`);
  }

  const result = await response.json();
  console.log('✅ push invocation successful:', result);
}

async function handle(event: Stripe.Event): Promise<Response> {
  const status = eventTypeToStatus[event.type];
  if (!status) {
    // Not relevant; acknowledge
    console.log('Skipping unsupported event type:', event.type);
    return new Response(JSON.stringify({ ok: true, skipped: true }), { status: 200, headers: { 'Content-Type': 'application/json' } });
  }

  const paymentIntentId = extractPaymentIntentId(event);
  const orderId = extractOrderId(event);
  if (!paymentIntentId && !orderId) {
    console.warn('Missing identifiers for event:', event.type);
    return new Response(JSON.stringify({ ok: false, error: 'missing_identifiers' }), { status: 200, headers: { 'Content-Type': 'application/json' } });
  }

  // Call SQL function to update order status and inventory
  console.log('Processing event:', { type: event.type, mappedStatus: status, paymentIntentId, orderId });

  let data: any = null;
  let error: any = null;
  if (paymentIntentId) {
    ({ data, error } = await supabase.rpc('update_order_status_and_inventory', {
      p_payment_intent_id: paymentIntentId,
      p_new_status: status,
    }));
  }

  if ((!data || (data && data.skipped)) && orderId) {
    console.log('Falling back to update by order_id');
    ({ data, error } = await supabase.rpc('update_order_status_and_inventory_by_order_id', {
      p_order_id: orderId,
      p_new_status: status,
      p_payment_intent_id: paymentIntentId ?? null,
    }));
  }

  if (error) {
    console.error('RPC error:', error.message);
    return new Response(JSON.stringify({ ok: false, error: error.message }), { status: 200, headers: { 'Content-Type': 'application/json' } });
  }

  console.log('RPC success:', data);

  // Notify zippers if order was successfully placed (status = in_queue)
  // Only notify on the FIRST transition to in_queue to avoid duplicate notifications
  // (Stripe sends multiple events like payment_intent.succeeded AND charge.succeeded)
  if (status === 'in_queue' && data && data.previous_status !== 'in_queue') {
    console.log(`🔔 Order transitioned from '${data.previous_status}' to 'in_queue' - notifying zippers`);
    try {
      await notifyZippers(orderId);
    } catch (notifyError) {
      console.error('Failed to notify zippers:', notifyError);
      // Don't fail the webhook if notification fails
    }
  } else if (status === 'in_queue' && data && data.previous_status === 'in_queue') {
    console.log(`⏭️ Order already in 'in_queue' status - skipping duplicate zipper notification`);
  }

  return new Response(JSON.stringify({ ok: true, result: data }), { status: 200, headers: { 'Content-Type': 'application/json' } });
}

// Entrypoint for the Edge Function
Deno.serve(async (req: Request) => {
  const rawBody = await req.text();

  // If a webhook secret is set, verify signature
  if (STRIPE_WEBHOOK_SECRET) {
    const sig = req.headers.get('stripe-signature');
    if (!sig) {
      console.warn('Missing stripe-signature header');
      return new Response(JSON.stringify({ ok: false, error: 'missing_signature' }), { status: 400, headers: { 'Content-Type': 'application/json' } });
    }
    try {
      const event = await stripe.webhooks.constructEventAsync(
        rawBody,
        sig,
        STRIPE_WEBHOOK_SECRET
      );
      return await handle(event);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'invalid_signature';
      console.error('Signature verification failed:', message);
      return new Response(JSON.stringify({ ok: false, error: message }), { status: 400, headers: { 'Content-Type': 'application/json' } });
    }
  }

  // Fallback without signature verification (not recommended for production)
  const event = JSON.parse(rawBody);
  return await handle(event);
});

