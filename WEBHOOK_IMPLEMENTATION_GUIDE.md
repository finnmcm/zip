# Webhook Implementation Guide for Zip iOS App

This guide provides step-by-step instructions for implementing and deploying the comprehensive Stripe webhook functions that manage order lifecycle in the Zip iOS app.

## Overview

The webhook functions provide real-time order management by:
- **Automatically updating order statuses** based on Stripe payment events
- **Managing delivery time estimates** for successful payments
- **Handling disputes** automatically
- **Logging all payment activities** for analytics and debugging
- **Ensuring data consistency** between Stripe and your database

## Architecture

```
Stripe Events → Webhook Function → Database Updates → Order Status Changes
     ↓              ↓                    ↓              ↓
Payment Success → Process Event → Update Order → Set Delivery Time
Payment Failure → Process Event → Cancel Order → Log Failure
Dispute Process → Process Event → Mark Disputed → Update Status
```

## Prerequisites

### 1. Stripe Account Setup
- [ ] Stripe account created
- [ ] API keys generated (publishable and secret)
- [ ] Webhook endpoint configured
- [ ] Test mode enabled for development

### 2. Supabase Project Setup
- [ ] Supabase project created
- [ ] Database schema deployed
- [ ] Edge functions enabled
- [ ] Service role key available

### 3. Development Environment
- [ ] Supabase CLI installed
- [ ] Deno runtime available
- [ ] Node.js/npm for package management

## Step-by-Step Implementation

### Step 1: Database Schema Setup

1. **Deploy the database migration:**
   ```bash
   cd supabase
   supabase start
   supabase db reset
   ```

2. **Verify the tables are created:**
   ```sql
   -- Check if orders table exists
   SELECT * FROM information_schema.tables 
   WHERE table_name = 'orders';
   
   -- Check table structure
   \d orders
   ```

3. **Verify RLS policies:**
   ```sql
   -- Check RLS is enabled
   SELECT schemaname, tablename, rowsecurity 
   FROM pg_tables 
   WHERE tablename = 'orders';
   ```

### Step 2: Environment Configuration

1. **Set Stripe environment variables:**
   ```bash
   supabase secrets set STRIPE_SECRET_KEY=sk_test_your_key_here
   supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret
   ```

2. **Set Supabase environment variables:**
   ```bash
   supabase secrets set SUPABASE_URL=https://your-project.supabase.co
   supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
   ```

3. **Verify environment variables:**
   ```bash
   supabase secrets list
   ```

### Step 3: Webhook Function Deployment

1. **Deploy the webhook function:**
   ```bash
   supabase functions deploy stripe-webhook
   ```

2. **Verify deployment:**
   ```bash
   supabase functions list
   ```

3. **Check function logs:**
   ```bash
   supabase functions logs stripe-webhook
   ```

### Step 4: Stripe Webhook Configuration

1. **Go to Stripe Dashboard:**
   - Navigate to Developers → Webhooks
   - Click "Add endpoint"

2. **Configure webhook endpoint:**
   ```
   URL: https://your-project.supabase.co/functions/v1/stripe-webhook
   Events to send:
   - payment_intent.succeeded
   - payment_intent.payment_failed
   - payment_intent.canceled
   - payment_intent.processing
   - payment_intent.requires_action
   - charge.succeeded
   - charge.failed
   - charge.dispute.created
   - charge.dispute.closed
   - invoice.payment_succeeded
   - invoice.payment_failed
   ```

3. **Copy webhook signing secret:**
   - Click on the webhook endpoint
   - Copy the "Signing secret"
   - Update your environment variable:
     ```bash
     supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_copied_secret
     ```

### Step 5: Testing the Implementation

1. **Run comprehensive tests:**
   ```bash
   cd supabase/functions/stripe-webhook
   deno run --allow-net --allow-env test-webhook.ts --local
   ```

2. **Test specific events:**
   ```bash
   # Test payment success
   deno run --allow-net --allow-env test-webhook.ts --event=payment_intent.succeeded
   
   # Test payment failure
   deno run --allow-net --allow-env test-webhook.ts --event=payment_intent.payment_failed
   ```

3. **Test with Stripe CLI:**
   ```bash
   # Install Stripe CLI
   brew install stripe/stripe-cli/stripe
   
   # Login to Stripe
   stripe login
   
   # Forward webhooks to local endpoint
   stripe listen --forward-to localhost:54321/functions/v1/stripe-webhook
   
   # In another terminal, trigger test events
   stripe trigger payment_intent.succeeded
   stripe trigger payment_intent.payment_failed
   ```

### Step 6: iOS App Integration

1. **Update your iOS app to include order metadata:**
   ```swift
   // When creating payment intent
   let metadata = [
       "order_id": order.id.uuidString,
       "user_id": user.id.uuidString
   ]
   
   // Include metadata in payment intent creation
   let paymentIntentParams = STPPaymentIntentParams(
       amount: amount,
       currency: "usd",
       metadata: metadata
   )
   ```

2. **Verify order creation flow:**
   - Create order in database
   - Create payment intent with metadata
   - Process payment
   - Check webhook updates order status

### Step 7: Production Deployment

1. **Deploy to production:**
   ```bash
   supabase functions deploy stripe-webhook --project-ref your-production-ref
   ```

2. **Set production secrets:**
   ```bash
   supabase secrets set --project-ref your-production-ref STRIPE_SECRET_KEY=sk_live_...
   supabase secrets set --project-ref your-production-ref STRIPE_WEBHOOK_SECRET=whsec_...
   ```

3. **Update Stripe webhook endpoint:**
   - Change webhook URL to production Supabase URL
   - Test webhook delivery

## Order Lifecycle Management

