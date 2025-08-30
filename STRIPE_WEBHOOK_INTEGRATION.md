# Stripe Webhook Integration Guide

This document explains how the Stripe webhook system integrates with your Zip iOS app to automatically handle payment events and update order statuses.

## System Overview

The integration consists of three main components:

1. **iOS App** - Creates orders and initiates payments
2. **Supabase Edge Functions** - Handle payment intent creation and webhook processing
3. **Stripe** - Processes payments and sends webhook events

## Flow Diagram

```
iOS App → Create Order → Supabase Database
    ↓
Process Payment → Create Payment Intent (with order_id metadata)
    ↓
Stripe Payment Sheet → User completes payment
    ↓
Stripe sends webhook → Supabase webhook function
    ↓
Update order status → Supabase Database
    ↓
iOS App reflects updated order status
```

## Implementation Details

### 1. Order Creation Flow

When a user completes checkout:

```swift
// 1. Create order in Supabase
let order = Order(user: currentUser, items: cartItems, ...)
let savedOrder = try await supabaseService.createOrder(order)

// 2. Process payment with order ID
let paymentResult = await stripeService.processPayment(
    amount: order.rawAmount,
    tip: order.tip,
    description: "Zip delivery order",
    orderId: savedOrder.id  // Pass the order ID
)
```

### 2. Payment Intent Creation

The `create-payment-intent` function now includes order metadata:

```typescript
// In create-payment-intent/index.ts
const paymentIntent = await stripe.paymentIntents.create({
  amount: amountInCents,
  currency,
  automatic_payment_methods: { enabled: true },
  description: payload.description,
  metadata: payload.metadata, // Contains order_id
});
```

### 3. Webhook Processing

The `stripe-webhook` function processes various payment events:

- **Payment Success**: Updates order status to "confirmed"
- **Payment Failure**: Updates order status to "cancelled"
- **Payment Cancellation**: Updates order status to "cancelled"

### 4. Database Updates

The webhook function updates the orders table:

```typescript
await updateOrderStatus(orderId, "confirmed", paymentIntentId);
```

## Key Benefits

### Automatic Order Management
- No manual intervention required for payment status updates
- Real-time order status synchronization
- Reduced risk of payment/order mismatches

### Improved User Experience
- Users see immediate feedback on payment success/failure
- Order status updates automatically in the app
- Seamless integration between payment and order systems

### Reliability
- Webhook signature verification ensures security
- Comprehensive error handling and logging
- Idempotent operations prevent duplicate updates

## Setup Requirements

### Environment Variables

```bash
# Stripe
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJ...
```

### Database Schema

Ensure your orders table has:

```sql
CREATE TABLE orders (
    id UUID PRIMARY KEY,
    status TEXT NOT NULL DEFAULT 'pending',
    payment_intent_id TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    -- other fields...
);

CREATE INDEX idx_orders_payment_intent_id ON orders(payment_intent_id);
```

### Stripe Webhook Configuration

Configure webhook endpoint in Stripe Dashboard:
- URL: `https://your-project.supabase.co/functions/v1/stripe-webhook`
- Events: `payment_intent.succeeded`, `payment_intent.payment_failed`, etc.

## Testing the Integration

### 1. Local Testing

```bash
# Start Supabase locally
supabase start

# Test webhook function
curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/stripe-webhook' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{"type":"payment_intent.succeeded","data":{"object":{"id":"pi_test123","metadata":{"order_id":"test-order"}}}}'
```

### 2. Stripe CLI Testing

```bash
# Install Stripe CLI
brew install stripe/stripe-cli/stripe

# Forward webhooks to local function
stripe listen --forward-to localhost:54321/functions/v1/stripe-webhook
```

### 3. End-to-End Testing

1. Create a test order in your iOS app
2. Process a test payment
3. Verify webhook receives the event
4. Check order status updates in database
5. Confirm app reflects the updated status

## Error Handling

### Common Issues

1. **Webhook Not Receiving Events**
   - Check endpoint URL configuration
   - Verify webhook is active in Stripe
   - Check Supabase function logs

2. **Order Status Not Updating**
   - Ensure `order_id` is in payment intent metadata
   - Verify order exists in database
   - Check service role key permissions

3. **Signature Verification Failures**
   - Confirm webhook secret is correct
   - Check endpoint URL matches exactly
   - Ensure function receives raw body

### Debug Mode

Enable additional logging:

```bash
supabase secrets set DEBUG=true
```

## Security Considerations

### Webhook Security
- All webhooks are verified using Stripe signatures
- Webhook secret is stored securely as environment variable
- Function rejects invalid signatures

### Database Access
- Function uses service role key for database updates
- Service role key has minimal required permissions
- No sensitive data is logged

### API Security
- Functions are protected by Supabase authentication
- Environment variables are encrypted at rest
- No sensitive keys in client-side code

## Monitoring and Logging

### Function Logs

Check logs in Supabase Dashboard:
1. Go to **Edge Functions** → **stripe-webhook**
2. Click **Logs** to view execution history
3. Monitor for errors or warnings

### Stripe Dashboard

Monitor webhook delivery in Stripe:
1. Go to **Developers** → **Webhooks**
2. Click on your webhook endpoint
3. View delivery attempts and failures

### Custom Metrics

Consider adding custom logging for:
- Payment success rates
- Order status update times
- Error frequency and types

## Future Enhancements

### Additional Webhook Events
- `invoice.payment_succeeded` - For subscription payments
- `customer.subscription.updated` - For subscription changes

### Enhanced Order Management
- Automatic inventory updates
- Delivery time calculations
- Customer notification system

### Analytics Integration
- Payment success rate tracking
- Order conversion metrics
- Customer behavior analysis

## Support and Troubleshooting

### Getting Help

1. Check Supabase function logs first
2. Verify Stripe webhook configuration
3. Test with Stripe CLI locally
4. Review environment variable setup

### Common Commands

```bash
# Deploy webhook function
supabase functions deploy stripe-webhook

# Set environment variables
supabase secrets set STRIPE_SECRET_KEY=sk_test_...

# View function logs
supabase functions logs stripe-webhook

# Test function locally
supabase functions serve stripe-webhook
```

### Resources

- [Stripe Webhooks Documentation](https://stripe.com/docs/webhooks)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
- [Stripe CLI Documentation](https://stripe.com/docs/stripe-cli)
- [Deno Runtime](https://deno.land/manual)

## Conclusion

This webhook integration provides a robust, automated system for handling payment events and order management. By following the setup instructions and testing procedures, you'll have a reliable payment processing system that keeps your order statuses synchronized with payment outcomes.

The system is designed to be:
- **Secure**: Webhook signature verification and secure key management
- **Reliable**: Comprehensive error handling and logging
- **Scalable**: Built on Supabase Edge Functions for high performance
- **Maintainable**: Clear separation of concerns and comprehensive documentation
