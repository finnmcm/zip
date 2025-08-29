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

// Enhanced types for the webhook payload and order management
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

// Enhanced order update request with more fields
type OrderUpdateRequest = {
  id: string;
  status: string;
  payment_intent_id?: string;
  updated_at: string;
  estimated_delivery_time?: string;
  actual_delivery_time?: string;
  delivery_notes?: string;
  payment_status?: string;
  refund_amount?: number;
  refund_reason?: string;
};

// Order status mapping for Stripe events
const ORDER_STATUS_MAP = {
  'payment_intent.succeeded': 'confirmed',
  'payment_intent.payment_failed': 'cancelled',
  'payment_intent.canceled': 'cancelled',
  'charge.succeeded': 'confirmed',
  'charge.failed': 'cancelled',
  'charge.refunded': 'refunded',
  'charge.dispute.created': 'disputed',
  'charge.dispute.closed': 'confirmed',
  'invoice.payment_succeeded': 'confirmed',
  'invoice.payment_failed': 'cancelled',
  'customer.subscription.deleted': 'cancelled'
} as const;

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

    // Enhanced event handling with comprehensive order management
    try {
      await handleStripeEvent(event);
      console.log(`✅ Event ${event.type} processed successfully`);
    } catch (error) {
      console.error(`❌ Error processing event ${event.type}:`, error);
      // Don't return error response here - we want to acknowledge receipt
      // but log the processing error for debugging
    }

    return jsonResponse({ received: true, processed: true });

  } catch (err) {
    console.error("❌ Webhook error:", err);
    return errorResponse("Webhook processing failed", 500);
  }
});

// Main event handler that routes to specific handlers
async function handleStripeEvent(event: StripeWebhookEvent) {
  const eventType = event.type;
  const eventData = event.data.object;
  
  console.log(`🔄 Processing event: ${eventType}`);
  
  switch (eventType) {
    // Payment Intent Events
    case "payment_intent.succeeded":
      await handlePaymentSucceeded(eventData);
      break;
    
    case "payment_intent.payment_failed":
      await handlePaymentFailed(eventData);
      break;
    
    case "payment_intent.canceled":
      await handlePaymentCanceled(eventData);
      break;
    
    case "payment_intent.processing":
      await handlePaymentProcessing(eventData);
      break;
    
    case "payment_intent.requires_action":
      await handlePaymentRequiresAction(eventData);
      break;
    
    // Charge Events
    case "charge.succeeded":
      await handleChargeSucceeded(eventData);
      break;
    
    case "charge.failed":
      await handleChargeFailed(eventData);
      break;
    
    case "charge.refunded":
      await handleChargeRefunded(eventData);
      break;
    
    case "charge.dispute.created":
      await handleChargeDisputeCreated(eventData);
      break;
    
    case "charge.dispute.closed":
      await handleChargeDisputeClosed(eventData);
      break;
    
    // Invoice Events
    case "invoice.payment_succeeded":
      await handleInvoicePaymentSucceeded(eventData);
      break;
    
    case "invoice.payment_failed":
      await handleInvoicePaymentFailed(eventData);
      break;
    
    // Customer Events
    case "customer.subscription.deleted":
      await handleSubscriptionDeleted(eventData);
      break;
    
    // Refund Events
    case "charge.refund.updated":
      await handleRefundUpdated(eventData);
      break;
    
    default:
      console.log(`ℹ️ Unhandled event type: ${eventType}`);
      // Log unhandled events for future implementation
      await logUnhandledEvent(eventType, eventData);
  }
}

