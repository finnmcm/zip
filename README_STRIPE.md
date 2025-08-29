# Stripe Integration – Zip iOS

## Overview
- Uses Stripe iOS SDK PaymentSheet
- PaymentIntent is created by Supabase Edge Function `create-payment-intent`

## iOS Setup
1) Add publishable key in `Zip/Utilities/Configuration.swift` (or via `.env` / scheme env var):
   - `STRIPE_PUBLISHABLE_KEY`
2) App sets `STPAPIClient.shared.publishableKey` at launch (`ZipApp` already wired).

## Supabase Setup
- Set environment variable in Supabase project:
  - `STRIPE_SECRET_KEY` (e.g., `sk_test_...`)
- Deploy functions:
```bash
supabase functions deploy create-payment-intent
# Optional for later reconciliation
supabase functions deploy stripe-webhook
```

## Local Test
```bash
supabase start
supabase functions serve create-payment-intent --no-verify-jwt
curl -s -X POST \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"amount": 12.34, "currency": "usd", "description": "Zip Order"}' \
  http://127.0.0.1:54321/functions/v1/create-payment-intent | jq
```

## Flow
1) Checkout computes total (subtotal + fee + tip)
2) `StripeService.processPayment(amount:tip:description:)` invokes edge function
3) `clientSecret` returned → PaymentSheet presented → user completes payment
4) On success, order is created locally and cart cleared (Wire to real backend later)

## Environment Variables
- App `.env`/scheme:
  - `SUPABASE_URL`, `SUPABASE_KEY`, `STRIPE_PUBLISHABLE_KEY`
- Supabase Functions:
  - `STRIPE_SECRET_KEY`

## Next Steps
- Persist orders to Supabase after successful payment
- Implement `stripe-webhook` to reconcile payments and update order status
- Add Apple Pay via PaymentSheet configuration
