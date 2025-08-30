# Supabase Database Functions for Stripe Webhook Integration

This document describes the database functions created to support the Stripe webhook operations in the Zip iOS app.

## Overview

The database functions are designed to handle all the database operations that the Stripe webhook script needs to perform, including:
- Order status updates
- Payment event logging
- Delivery time management
- Dispute processing
- Analytics and monitoring

## Migration Files

### 001_create_orders_table.sql
Creates the core database schema:
- `orders` table - Main order information
- `order_items` table - Individual items in orders
- `order_status_history` table - Audit trail of all status changes
- `products` table - Product catalog
- `users` table - User information
- Indexes for performance optimization

### 002_create_webhook_functions.sql
Creates the primary webhook functions:
- Order status management
- Payment event logging
- Dispute handling
- Basic utility functions

### 003_create_webhook_utilities.sql
Creates advanced utility functions:
- Analytics and reporting
- Bulk operations
- Health monitoring
- Performance optimization

### 004_create_product_quantity_monitoring.sql
Creates product quantity monitoring system:
- Inventory tracking and audit trails
- Restock management
- Low stock alerts
- Quantity change history

## Core Functions

### Order Status Management

#### `update_order_status(order_id, status, payment_intent_id, reason, metadata)`
Updates an order's status and logs the change in the history table.

**Parameters:**
- `order_id` (UUID): The order to update
- `status` (VARCHAR): New status (e.g., 'confirmed', 'cancelled')
- `payment_intent_id` (VARCHAR, optional): Stripe payment intent ID
- `reason` (TEXT, optional): Reason for status change
- `metadata` (JSONB, optional): Additional metadata

**Returns:** Boolean indicating success

**Usage Example:**
```sql
SELECT update_order_status(
    '123e4567-e89b-12d3-a456-426614174000'::UUID,
    'confirmed',
    'pi_1234567890',
    'Payment succeeded',
    '{"source": "stripe_webhook", "event_id": "evt_123"}'
);
```

#### `update_order_delivery_time(order_id, estimated_delivery_time, actual_delivery_time)`
Updates delivery time information for an order.

**Parameters:**
- `order_id` (UUID): The order to update
- `estimated_delivery_time` (TIMESTAMP): Estimated delivery time
- `actual_delivery_time` (TIMESTAMP, optional): Actual delivery time

**Returns:** Boolean indicating success

### Payment Event Logging

#### `log_payment_success(order_id, amount, currency, payment_intent_id, charge_id)`
Logs a successful payment event.

**Parameters:**
- `order_id` (UUID): The order ID
- `amount` (INTEGER): Amount in cents (Stripe format)
- `currency` (VARCHAR): Currency code (e.g., 'usd')
- `payment_intent_id` (VARCHAR): Stripe payment intent ID
- `charge_id` (VARCHAR, optional): Stripe charge ID

**Returns:** Boolean indicating success

#### `log_payment_failure(order_id, reason, payment_intent_id, error_code)`
Logs a failed payment event.

**Parameters:**
- `order_id` (UUID): The order ID
- `reason` (TEXT): Reason for failure
- `payment_intent_id` (VARCHAR): Stripe payment intent ID
- `error_code` (VARCHAR, optional): Stripe error code



#### `log_dispute_event(order_id, charge_id, event_type, reason, amount, currency)`
Logs dispute events (chargebacks, etc.).

### Utility Functions

#### `get_order_summary_for_webhook(order_id)`
Returns comprehensive order information for webhook processing.

#### `get_webhook_stats(days)`
Returns webhook processing statistics for monitoring.

#### `get_webhook_health_status()`
Returns health metrics for the webhook system.

#### `cleanup_old_webhook_logs(days_to_keep)`
Cleans up old webhook logs for maintenance.

### Product Quantity Monitoring Functions

#### `update_product_quantity(product_id, new_quantity, change_type, reason, reference_id, reference_type, user_id, metadata)`
Updates product quantity and logs the change with full audit trail.

**Parameters:**
- `product_id` (UUID): The product to update
- `new_quantity` (INTEGER): New stock quantity
- `change_type` (VARCHAR): Type of change ('order_placed', 'restock', 'adjustment', 'damage', 'expiry', 'manual')
- `reason` (TEXT, optional): Reason for the change
- `reference_id` (UUID, optional): Related order, restock, or adjustment ID
- `reference_type` (VARCHAR, optional): Type of reference ('order', 'restock', 'adjustment')
- `user_id` (UUID, optional): User who made the change
- `metadata` (JSONB, optional): Additional metadata

**Returns:** Boolean indicating success

**Usage Example:**
```sql
SELECT update_product_quantity(
    '123e4567-e89b-12d3-a456-426614174000'::UUID,
    45,
    'order_placed',
    'Order #12345 reduced stock',
    '123e4567-e89b-12d3-a456-426614174001'::UUID,
    'order',
    '123e4567-e89b-12d3-a456-426614174002'::UUID,
    '{"order_number": "12345", "customer": "student@northwestern.edu"}'
);
```

#### `process_order_quantity_changes(order_id, user_id)`
Automatically processes all items in an order and updates product quantities.

#### `create_product_restock(product_id, quantity_added, supplier, cost_per_unit, expected_arrival, notes, created_by)`
Creates a restock record for inventory management.

