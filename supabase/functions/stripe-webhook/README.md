# Stripe Webhook Function

This Supabase Edge Function handles Stripe webhook events to automatically update order statuses when payments are processed.

## Features

- **Payment Success Handling**: Updates order status to "confirmed" when payment succeeds
- **Payment Failure Handling**: Updates order status to "cancelled" when payment fails
- **Payment Cancellation**: Updates order status to "cancelled" when payment is canceled
- **Charge Events**: Handles both successful and failed charges
- **Signature Verification**: Securely verifies webhook signatures from Stripe
- **Database Updates**: Automatically updates order statuses in Supabase

## Supported Webhook Events

- `payment_intent.succeeded` - Payment completed successfully
- `payment_intent.payment_failed` - Payment failed
- `payment_intent.canceled` - Payment was canceled
- `charge.succeeded` - Charge completed successfully
- `charge.failed` - Charge failed

## Setup Instructions

### 1. Environment Variables

Set the following environment variables in your Supabase project:

```bash
# Stripe Configuration
STRIPE_SECRET_KEY=sk_test_... # Your Stripe secret key
STRIPE_WEBHOOK_SECRET=whsec_... # Your Stripe webhook endpoint secret

# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJ... # Your Supabase service role key
```

### 2. Stripe Webhook Configuration

In your Stripe Dashboard:

1. Go to **Developers** → **Webhooks**
2. Click **Add endpoint**
3. Set the endpoint URL to: `https://your-project.supabase.co/functions/v1/stripe-webhook`
4. Select the following events:
   - `payment_intent.succeeded`
   - `payment_intent.payment_failed`
   - `payment_intent.canceled`
   - `charge.succeeded`
   - `charge.failed`
5. Copy the webhook signing secret and add it to `STRIPE_WEBHOOK_SECRET`

### 3. Order Metadata Requirements

When creating payment intents, ensure you include the `order_id` in the metadata:

```swift
// In your iOS app when creating payment intent
let metadata = [
    "order_id": order.id.uuidString,
    "user_id": user.id.uuidString
]

// This metadata will be used by the webhook to identify which order to update
```

### 4. Database Schema

Ensure your `orders` table has the following columns:

```sql
CREATE TABLE orders (
    id UUID PRIMARY KEY,
    status TEXT NOT NULL DEFAULT 'pending',
    payment_intent_id TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    -- ... other order fields
);

-- Create an index on payment_intent_id for efficient lookups
CREATE INDEX idx_orders_payment_intent_id ON orders(payment_intent_id);
```

## Deployment

### Local Development

1. Start Supabase locally:
   ```bash
   supabase start
   ```

2. Test the function:
   ```bash
   curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/stripe-webhook' \
     --header 'Authorization: Bearer YOUR_ANON_KEY' \
     --header 'Content-Type: application/json' \
     --data '{"type":"payment_intent.succeeded","data":{"object":{"id":"pi_test123","metadata":{"order_id":"test-order"}}}}'
   ```

### Production Deployment

1. Deploy to Supabase:
   ```bash
   supabase functions deploy stripe-webhook
   ```

2. Set environment variables in production:
   ```bash
   supabase secrets set STRIPE_SECRET_KEY=sk_live_...
   supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_...
   ```

## How It Works

1. **Webhook Reception**: Stripe sends webhook events to this function
2. **Signature Verification**: The function verifies the webhook signature using your webhook secret
3. **Event Processing**: Based on the event type, the appropriate handler function is called
4. **Order Update**: The function updates the order status in your Supabase database
5. **Response**: Returns a success response to Stripe

## Error Handling

The function includes comprehensive error handling:

- **Signature Verification**: Rejects webhooks with invalid signatures
- **Missing Metadata**: Logs warnings when order_id is not found
- **Database Errors**: Logs and handles database update failures
- **Invalid Events**: Gracefully handles unsupported event types

## Monitoring

Check the function logs in your Supabase dashboard:

1. Go to **Edge Functions** → **stripe-webhook**
2. Click **Logs** to view execution history
3. Monitor for any errors or warnings

## Testing

### Test Webhook Events

Use Stripe CLI to test webhook events locally:

```bash
# Install Stripe CLI
brew install stripe/stripe-cli/stripe

# Login to Stripe
stripe login

# Forward webhooks to local function
stripe listen --forward-to localhost:54321/functions/v1/stripe-webhook
```

### Test Order Updates

1. Create a test order in your app
2. Process a test payment
3. Check that the order status updates correctly
4. Verify the webhook logs show successful processing

## Security Considerations

- **Webhook Secret**: Never expose your webhook secret in client-side code
- **Service Role Key**: The function uses the service role key to update orders
- **Signature Verification**: All webhooks are verified using Stripe's signature
- **Environment Variables**: Sensitive keys are stored as environment variables

## Troubleshooting

### Common Issues

1. **Webhook Not Receiving Events**
   - Check that the endpoint URL is correct
   - Verify the webhook is active in Stripe Dashboard
   - Check Supabase function logs for errors

2. **Order Status Not Updating**
   - Ensure `order_id` is included in payment intent metadata
   - Check that the order exists in your database
   - Verify the service role key has proper permissions

3. **Signature Verification Failures**
   - Confirm the webhook secret is correct
   - Check that the webhook endpoint URL matches exactly
   - Ensure the function is receiving the raw body

### Debug Mode

Enable additional logging by setting:

```bash
supabase secrets set DEBUG=true
```

## Support

For issues or questions:

1. Check the Supabase function logs
2. Verify Stripe webhook configuration
3. Test with Stripe CLI locally
4. Review environment variable configuration

## Related Files

- `index.ts` - Main webhook handler
- `deno.json` - Deno configuration and imports
- `README.md` - This documentation file
