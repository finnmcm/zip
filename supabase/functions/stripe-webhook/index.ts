// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts"

// Use Stripe's npm package in Deno
// Note: This function is designed for Deno edge runtime compatibility
// If you encounter SubtleCryptoProvider errors, ensure you're using:
// 1. Stripe v14.25.0+ (which this uses)
// 2. Deno edge runtime (which Supabase Functions use)
// 3. constructEventAsync() instead of constructEvent()
import Stripe from "stripe";

// Types for the webhook payload
type StripeWebhookEvent = {
  id: string;
  object: string;
  api_version: string;
  created: number;
  data: {
    object: any;
  };
  livemode: boolean;
  pending_webhooks: number;
  request: {
    id: string;
    idempotency_key: string | null;
  };
  type: string;
};

// Types for order status updates
type OrderUpdateRequest = {
  id: string;
  status: string;
  payment_intent_id?: string;
  updated_at: string;
};

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function errorResponse(message: string, status = 400) {
  return jsonResponse({ error: message }, status);
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return errorResponse("Method not allowed", 405);
  }

  // Get environment variables
  const stripeSecretKey = Deno.env.get("STRIPE_SECRET_KEY");
  const stripeWebhookSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  // Log environment variable status (without exposing values)
  console.log("🔧 Environment check:");
  console.log(`   - STRIPE_SECRET_KEY: ${stripeSecretKey ? "✅ Configured" : "❌ Missing"}`);
  console.log(`   - STRIPE_WEBHOOK_SECRET: ${stripeWebhookSecret ? "✅ Configured" : "❌ Missing"}`);
  console.log(`   - SUPABASE_URL: ${supabaseUrl ? "✅ Configured" : "❌ Missing"}`);
  console.log(`   - SUPABASE_SERVICE_ROLE_KEY: ${supabaseServiceRoleKey ? "✅ Configured" : "❌ Missing"}`);

  if (!stripeSecretKey) {
    console.error("❌ Stripe secret key not configured");
    return errorResponse("Stripe secret key not configured", 500);
  }

  if (!stripeWebhookSecret) {
    console.error("❌ Stripe webhook secret not configured");
    return errorResponse("Stripe webhook secret not configured", 500);
  }

  if (!supabaseUrl || !supabaseServiceRoleKey) {
    console.error("❌ Supabase configuration not found");
    return errorResponse("Supabase configuration not found", 500);
  }

  try {
    // Get the raw body for signature verification
    const body = await req.text();
    console.log(`📝 Request body length: ${body.length} characters`);
    
    // Verify the webhook signature
    const signature = req.headers.get("stripe-signature");
    if (!signature) {
      console.error("❌ No Stripe signature found");
      console.log("📋 Available headers:", Array.from(req.headers.entries()));
      return errorResponse("No Stripe signature found", 400);
    }

    console.log(`🔐 Stripe signature found: ${signature.substring(0, 20)}...`);

    let event: StripeWebhookEvent;
    try {
      const stripe = new Stripe(stripeSecretKey, {
        apiVersion: "2024-06-20",
      });
      
      // Use constructEventAsync for Deno edge runtime compatibility
      event = await stripe.webhooks.constructEventAsync(body, signature, stripeWebhookSecret);
      console.log(`✅ Webhook signature verified successfully`);
      console.log(`📋 Event type: ${event.type}, Event ID: ${event.id}`);
    } catch (err: any) {
      console.error("❌ Webhook signature verification failed:", err);
      console.error("❌ Error details:", {
        message: err.message,
        type: err.constructor.name,
        stack: err.stack
      });
      
      // Provide more specific error information
      if (err.message.includes("SubtleCryptoProvider")) {
        console.error("❌ Crypto provider error - this suggests a Deno runtime compatibility issue");
        console.error("💡 Try updating to the latest Stripe version or check Deno compatibility");
      }
      
      // Log additional debugging info
      console.error("🔍 Debug info:", {
        bodyLength: body.length,
        signatureLength: signature?.length,
        webhookSecretLength: stripeWebhookSecret?.length,
        stripeApiVersion: "2024-06-20"
      });
      
      return errorResponse(`Webhook signature verification failed: ${err.message}`, 400);
    }

    console.log(`✅ Webhook received: ${event.type}`);

    // Handle different event types
    switch (event.type) {
      case "payment_intent.succeeded":
        await handlePaymentSucceeded(event.data.object);
        break;
      
      case "payment_intent.payment_failed":
        await handlePaymentFailed(event.data.object);
        break;
      
      case "payment_intent.canceled":
        await handlePaymentCanceled(event.data.object);
        break;
      
      case "charge.succeeded":
        await handleChargeSucceeded(event.data.object);
        break;
      
      case "charge.failed":
        await handleChargeFailed(event.data.object);
        break;
      
      default:
        console.log(`ℹ️ Unhandled event type: ${event.type}`);
    }

    return jsonResponse({ received: true });

  } catch (err) {
    console.error("❌ Webhook error:", err);
    return errorResponse("Webhook processing failed", 500);
  }
});