// Enhanced Payment Intent Handlers
async function handlePaymentSucceeded(paymentIntent: any) {
  console.log(`✅ Payment succeeded for intent: ${paymentIntent.id}`);
  
  try {
    const orderId = paymentIntent.metadata?.order_id;
    if (!orderId) {
      console.warn("⚠️ No order_id found in payment intent metadata");
      return;
    }

    // Update order status to confirmed
    await updateOrderStatus(orderId, "confirmed", paymentIntent.id);
    
    // Set estimated delivery time (15-30 minutes for campus delivery)
    const estimatedDeliveryTime = new Date(Date.now() + 20 * 60 * 1000); // 20 minutes
    await updateOrderDeliveryTime(orderId, estimatedDeliveryTime);
    
    // Log successful payment for analytics
    await logPaymentSuccess(orderId, paymentIntent.amount, paymentIntent.currency);
    
    console.log(`✅ Order ${orderId} confirmed and delivery time set`);
    
  } catch (error) {
    console.error("❌ Error handling payment success:", error);
    throw error;
  }
}

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
    
    // Log payment failure for analytics
    await logPaymentFailure(orderId, paymentIntent.last_payment_error?.message || "Payment failed");
    
    console.log(`✅ Order ${orderId} cancelled due to payment failure`);
    
  } catch (error) {
    console.error("❌ Error handling payment failure:", error);
    throw error;
  }
}

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
    
    // Log cancellation for analytics
    await logOrderCancellation(orderId, "Payment canceled by user");
    
    console.log(`✅ Order ${orderId} cancelled`);
    
  } catch (error) {
    console.error("❌ Error handling payment cancellation:", error);
    throw error;
  }
}

async function handlePaymentProcessing(paymentIntent: any) {
  console.log(`⏳ Payment processing for intent: ${paymentIntent.id}`);
  
  try {
    const orderId = paymentIntent.metadata?.order_id;
    if (!orderId) {
      console.warn("⚠️ No order_id found in payment intent metadata");
      return;
    }

    // Update order status to pending (payment is being processed)
    await updateOrderStatus(orderId, "pending", paymentIntent.id);
    
    console.log(`✅ Order ${orderId} marked as processing payment`);
    
  } catch (error) {
    console.error("❌ Error handling payment processing:", error);
    throw error;
  }
}

async function handlePaymentRequiresAction(paymentIntent: any) {
  console.log(`⚠️ Payment requires action for intent: ${paymentIntent.id}`);
  
  try {
    const orderId = paymentIntent.metadata?.order_id;
    if (!orderId) {
      console.warn("⚠️ No order_id found in payment intent metadata");
      return;
    }

    // Update order status to pending (waiting for user action)
    await updateOrderStatus(orderId, "pending", paymentIntent.id);
    
    console.log(`✅ Order ${orderId} marked as awaiting user action`);
    
  } catch (error) {
    console.error("❌ Error handling payment requires action:", error);
    throw error;
  }
}

// Enhanced Charge Handlers
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
    
    // Log successful charge
    await logChargeSuccess(orderId, charge.id, charge.amount, charge.currency);
    
    console.log(`✅ Order ${orderId} confirmed via charge`);
    
  } catch (error) {
    console.error("❌ Error handling charge success:", error);
    throw error;
  }
}

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
    
    // Log charge failure
    await logChargeFailure(orderId, charge.id, charge.failure_message || "Charge failed");
    
    console.log(`✅ Order ${orderId} cancelled due to charge failure`);
    
  } catch (error) {
    console.error("❌ Error handling charge failure:", error);
    throw error;
  }
}

async function handleChargeRefunded(charge: any) {
  console.log(`💰 Charge refunded: ${charge.id}`);
  
  try {
    const orderId = charge.metadata?.order_id;
    if (!orderId) {
      console.warn("⚠️ No order_id found in charge metadata");
      return;
    }

    // Update order status to refunded
    await updateOrderStatus(orderId, "refunded", charge.payment_intent);
    
    // Calculate refund amount
    const refundAmount = charge.amount_refunded || 0;
    await updateOrderRefund(orderId, refundAmount, "Full refund");
    
    // Log refund
    await logRefund(orderId, charge.id, refundAmount, charge.currency);
    
    console.log(`✅ Order ${orderId} marked as refunded`);
    
  } catch (error) {
    console.error("❌ Error handling charge refund:", error);
    throw error;
  }
}

