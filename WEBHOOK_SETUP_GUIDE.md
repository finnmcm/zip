# Stripe Webhook Setup Guide

## Issues Fixed

1. **JWT Verification Disabled**: Changed `verify_jwt = false` in `supabase/config.toml` since Stripe webhooks don't send JWT tokens
2. **Enhanced Logging**: Added detailed logging to help debug webhook issues
3. **Better Error Handling**: Improved error messages and debugging information

## Required Environment Variables

You need to set these environment variables in your Supabase project:

### 1. Set Environment Variables in Supabase Dashboard

Go to your Supabase project dashboard → Settings → Edge Functions and add:

```
STRIPE_SECRET_KEY=sk_test_... (your Stripe secret key)
STRIPE_WEBHOOK_SECRET=whsec_... (your Stripe webhook endpoint secret)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJ... (your service role key)
```

### 2. Get Your Stripe Webhook Secret

1. Go to [Stripe Dashboard → Webhooks](https://dashboard.stripe.com/webhooks)
2. Create a new webhook endpoint:
   - URL: `https://your-project.supabase.co/functions/v1/stripe-webhook`
   - Events to send: Select all payment-related events
3. Copy the webhook signing secret (starts with `whsec_`)

### 3. Get Your Supabase Service Role Key

1. Go to your Supabase project dashboard
2. Settings → API
3. Copy the "service_role" key (NOT the anon key)

## Deploy the Updated Function

```bash
# Deploy the updated webhook function
supabase functions deploy stripe-webhook

# Or deploy all functions
supabase functions deploy
```

## Test the Webhook

### 1. Test Locally (Optional)

```bash
# Start Supabase locally
supabase start

# Test with curl (replace with your actual values)
curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/stripe-webhook' \
  --header 'Content-Type: application/json' \
  --data '{"type":"payment_intent.succeeded","data":{"object":{"id":"pi_test123","metadata":{"order_id":"test-order"}}}}'
```

### 2. Test with Stripe CLI

```bash
# Install Stripe CLI if you haven't
brew install stripe/stripe-cli/stripe

# Login to Stripe
stripe login

# Forward webhooks to your local function
stripe listen --forward-to https://your-project.supabase.co/functions/v1/stripe-webhook

# In another terminal, trigger a test event
stripe trigger payment_intent.succeeded
```

### 3. Test with Real Payment

1. Make a test payment through your app
2. Check the Supabase Edge Function logs in the dashboard
3. Verify the webhook processes the event

## Monitor Webhook Function

### View Logs in Supabase Dashboard

1. Go to Edge Functions → stripe-webhook
2. Click "View logs" to see real-time execution logs
3. Look for the enhanced logging we added:
   - Environment variable status
   - Request body length
   - Signature verification status
   - Event processing details

### Common Issues and Solutions

#### 1. 401 Unauthorized
- **Cause**: JWT verification was enabled (now fixed)
- **Solution**: Ensure `verify_jwt = false` in config.toml

#### 2. 500 Internal Server Error
- **Cause**: Missing environment variables
- **Solution**: Set all required environment variables in Supabase dashboard

#### 3. Webhook Signature Verification Failed
- **Cause**: Incorrect webhook secret or malformed request
- **Solution**: 
  - Verify webhook secret in Stripe dashboard
  - Check that webhook URL is correct
  - Ensure Stripe is sending to the right endpoint

#### 4. Order Update Failed
- **Cause**: Database permission issues or missing orders table
- **Solution**: 
  - Verify service role key has proper permissions
  - Check that orders table exists and has correct schema

## Webhook Event Types Handled

The function currently handles these Stripe events:

- `payment_intent.succeeded` → Order status: "confirmed"
- `payment_intent.payment_failed` → Order status: "cancelled"
- `payment_intent.canceled` → Order status: "cancelled"
- `charge.succeeded` → Order status: "confirmed"
- `charge.failed` → Order status: "cancelled"

## Database Schema Requirements

Ensure your `orders` table has these columns:

```sql
CREATE TABLE orders (
  id UUID PRIMARY KEY,
  status TEXT NOT NULL,
  payment_intent_id TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  -- other order fields...
);
```

## Security Notes

- The webhook function now has `verify_jwt = false` because Stripe webhooks don't send JWT tokens
- Webhook security is maintained through Stripe's signature verification
- The function uses the service role key for database operations (bypasses RLS)
- All sensitive operations are logged for monitoring

## Next Steps

1. Deploy the updated function
2. Set environment variables in Supabase dashboard
3. Test with Stripe CLI or real payments
4. Monitor logs for any remaining issues
5. Verify order status updates in your database
