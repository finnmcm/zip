// Deno Deploy (Supabase Edge) Stripe webhook to update order status and adjust inventory
// Events handled -> status mapping:
// 'payment_intent.succeeded': 'confirmed'
// 'payment_intent.payment_failed': 'cancelled'
// 'payment_intent.canceled': 'cancelled'
// 'charge.succeeded': 'confirmed'
// 'charge.failed': 'cancelled'
// 'charge.dispute.created': 'disputed'
// 'charge.dispute.closed': 'confirmed'
// 'invoice.payment_succeeded': 'confirmed'
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

type Status = 'confirmed' | 'cancelled' | 'disputed';

const eventTypeToStatus: Record<string, Status | undefined> = {
  'payment_intent.succeeded': 'confirmed',
  'payment_intent.payment_failed': 'cancelled',
  'payment_intent.canceled': 'cancelled',
  'charge.succeeded': 'confirmed',
  'charge.failed': 'cancelled',
  'charge.dispute.created': 'disputed',
  'charge.dispute.closed': 'confirmed',
  'invoice.payment_succeeded': 'confirmed',
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