async function handleChargeDisputeCreated(charge: any) {
  console.log(`⚠️ Charge dispute created: ${charge.id}`);
  
  try {
    const orderId = charge.metadata?.order_id;
    if (!orderId) {
      console.warn("⚠️ No order_id found in charge metadata");
      return;
    }

    // Update order status to disputed
    await updateOrderStatus(orderId, "disputed", charge.payment_intent);
    
    // Log dispute
    await logDispute(orderId, charge.id, "Dispute created");
    
    console.log(`✅ Order ${orderId} marked as disputed`);
    
  } catch (error) {
    console.error("❌ Error handling charge dispute creation:", error);
    throw error;
  }
}

async function handleChargeDisputeClosed(charge: any) {
  console.log(`✅ Charge dispute closed: ${charge.id}`);
  
  try {
    const orderId = charge.metadata?.order_id;
    if (!orderId) {
      console.warn("⚠️ No order_id found in charge metadata");
      return;
    }

    // Determine final status based on dispute outcome
    const finalStatus = charge.dispute?.status === 'won' ? 'confirmed' : 'cancelled';
    await updateOrderStatus(orderId, finalStatus, charge.payment_intent);
    
    // Log dispute resolution
    await logDisputeResolution(orderId, charge.id, finalStatus);
    
    console.log(`✅ Order ${orderId} dispute resolved with status: ${finalStatus}`);
    
  } catch (error) {
    console.error("❌ Error handling charge dispute closure:", error);
    throw error;
  }
}

// Invoice Event Handlers
async function handleInvoicePaymentSucceeded(invoice: any) {
  console.log(`✅ Invoice payment succeeded: ${invoice.id}`);
  
  try {
    const orderId = invoice.metadata?.order_id;
    if (!orderId) {
      console.warn("⚠️ No order_id found in invoice metadata");
      return;
    }

    // Update order status to confirmed
    await updateOrderStatus(orderId, "confirmed", invoice.payment_intent);
    
    console.log(`✅ Order ${orderId} confirmed via invoice payment`);
    
  } catch (error) {
    console.error("❌ Error handling invoice payment success:", error);
    throw error;
  }
}

async function handleInvoicePaymentFailed(invoice: any) {
  console.log(`❌ Invoice payment failed: ${invoice.id}`);
  
  try {
    const orderId = invoice.metadata?.order_id;
    if (!orderId) {
      console.warn("⚠️ No order_id found in invoice metadata");
      return;
    }

    // Update order status to cancelled
    await updateOrderStatus(orderId, "cancelled", invoice.payment_intent);
    
    console.log(`✅ Order ${orderId} cancelled due to invoice payment failure`);
    
  } catch (error) {
    console.error("❌ Error handling invoice payment failure:", error);
    throw error;
  }
}

// Subscription Event Handlers
async function handleSubscriptionDeleted(subscription: any) {
  console.log(`❌ Subscription deleted: ${subscription.id}`);
  
  try {
    // Handle subscription cancellation - this might affect multiple orders
    // For now, just log the event
    await logSubscriptionEvent(subscription.id, "deleted");
    
    console.log(`✅ Subscription ${subscription.id} deletion logged`);
    
  } catch (error) {
    console.error("❌ Error handling subscription deletion:", error);
    throw error;
  }
}

// Refund Event Handlers
async function handleRefundUpdated(refund: any) {
  console.log(`💰 Refund updated: ${refund.id}`);
  
  try {
    const orderId = refund.metadata?.order_id;
    if (!orderId) {
      console.warn("⚠️ No order_id found in refund metadata");
      return;
    }

    // Update order refund information
    await updateOrderRefund(orderId, refund.amount, refund.reason || "Refund updated");
    
    // Log refund update
    await logRefundUpdate(orderId, refund.id, refund.amount, refund.status);
    
    console.log(`✅ Order ${orderId} refund information updated`);
    
  } catch (error) {
    console.error("❌ Error handling refund update:", error);
    throw error;
  }
}