#### `receive_product_restock(restock_id, actual_arrival, received_by)`
Marks a restock as received and updates product quantities.

#### `get_product_quantity_history(product_id, days)`
Returns complete history of quantity changes for a product.

#### `get_low_stock_products(threshold)`
Returns products that are running low on stock.

#### `get_inventory_analytics(days)`
Returns comprehensive inventory analytics and metrics.

## Integration with Stripe Webhook

The webhook script calls these functions through HTTP requests to the Supabase REST API. Here's how the integration works:

### 1. Webhook Receives Event
```typescript
// In stripe-webhook/index.ts
case "payment_intent.succeeded":
    await handlePaymentSucceeded(eventData);
    break;
```

### 2. Webhook Calls Database Function
```typescript
// Update order status
await updateOrderStatus(orderId, "confirmed", paymentIntent.id);

// Set delivery time
await updateOrderDeliveryTime(orderId, estimatedDeliveryTime);

// Log payment success
await logPaymentSuccess(orderId, paymentIntent.amount, paymentIntent.currency);
```

### 3. Database Function Executes
The function updates the database and logs the event:
```sql
-- Updates orders table
UPDATE orders SET status = 'confirmed', updated_at = NOW() WHERE id = order_id;

-- Logs to order_status_history
INSERT INTO order_status_history (order_id, status, reason, metadata) VALUES (...);
```

## Security and Permissions

All functions are created with `SECURITY DEFINER`, meaning they run with the privileges of the function creator (service_role). This ensures:

- Functions can only be called by authenticated users with proper permissions
- Database operations are performed with elevated privileges when needed
- Row-level security policies are respected

**Permission Grants:**
- `service_role`: Full access to all functions
- `authenticated`: Read access to order data
- `anon`: No access (for security)

## Performance Considerations

### Indexes
- Primary keys on all tables
- Indexes on frequently queried columns (status, payment_intent_id, created_at)
- GIN index on JSONB metadata for efficient event type queries
- Product quantity monitoring tables with comprehensive audit trails

### Materialized Views
- `webhook_analytics`: Pre-computed analytics for high-volume scenarios
- Can be refreshed on schedule or manually

### Query Optimization
- Functions use efficient SQL with proper JOINs
- Status history queries are limited and ordered
- Bulk operations are supported for high-volume processing

## Monitoring and Maintenance

### Health Checks
Use `get_webhook_health_status()` to monitor:
- Total webhook events processed
- Failed webhook events
- Last webhook event timestamp

### Analytics
Use `get_webhook_stats(days)` to track:
- Event counts by type
- Success/failure rates
- Processing performance

### Cleanup
Use `cleanup_old_webhook_logs(days_to_keep)` to:
- Remove old webhook logs
- Maintain database performance
- Comply with data retention policies

## Error Handling

All functions include comprehensive error handling:
- Try-catch blocks with detailed error messages
- Rollback on failure
- Logging of errors for debugging
- Return values indicating success/failure

## Testing

### Local Testing
```bash
# Start Supabase locally
supabase start

# Apply migrations
supabase db reset

# Test webhook functions
psql -h localhost -U postgres -d postgres -f supabase/test_webhook_functions.sql

# Test product quantity monitoring functions
psql -h localhost -U postgres -d postgres -f supabase/test_product_quantity_monitoring.sql
```

### Function Validation
```sql
-- Test webhook payload validation
SELECT * FROM validate_webhook_payload('{"id": "test", "type": "payment_intent.succeeded", "data": {}}');

-- Check webhook health
SELECT * FROM get_webhook_health_status();
```

## Troubleshooting

### Common Issues

1. **Permission Denied**
   - Ensure service_role key is used
   - Check function permissions are granted

2. **Function Not Found**
   - Verify migrations have been applied
   - Check function names match exactly

3. **Performance Issues**
   - Monitor query execution plans
   - Check index usage
   - Consider materialized views for analytics

### Debugging

1. **Enable Logging**
   ```sql
   SET log_statement = 'all';
   SET log_min_messages = 'notice';
   ```

2. **Check Function Execution**
   ```sql
   SELECT * FROM pg_stat_user_functions WHERE funcname LIKE '%webhook%';
   ```

3. **Monitor Table Growth**
   ```sql
   SELECT schemaname, tablename, n_tup_ins, n_tup_upd, n_tup_del 
   FROM pg_stat_user_tables 
   WHERE tablename LIKE '%order%';
   ```

## Future Enhancements

### Planned Features
- Real-time notifications via Supabase realtime
- Advanced analytics dashboard
- Automated retry mechanisms
- Integration with external monitoring services

### Scalability Considerations
- Partitioning for high-volume tables
- Read replicas for analytics queries
- Caching layer for frequently accessed data
- Queue system for webhook processing

## Support

For issues or questions:
1. Check the function logs in Supabase dashboard
2. Review the webhook script logs
3. Test functions individually in the SQL editor
4. Monitor database performance metrics

## Related Documentation

- [Stripe Webhook Implementation Guide](../WEBHOOK_IMPLEMENTATION_GUIDE.md)
- [Supabase Setup Guide](../SUPABASE_SETUP.md)
- [Stripe Integration README](../README_STRIPE.md)
