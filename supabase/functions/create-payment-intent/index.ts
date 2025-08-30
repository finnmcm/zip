// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts"

// Use Stripe's npm package in Deno
import Stripe from "npm:stripe@14";

type CreatePaymentIntentRequest = {
  amount: number; // amount in dollars
  currency?: string; // default: usd
  metadata?: Record<string, string>;
  description?: string;
};

type CreatePaymentIntentResponse = {
  clientSecret: string;
  paymentIntentId: string;
};

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const stripeSecretKey = Deno.env.get("STRIPE_SECRET_KEY");
  if (!stripeSecretKey) {
    return jsonResponse({ error: "Stripe secret key not configured" }, 500);
  }

  let payload: CreatePaymentIntentRequest | undefined;
  try {
    payload = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  if (!payload || typeof payload.amount !== "number" || payload.amount <= 0) {
    return jsonResponse({ error: "Invalid amount" }, 400);
  }

  const currency = (payload.currency || "usd").toLowerCase();
  const amountInCents = Math.round(payload.amount * 100);

  try {
    const stripe = new Stripe(stripeSecretKey, {
      apiVersion: "2024-06-20",
    });

    const paymentIntent = await stripe.paymentIntents.create({
      amount: amountInCents,
      currency,
      automatic_payment_methods: { enabled: true },
      description: payload.description,
      metadata: payload.metadata,
    });

    if (!paymentIntent.client_secret) {
      return jsonResponse({ error: "Failed to create client secret" }, 500);
    }

    const response: CreatePaymentIntentResponse = {
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
    };

    return jsonResponse(response, 200);
  } catch (err) {
    console.error("Stripe error", err);
    return jsonResponse({ error: "Stripe error" }, 500);
  }
});