// Enhanced Order Management Functions
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

async function updateOrderDeliveryTime(orderId: string, estimatedDeliveryTime: Date) {
  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    
    if (!supabaseUrl || !supabaseServiceRoleKey) {
      throw new Error("Supabase configuration not found");
    }

    const updateData = {
      estimated_delivery_time: estimatedDeliveryTime.toISOString(),
      updated_at: new Date().toISOString()
    };

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
      throw new Error(`Failed to update order delivery time: ${response.status} ${errorText}`);
    }

    console.log(`✅ Order ${orderId} delivery time updated`);
    
  } catch (error) {
    console.error(`❌ Error updating order ${orderId} delivery time:`, error);
    throw error;
  }
}

async function updateOrderRefund(orderId: string, refundAmount: number, refundReason: string) {
  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    
    if (!supabaseUrl || !supabaseServiceRoleKey) {
      throw new Error("Supabase configuration not found");
    }

    const updateData = {
      refund_amount: refundAmount,
      refund_reason: refundReason,
      updated_at: new Date().toISOString()
    };

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
      throw new Error(`Failed to update order refund: ${response.status} ${errorText}`);
    }

    console.log(`✅ Order ${orderId} refund information updated`);
    
  } catch (error) {
    console.error(`❌ Error updating order ${orderId} refund:`, error);
    throw error;
  }
}

// Logging Functions for Analytics and Debugging
async function logPaymentSuccess(orderId: string, amount: number, currency: string) {
  console.log(`📊 Payment Success Log: Order ${orderId}, Amount: ${amount} ${currency}`);
  // In production, you might want to send this to an analytics service
}

async function logPaymentFailure(orderId: string, reason: string) {
  console.log(`📊 Payment Failure Log: Order ${orderId}, Reason: ${reason}`);
  // In production, you might want to send this to an analytics service
}

async function logOrderCancellation(orderId: string, reason: string) {
  console.log(`📊 Order Cancellation Log: Order ${orderId}, Reason: ${reason}`);
  // In production, you might want to send this to an analytics service
}

async function logChargeSuccess(orderId: string, chargeId: string, amount: number, currency: string) {
  console.log(`📊 Charge Success Log: Order ${orderId}, Charge ${chargeId}, Amount: ${amount} ${currency}`);
}

async function logChargeFailure(orderId: string, chargeId: string, reason: string) {
  console.log(`📊 Charge Failure Log: Order ${orderId}, Charge ${chargeId}, Reason: ${reason}`);
}

async function logRefund(orderId: string, chargeId: string, amount: number, currency: string) {
  console.log(`📊 Refund Log: Order ${orderId}, Charge ${chargeId}, Amount: ${amount} ${currency}`);
}

async function logDispute(orderId: string, chargeId: string, reason: string) {
  console.log(`📊 Dispute Log: Order ${orderId}, Charge ${chargeId}, Reason: ${reason}`);
}

async function logDisputeResolution(orderId: string, chargeId: string, finalStatus: string) {
  console.log(`📊 Dispute Resolution Log: Order ${orderId}, Charge ${chargeId}, Final Status: ${finalStatus}`);
}

async function logSubscriptionEvent(subscriptionId: string, event: string) {
  console.log(`📊 Subscription Event Log: ${subscriptionId}, Event: ${event}`);
}

async function logRefundUpdate(orderId: string, refundId: string, amount: number, status: string) {
  console.log(`📊 Refund Update Log: Order ${orderId}, Refund ${refundId}, Amount: ${amount}, Status: ${status}`);
}

async function logUnhandledEvent(eventType: string, eventData: any) {
  console.log(`📊 Unhandled Event Log: ${eventType}`, {
    eventId: eventData.id,
    objectType: eventData.object,
    created: eventData.created
  });
}

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/stripe-webhook' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"type":"payment_intent.succeeded","data":{"object":{"id":"pi_test123","metadata":{"order_id":"test-order"}}}}'

*/
