# Payment Quantity Update System

This document describes the database functions and webhook integration for automatically updating product quantities after successful Stripe payments.

## Overview

When a Stripe payment succeeds, the webhook automatically:
1. Updates the order status to "confirmed"
2. Sets the payment status to "paid"
3. Records the payment intent ID
4. Sets an estimated delivery time (20 minutes for campus delivery)
5. **Reduces product quantities based on the order**
6. Logs all changes for audit purposes

## Database Functions

### 1. `update_product_quantities_after_payment(order_id, payment_intent_id)`

**Purpose**: Updates product quantities after a successful payment for a specific order.

**Parameters**:
- `p_order_id` (UUID): The order ID to process
- `p_payment_intent_id` (VARCHAR, optional): Stripe payment intent ID for tracking

**Returns**: BOOLEAN indicating success/failure

**What it does**:
- Verifies the order exists and is confirmed
- Checks stock availability for each product
- Reduces quantities for all items in the order
- Logs quantity changes with detailed metadata
- Creates low stock alerts if needed
- Records the operation in order status history

**Example Usage**:
```sql
SELECT update_product_quantities_after_payment(
    'order-uuid-here'::UUID, 
    'pi_payment_intent_123'
);
```

### 2. `process_payment_success_with_quantities(order_id, payment_intent_id)`

**Purpose**: Comprehensive function that handles the entire payment success workflow.

**Parameters**:
- `p_order_id` (UUID): The order ID to process
- `p_payment_intent_id` (VARCHAR, optional): Stripe payment intent ID

**Returns**: JSONB with detailed results

**What it does**:
- Updates order status to "confirmed"
- Sets payment status to "paid"
- Records payment intent ID
- Sets estimated delivery time (20 minutes)
- Updates product quantities
- Returns comprehensive result object

**Example Usage**:
```sql
SELECT process_payment_success_with_quantities(
    'order-uuid-here'::UUID, 
    'pi_payment_intent_123'
);
```

## Webhook Integration

The Stripe webhook (`supabase/functions/stripe-webhook/index.ts`) automatically calls these functions when:

### Payment Intent Succeeded
```typescript
case "payment_intent.succeeded":
  await handlePaymentSucceeded(eventData);
  break;
```

### Charge Succeeded
```typescript
case "charge.succeeded":
  await handleChargeSucceeded(eventData);
  break;
```

Both handlers call `processPaymentSuccessWithQuantities()` which:
1. Calls the database function via REST API
2. Handles any errors gracefully
3. Logs the results for debugging

## Database Schema Requirements

The system requires these tables (already created in migrations):

- `orders` - Main order information
- `order_items` - Individual items in orders
- `products` - Product catalog with stock quantities
- `product_quantity_changes` - Audit trail for quantity changes
- `order_status_history` - Order status change history
- `product_low_stock_alerts` - Low stock monitoring

## Error Handling

The system handles several error scenarios:

### Insufficient Stock
- Checks stock before processing
- Fails gracefully with detailed error messages
- Prevents overselling

### Order Not Found
- Validates order existence
- Logs errors for debugging

### Database Errors
- Uses transactions for data consistency
- Rolls back changes on failure
- Provides detailed error logging

## Testing

Use the test file `test_payment_quantity_update.sql` to verify functionality:

```bash
# Run in Supabase SQL editor or via psql
\i test_payment_quantity_update.sql
```

The test file:
1. Creates test products with known quantities
2. Creates test orders
3. Tests both functions
4. Verifies quantity updates
5. Tests error handling
6. Provides cleanup options

## Monitoring and Auditing

### Quantity Change History
All quantity changes are logged in `product_quantity_changes` with:
- Previous and new quantities
- Change reason and type
- Reference to order/payment
- User who triggered the change
- Timestamp

### Order Status History
Order status changes are tracked in `order_status_history` with:
- Status changes
- Reasons for changes
- Metadata including payment details
- Timestamps

### Low Stock Alerts
Automatic alerts are created when:
- Stock ≤ 5: Low stock warning
- Stock = 0: Out of stock alert
- Stock ≤ 2: Critical low stock alert

## Security

- Functions use `SECURITY DEFINER` for elevated permissions
- Only `service_role` can execute these functions
- All operations are logged for audit purposes
- Input validation prevents SQL injection

## Performance Considerations

- Indexes on `payment_intent_id` for fast lookups
- Efficient joins between orders and products
- Batch processing of order items
- Minimal database round trips

## Troubleshooting

### Common Issues

1. **Function not found**: Ensure migration 006 has been applied
2. **Permission denied**: Check service role permissions
3. **Order not found**: Verify order ID exists and is valid
4. **Insufficient stock**: Check current product quantities

### Debug Queries

```sql
-- Check order status
SELECT * FROM orders WHERE id = 'order-uuid-here';

-- Check product quantities
SELECT name, stock_quantity, in_stock FROM products WHERE id IN (
  SELECT product_id FROM order_items WHERE order_id = 'order-uuid-here'
);

-- Check quantity change history
SELECT * FROM product_quantity_changes 
WHERE reference_id = 'order-uuid-here' 
ORDER BY created_at DESC;

-- Check order status history
SELECT * FROM order_status_history 
WHERE order_id = 'order-uuid-here' 
ORDER BY created_at DESC;
```

## Future Enhancements

Potential improvements:
- Real-time stock updates via WebSockets
- Integration with inventory management systems
- Automated restock notifications
- Stock reservation during checkout
- Bulk quantity updates for multiple orders

## Support

For issues or questions:
1. Check the logs in the webhook function
2. Verify database function permissions
3. Test with the provided test file
4. Review order and product data integrity
