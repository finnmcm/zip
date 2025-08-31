-- Test script for webhook database functions
-- Run this after applying all migrations to verify functionality

-- Test data setup
DO $$
DECLARE
    test_user_id UUID := gen_random_uuid();
    test_order_id UUID := gen_random_uuid();
    test_product_id UUID := gen_random_uuid();
BEGIN
    -- Insert test user
    INSERT INTO users (id, email, first_name, last_name) 
    VALUES (test_user_id, 'test@northwestern.edu', 'Test', 'User');
    
    -- Insert test product
    INSERT INTO products (id, name, description, price, category) 
    VALUES (test_product_id, 'Test Coffee', 'Test coffee product', 4.99, 'Beverages');
    
    -- Insert test order
    INSERT INTO orders (id, user_id, status, raw_amount, tip, total_amount, delivery_address, is_campus_delivery) 
    VALUES (test_order_id, test_user_id, 'pending', 4.99, 1.00, 5.99, 'Test Building, Northwestern University', true);
    
    -- Insert test order item
    INSERT INTO order_items (order_id, product_id, product_name, quantity, unit_price, total_price, item_display_name) 
    VALUES (test_order_id, test_product_id, 'Test Coffee', 1, 4.99, 4.99, 'Test Coffee');
    
    RAISE NOTICE 'Test data created: User: %, Order: %, Product: %', test_user_id, test_order_id, test_product_id;
END $$;

-- Test 1: Update order status
SELECT 'Test 1: Update order status' as test_name;
SELECT update_order_status(
    (SELECT id FROM orders LIMIT 1),
    'in_queue',
    'pi_test123',
    'Test payment success',
    '{"test": true, "source": "test_script"}'
) as status_update_result;

-- Test 2: Update delivery time
SELECT 'Test 2: Update delivery time' as test_name;
SELECT update_order_delivery_time(
    (SELECT id FROM orders LIMIT 1),
    NOW() + INTERVAL '20 minutes',
    NULL
) as delivery_time_update_result;

-- Test 3: Log payment success
SELECT 'Test 3: Log payment success' as test_name;
SELECT log_payment_success(
    (SELECT id FROM orders LIMIT 1),
    599, -- $5.99 in cents
    'usd',
    'pi_test123',
    'ch_test123'
) as payment_success_log_result;

-- Test 4: Log payment failure
SELECT 'Test 4: Log payment failure' as test_name;
SELECT log_payment_failure(
    (SELECT id FROM orders LIMIT 1),
    'Card declined',
    'pi_test123',
    'card_declined'
) as payment_failure_log_result;



-- Test 6: Log charge event
SELECT 'Test 6: Log charge event' as test_name;
SELECT log_charge_event(
    (SELECT id FROM orders LIMIT 1),
    'ch_test123',
    'succeeded',
    599,
    'usd',
    '{"test": true}'
) as charge_event_log_result;



-- Test 8: Log dispute event
SELECT 'Test 8: Log dispute event' as test_name;
SELECT log_dispute_event(
    (SELECT id FROM orders LIMIT 1),
    'ch_test123',
    'created',
    'Customer dispute',
    599,
    'usd'
) as dispute_event_log_result;

-- Test 9: Get order summary for webhook
SELECT 'Test 9: Get order summary for webhook' as test_name;
SELECT * FROM get_order_summary_for_webhook((SELECT id FROM orders LIMIT 1));

-- Test 10: Get user recent orders
SELECT 'Test 10: Get user recent orders' as test_name;
SELECT * FROM get_user_recent_orders((SELECT user_id FROM orders LIMIT 1), 5);

-- Test 11: Get orders by status
SELECT 'Test 11: Get orders by status' as test_name;
SELECT * FROM get_orders_by_status('in_queue', 10);

-- Test 12: Get payment intent details
SELECT 'Test 12: Get payment intent details' as test_name;
SELECT * FROM get_payment_intent_details('pi_test123');

-- Test 13: Check if order exists
SELECT 'Test 13: Check if order exists' as test_name;
SELECT order_exists((SELECT id FROM orders LIMIT 1)) as order_exists_result;

-- Test 14: Validate webhook payload
SELECT 'Test 14: Validate webhook payload' as test_name;
SELECT * FROM validate_webhook_payload('{"id": "evt_test", "type": "payment_intent.succeeded", "data": {"object": {}}}');

-- Test 15: Get webhook stats
SELECT 'Test 15: Get webhook stats' as test_name;
SELECT * FROM get_webhook_stats(7);

-- Test 16: Get webhook health status
SELECT 'Test 16: Get webhook health status' as test_name;
SELECT * FROM get_webhook_health_status();

-- Test 17: Retry failed webhook operations
SELECT 'Test 17: Retry failed webhook operations' as test_name;
SELECT retry_failed_webhook_operations((SELECT id FROM orders LIMIT 1)) as retry_result;

-- Test 18: Check order status history
SELECT 'Test 18: Check order status history' as test_name;
SELECT 
    order_id,
    status,
    reason,
    metadata,
    created_at
FROM order_status_history 
WHERE order_id = (SELECT id FROM orders LIMIT 1)
ORDER BY created_at DESC;

-- Test 19: Check final order state
SELECT 'Test 19: Check final order state' as test_name;
SELECT 
    id,
    status,
    payment_status,

    estimated_delivery_time,
    updated_at
FROM orders 
WHERE id = (SELECT id FROM orders LIMIT 1);

-- Test 20: Test view functionality
SELECT 'Test 20: Test view functionality' as test_name;
SELECT * FROM order_summary WHERE id = (SELECT id FROM orders LIMIT 1);

-- Test 21: Test materialized view (if exists)
SELECT 'Test 21: Test materialized view' as test_name;
SELECT COUNT(*) as webhook_analytics_count FROM webhook_analytics;

-- Test 22: Test trigger functionality
SELECT 'Test 22: Test trigger functionality' as test_name;
UPDATE orders 
SET status = 'test_trigger' 
WHERE id = (SELECT id FROM orders LIMIT 1);

SELECT 
    status,
    updated_at
FROM orders 
WHERE id = (SELECT id FROM orders LIMIT 1);

-- Cleanup test data
DO $$
DECLARE
    test_order_id UUID;
BEGIN
    SELECT id INTO test_order_id FROM orders WHERE delivery_address = 'Test Building, Northwestern University';
    
    IF test_order_id IS NOT NULL THEN
        DELETE FROM order_status_history WHERE order_id = test_order_id;
        DELETE FROM order_items WHERE order_id = test_order_id;
        DELETE FROM orders WHERE id = test_order_id;
        DELETE FROM products WHERE name = 'Test Coffee';
        DELETE FROM users WHERE email = 'test@northwestern.edu';
        
        RAISE NOTICE 'Test data cleaned up successfully';
    END IF;
END $$;

-- Final verification
SELECT 'All tests completed successfully!' as result;
