# Stripe Webhook Functions

This directory contains the Stripe webhook implementation for the Zip iOS app, which handles payment events and updates order statuses in real-time.

## Overview

The webhook functions provide comprehensive order lifecycle management by:
- Processing Stripe payment events
- Updating order statuses in the database
- Managing delivery time estimates
- Handling disputes
- Logging all payment activities for analytics

## Supported Stripe Events

### Payment Intent Events
- `payment_intent.succeeded` - Payment completed successfully
- `payment_intent.payment_failed` - Payment failed
- `payment_intent.canceled` - Payment canceled
- `payment_intent.processing` - Payment being processed
- `payment_intent.requires_action` - Payment requires user action

### Charge Events
- `charge.succeeded` - Charge completed successfully
- `charge.failed` - Charge failed
- `charge.dispute.created` - Dispute created
- `charge.dispute.closed` - Dispute resolved

### Invoice Events
- `invoice.payment_succeeded` - Invoice payment completed
- `invoice.payment_failed` - Invoice payment failed

### Subscription Events
- `customer.subscription.deleted` - Subscription canceled

## Order Status Flow

```
pending → in_queue → in_progress → delivered
    ↓
cancelled (if payment fails/cancels)
    ↓
disputed (if dispute created)
```

## Database Schema

The webhook functions work with the following database structure:

### Orders Table
- `id` - Unique order identifier
- `status` - Current order status
- `payment_intent_id` - Stripe payment intent ID
- `estimated_delivery_time` - Expected delivery time

### Order Status History Table
- Tracks all status changes with timestamps
- Includes reasons and metadata for each change

### Payment Events Table
- Logs all Stripe webhook events
- Links events to orders for tracking

## Environment Variables

Required environment variables:

```bash
STRIPE_SECRET_KEY=sk_test_... # Your Stripe secret key
STRIPE_WEBHOOK_SECRET=whsec_... # Your webhook endpoint secret
SUPABASE_URL=https://... # Your Supabase project URL
SUPABASE_SERVICE_ROLE_KEY=eyJ... # Your Supabase service role key
```

## Local Development

### Prerequisites
1. Supabase CLI installed
2. Stripe account with webhook endpoint configured
3. Local Supabase instance running

### Setup
1. Start local Supabase:
   ```bash
   supabase start
   ```

2. Set environment variables:
   ```bash
   supabase secrets set STRIPE_SECRET_KEY=sk_test_...
   supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_...
   ```

3. Deploy the function:
   ```bash
   supabase functions deploy stripe-webhook
   ```

### Testing Locally

#### Test with Stripe CLI
1. Install Stripe CLI
2. Forward webhooks to local endpoint:
   ```bash
   stripe listen --forward-to localhost:54321/functions/v1/stripe-webhook
   ```

3. Trigger test events:
   ```bash
   stripe trigger payment_intent.succeeded
   stripe trigger payment_intent.payment_failed
   stripe trigger charge.succeeded
   ```

#### Test with cURL
```bash
curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/stripe-webhook' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{
    "type": "payment_intent.succeeded",
    "data": {
      "object": {
        "id": "pi_test123",
        "metadata": {
          "order_id": "test-order-uuid"
        },
        "amount": 2000,
        "currency": "usd"
      }
    }
  }'
```

## Production Deployment

### Stripe Dashboard Setup
1. Go to Stripe Dashboard > Developers > Webhooks
2. Add endpoint: `https://your-project.supabase.co/functions/v1/stripe-webhook`
3. Select events to listen for:
   - `payment_intent.succeeded`
   - `payment_intent.payment_failed`
   - `payment_intent.canceled`
   - `charge.succeeded`
   - `charge.failed`
   
   - `charge.dispute.created`
   - `charge.dispute.closed`

### Supabase Deployment
1. Deploy function:
   ```bash
   supabase functions deploy stripe-webhook --project-ref YOUR_PROJECT_REF
   ```

2. Set production secrets:
   ```bash
   supabase secrets set --project-ref YOUR_PROJECT_REF STRIPE_SECRET_KEY=sk_live_...
   supabase secrets set --project-ref YOUR_PROJECT_REF STRIPE_WEBHOOK_SECRET=whsec_...
   ```

## Error Handling

The webhook implements comprehensive error handling:

### Signature Verification
- Validates Stripe webhook signatures
- Logs verification failures with debugging info
- Returns appropriate HTTP status codes

### Database Operations
- Graceful handling of database connection issues
- Detailed error logging for failed updates
- Continues processing other events if one fails

### Event Processing
- Individual event processing errors don't fail the entire webhook
- All errors are logged for debugging
- Webhook acknowledges receipt even if processing fails

## Monitoring and Logging

### Log Levels
- ✅ Success operations
- ❌ Errors and failures
- ⚠️ Warnings and edge cases
- 📊 Analytics and tracking
- 🔧 Configuration and setup
- 🔄 Processing status

### Key Metrics to Monitor
- Webhook delivery success rate
- Order status update success rate
- Processing time per event
- Error frequency by event type
- Database operation performance

## Troubleshooting

### Common Issues

#### Webhook Signature Verification Fails
- Check `STRIPE_WEBHOOK_SECRET` is correct
- Ensure webhook endpoint URL matches Stripe dashboard
- Verify Stripe API version compatibility

#### Database Update Failures
- Check `SUPABASE_SERVICE_ROLE_KEY` has proper permissions
- Verify database schema matches expected structure
- Check RLS policies allow service role operations

#### Event Processing Errors
- Review logs for specific error messages
- Check order metadata contains required fields
- Verify Stripe event structure hasn't changed

### Debug Mode
Enable detailed logging by setting:
```bash
SUPABASE_FUNCTIONS_DEBUG=true
```

### Health Check
Test webhook health with:
```bash
curl -X GET 'https://your-project.supabase.co/functions/v1/stripe-webhook/health'
```

## Security Considerations

### Authentication
- Webhook endpoint doesn't require JWT authentication
- Stripe signature verification ensures authenticity
- Service role key used for database operations

### Data Validation
- All input data validated before processing
- SQL injection prevention through parameterized queries
- Amount validation prevents negative values

### Access Control
- Row Level Security (RLS) enabled on all tables
- Users can only access their own orders
- Service role has necessary permissions for webhook operations

## Performance Optimization

### Database Operations
- Efficient indexing on frequently queried fields
- Batch operations where possible
- Connection pooling for database operations

### Event Processing
- Asynchronous processing of non-critical operations
- Efficient error handling to prevent blocking
- Logging optimized for production environments

## Future Enhancements

### Planned Features
- Real-time notifications via Supabase realtime
- Integration with delivery tracking systems
- Advanced analytics and reporting
- Automated dispute resolution workflows

### Scalability Improvements
- Event queuing for high-volume scenarios
- Horizontal scaling of webhook processors
- Caching layer for frequently accessed data

## Support

For issues or questions:
1. Check the logs for error details
2. Verify environment variable configuration
3. Test with Stripe CLI locally
4. Review database schema and permissions
5. Check Stripe webhook dashboard for delivery status

## Related Documentation

- [Stripe Webhook Guide](https://stripe.com/docs/webhooks)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
- [Database Schema](001_create_orders_table.sql)
- [Webhook Integration Guide](../../WEBHOOK_SETUP_GUIDE.md)