### Payment Flow
```
1. User places order → Status: pending
2. Payment intent created → Status: pending
3. Payment processing → Status: pending
4. Payment succeeds → Status: confirmed + Delivery time set
5. Order prepared → Status: preparing
6. Order delivered → Status: delivered
```

### Failure Scenarios
```
1. Payment fails → Status: cancelled
2. Payment requires action → Status: pending
3. Dispute created → Status: disputed
4. Dispute processed → Status: disputed
```

### Status Transitions
```sql
-- View all status transitions for an order
SELECT 
    status,
    previous_status,
    reason,
    created_at
FROM order_status_history 
WHERE order_id = 'your-order-id'
ORDER BY created_at;
```

## Monitoring and Debugging

### 1. Function Logs
```bash
# View real-time logs
supabase functions logs stripe-webhook --follow

# View specific time range
supabase functions logs stripe-webhook --start="2024-01-01" --end="2024-01-02"
```

### 2. Database Monitoring
```sql
-- Check recent order status changes
SELECT 
    o.id,
    o.status,
    o.updated_at,
    osh.reason,
    osh.created_at as status_change_time
FROM orders o
LEFT JOIN order_status_history osh ON o.id = osh.order_id
WHERE o.updated_at > NOW() - INTERVAL '1 hour'
ORDER BY o.updated_at DESC;

-- Check webhook event processing
SELECT 
    stripe_event_type,
    status,
    COUNT(*) as event_count,
    AVG(EXTRACT(EPOCH FROM (created_at - LAG(created_at) OVER (ORDER BY created_at)))) as avg_processing_time
FROM payment_events
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY stripe_event_type, status;
```

### 3. Stripe Dashboard Monitoring
- **Webhooks section**: Check delivery status and retry attempts
- **Events section**: Monitor event processing and failures
- **Logs section**: Review detailed error messages

## Common Issues and Solutions

### Issue 1: Webhook Signature Verification Fails
**Symptoms:**
- 400 Bad Request errors
- "Webhook signature verification failed" in logs

**Solutions:**
1. Verify `STRIPE_WEBHOOK_SECRET` is correct
2. Check webhook endpoint URL matches exactly
3. Ensure no proxy/load balancer modifies the request body

### Issue 2: Database Update Failures
**Symptoms:**
- Orders not updating status
- "Failed to update order" errors in logs

**Solutions:**
1. Check `SUPABASE_SERVICE_ROLE_KEY` permissions
2. Verify database schema matches expected structure
3. Check RLS policies allow service role operations

### Issue 3: Missing Order Metadata
**Symptoms:**
- "No order_id found in payment intent metadata" warnings
- Orders not being updated

**Solutions:**
1. Ensure iOS app includes `order_id` in payment intent metadata
2. Verify metadata is being sent correctly
3. Check Stripe dashboard for metadata in payment intents

### Issue 4: High Processing Times
**Symptoms:**
- Slow webhook responses
- Stripe retry attempts

**Solutions:**
1. Optimize database queries with proper indexing
2. Review function performance in Supabase dashboard
3. Consider database connection pooling

## Performance Optimization

### 1. Database Indexing
```sql
-- Ensure critical indexes exist
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_payment_intent_id ON orders(payment_intent_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_updated_at ON orders(updated_at);
```

### 2. Batch Operations
- Consider batching multiple order updates
- Use database transactions for related operations
- Implement retry logic with exponential backoff

### 3. Caching
- Cache frequently accessed order data
- Use Redis for high-performance caching
- Implement cache invalidation strategies

## Security Best Practices

### 1. Webhook Security
- Always verify Stripe webhook signatures
- Use HTTPS for all webhook endpoints
- Implement rate limiting to prevent abuse

### 2. Database Security
- Enable Row Level Security (RLS)
- Use service role key only for webhook operations
- Regularly rotate API keys

### 3. Error Handling
- Never expose sensitive information in error messages
- Log errors securely without exposing PII
- Implement proper error monitoring

## Testing Strategies

### 1. Unit Testing
- Test individual webhook handlers
- Mock Stripe API responses
- Verify database update logic

### 2. Integration Testing
- Test complete webhook flow
- Verify database state changes
- Test error scenarios

### 3. Load Testing
- Test webhook performance under load
- Verify database connection handling
- Monitor resource usage

## Future Enhancements

### 1. Real-time Notifications
```typescript
// Implement Supabase realtime for order updates
const channel = supabase
  .channel('order-updates')
  .on('postgres_changes', 
    { event: 'UPDATE', schema: 'public', table: 'orders' },
    (payload) => {
      // Send push notification or update UI
      console.log('Order updated:', payload.new);
    }
  )
  .subscribe();
```

### 2. Advanced Analytics
- Track order processing times
- Monitor payment success rates
- Analyze customer behavior patterns

### 3. Automated Actions
- Auto-cancel orders after payment failure
- Send delivery reminders
- Process disputes automatically

## Support and Resources

### 1. Documentation
- [Stripe Webhook Guide](https://stripe.com/docs/webhooks)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
- [Deno Runtime](https://deno.land/manual)

### 2. Community Support
- Stripe Community Forums
- Supabase Discord
- GitHub Issues

### 3. Monitoring Tools
- Supabase Dashboard
- Stripe Dashboard
- Custom logging and alerting

## Conclusion

This webhook implementation provides a robust foundation for managing order lifecycle in the Zip iOS app. By following this guide, you'll have:

- ✅ Real-time order status updates
- ✅ Comprehensive payment event handling
- ✅ Robust error handling and logging
- ✅ Secure webhook processing
- ✅ Scalable database architecture
- ✅ Comprehensive testing framework

The system is designed to handle high-volume scenarios while maintaining data consistency and providing excellent user experience through real-time updates.