// Handle successful payment
async function handlePaymentSucceeded(paymentIntent: any) {
  console.log(`✅ Payment succeeded for intent: ${paymentIntent.id}`);
  
  try {
    // Extract metadata from payment intent
    const orderId = paymentIntent.metadata?.order_id;
    if (!orderId) {
      console.warn("⚠️ No order_id found in payment intent metadata");
      return;
    }

    // Update order status to confirmed
    await updateOrderStatus(orderId, "confirmed", paymentIntent.id);
    
    // Clear the user's cart (optional - you might want to do this after order creation)
    // await clearUserCart(paymentIntent.metadata?.user_id);
    
    console.log(`✅ Order ${orderId} status updated to confirmed`);
    
  } catch (error) {
    console.error("❌ Error handling payment success:", error);
  }
}

// Handle failed payment
async function handlePaymentFailed(paymentIntent: any) {
  console.log(`❌ Payment failed for intent: ${paymentIntent.id}`);
  
  try {
    const orderId = paymentIntent.metadata?.order_id;
    if (!orderId) {
      console.warn("⚠️ No order_id found in payment intent metadata");
      return;
    }

    // Update order status to cancelled
    await updateOrderStatus(orderId, "cancelled", paymentIntent.id);
    
    console.log(`✅ Order ${orderId} status updated to cancelled`);
    
  } catch (error) {
    console.error("❌ Error handling payment failure:", error);
  }
}

// Handle canceled payment
async function handlePaymentCanceled(paymentIntent: any) {
  console.log(`❌ Payment canceled for intent: ${paymentIntent.id}`);
  
  try {
    const orderId = paymentIntent.metadata?.order_id;
    if (!orderId) {
      console.warn("⚠️ No order_id found in payment intent metadata");
      return;
    }

    // Update order status to cancelled
    await updateOrderStatus(orderId, "cancelled", paymentIntent.id);
    
    console.log(`✅ Order ${orderId} status updated to cancelled`);
    
  } catch (error) {
    console.error("❌ Error handling payment cancellation:", error);
  }
}

// Handle successful charge
async function handleChargeSucceeded(charge: any) {
  console.log(`✅ Charge succeeded: ${charge.id}`);
  
  try {
    const orderId = charge.metadata?.order_id;
    if (!orderId) {
      console.warn("⚠️ No order_id found in charge metadata");
      return;
    }

    // Update order status to confirmed if not already
    await updateOrderStatus(orderId, "confirmed", charge.payment_intent);
    
    console.log(`✅ Order ${orderId} confirmed via charge`);
    
  } catch (error) {
    console.error("❌ Error handling charge success:", error);
  }
}

// Handle failed charge
async function handleChargeFailed(charge: any) {
  console.log(`❌ Charge failed: ${charge.id}`);
  
  try {
    const orderId = charge.metadata?.order_id;
    if (!orderId) {
      console.warn("⚠️ No order_id found in charge metadata");
      return;
    }

    // Update order status to cancelled
    await updateOrderStatus(orderId, "cancelled", charge.payment_intent);
    
    console.log(`✅ Order ${orderId} cancelled due to charge failure`);
    
  } catch (error) {
    console.error("❌ Error handling charge failure:", error);
  }
}

// Update order status in Supabase
async function updateOrderStatus(orderId: string, status: string, paymentIntentId?: string) {
  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    
    if (!supabaseUrl || !supabaseServiceRoleKey) {
      throw new Error("Supabase configuration not found");
    }

    const updateData: OrderUpdateRequest = {
      id: orderId,
      status: status,
      updated_at: new Date().toISOString()
    };

    if (paymentIntentId) {
      updateData.payment_intent_id = paymentIntentId;
    }

    // Make HTTP request to Supabase REST API
    const response = await fetch(`${supabaseUrl}/rest/v1/orders?id=eq.${orderId}`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${supabaseServiceRoleKey}`,
        "apikey": supabaseServiceRoleKey,
        "Prefer": "return=minimal"
      },
      body: JSON.stringify(updateData)
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Failed to update order: ${response.status} ${errorText}`);
    }

    console.log(`✅ Order ${orderId} status updated to ${status}`);
    
  } catch (error) {
    console.error(`❌ Error updating order ${orderId}:`, error);
    throw error;
  }
}

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/stripe-webhook' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"type":"payment_intent.succeeded","data":{"object":{"id":"pi_test123","metadata":{"order_id":"test-order"}}}}'

*/
