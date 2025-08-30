-- Test script for product quantity monitoring functions
-- Run this after applying migration 004 to verify functionality

-- Test data setup
DO $$
DECLARE
    test_user_id UUID := gen_random_uuid();
    test_product_id UUID := gen_random_uuid();
    test_restock_id UUID;
BEGIN
    -- Insert test user
    INSERT INTO users (id, email, first_name, last_name) 
    VALUES (test_user_id, 'inventory@northwestern.edu', 'Inventory', 'Manager');
    
    -- Insert test product with initial stock
    INSERT INTO products (id, name, description, price, category, stock_quantity, in_stock) 
    VALUES (test_product_id, 'Test Coffee Beans', 'Premium coffee beans for testing', 12.99, 'Beverages', 50, true);
    
    RAISE NOTICE 'Test data created: User: %, Product: %', test_user_id, test_product_id;
END $$;

-- Test 1: Update product quantity (decrease)
SELECT 'Test 1: Update product quantity (decrease)' as test_name;
SELECT update_product_quantity(
    (SELECT id FROM products WHERE name = 'Test Coffee Beans'),
    45,
    'order_placed',
    'Test order reduced stock',
    gen_random_uuid(),
    'order',
    (SELECT id FROM users WHERE email = 'inventory@northwestern.edu'),
    '{"test": true, "source": "test_script"}'
) as quantity_update_result;

-- Test 2: Check if low stock alert was created
SELECT 'Test 2: Check low stock alert creation' as test_name;
SELECT 
    alert_type,
    threshold_quantity,
    current_quantity,
    alert_message,
    is_resolved
FROM product_low_stock_alerts 
WHERE product_id = (SELECT id FROM products WHERE name = 'Test Coffee Beans')
AND is_resolved = FALSE;

-- Test 3: Update product quantity (further decrease to trigger critical alert)
SELECT 'Test 3: Update product quantity (critical low)' as test_name;
SELECT update_product_quantity(
    (SELECT id FROM products WHERE name = 'Test Coffee Beans'),
    1,
    'order_placed',
    'Another test order',
    gen_random_uuid(),
    'order',
    (SELECT id FROM users WHERE email = 'inventory@northwestern.edu'),
    '{"test": true, "source": "test_script"}'
) as critical_quantity_update_result;

-- Test 4: Check critical low stock alert
SELECT 'Test 4: Check critical low stock alert' as test_name;
SELECT 
    alert_type,
    threshold_quantity,
    current_quantity,
    alert_message
FROM product_low_stock_alerts 
WHERE product_id = (SELECT id FROM products WHERE name = 'Test Coffee Beans')
AND alert_type = 'critical_low'
AND is_resolved = FALSE;

-- Test 5: Create a restock record
SELECT 'Test 5: Create restock record' as test_name;
SELECT create_product_restock(
    (SELECT id FROM products WHERE name = 'Test Coffee Beans'),
    100,
    'Test Supplier Co.',
    10.50,
    NOW() + INTERVAL '3 days',
    'Test restock for testing purposes',
    (SELECT id FROM users WHERE email = 'inventory@northwestern.edu')
) as restock_id;

-- Test 6: Check restock record
SELECT 'Test 6: Check restock record' as test_name;
SELECT 
    id,
    product_id,
    quantity_added,
    supplier,
    cost_per_unit,
    total_cost,
    status,
    expected_arrival
FROM product_restocks 
WHERE product_id = (SELECT id FROM products WHERE name = 'Test Coffee Beans')
AND supplier = 'Test Supplier Co.';

-- Test 7: Receive the restock
SELECT 'Test 7: Receive restock' as test_name;
SELECT receive_product_restock(
    (SELECT id FROM product_restocks WHERE supplier = 'Test Supplier Co.' LIMIT 1),
    NOW(),
    (SELECT id FROM users WHERE email = 'inventory@northwestern.edu')
) as restock_received_result;

-- Test 8: Check if quantity was updated and alerts resolved
SELECT 'Test 8: Check quantity update and alert resolution' as test_name;
SELECT 
    p.name,
    p.stock_quantity,
    p.in_stock,
    (SELECT COUNT(*) FROM product_low_stock_alerts 
     WHERE product_id = p.id AND is_resolved = FALSE) as active_alerts
FROM products p
WHERE p.name = 'Test Coffee Beans';

-- Test 9: Get product quantity history
SELECT 'Test 9: Get product quantity history' as test_name;
SELECT * FROM get_product_quantity_history(
    (SELECT id FROM products WHERE name = 'Test Coffee Beans'),
    30
);

-- Test 10: Get low stock products
SELECT 'Test 10: Get low stock products' as test_name;
SELECT * FROM get_low_stock_products(50);

-- Test 11: Get inventory analytics
SELECT 'Test 11: Get inventory analytics' as test_name;
SELECT * FROM get_inventory_analytics(30);

-- Test 12: Check product inventory status view
SELECT 'Test 12: Check product inventory status view' as test_name;
SELECT 
    name,
    category,
    stock_quantity,
    in_stock,
    last_change_type,
    last_change_at,
    pending_restocks,
    pending_quantity,
    active_alerts
FROM product_inventory_status 
WHERE name = 'Test Coffee Beans';

-- Test 13: Test manual quantity adjustment
SELECT 'Test 13: Test manual quantity adjustment' as test_name;
SELECT update_product_quantity(
    (SELECT id FROM products WHERE name = 'Test Coffee Beans'),
    95,
    'adjustment',
    'Manual adjustment for testing',
    NULL,
    'manual',
    (SELECT id FROM users WHERE email = 'inventory@northwestern.edu'),
    '{"adjustment_reason": "test", "previous_value": 101}'
) as manual_adjustment_result;

-- Test 14: Test damage/expiry quantity reduction
SELECT 'Test 14: Test damage/expiry quantity reduction' as test_name;
SELECT update_product_quantity(
    (SELECT id FROM products WHERE name = 'Test Coffee Beans'),
    90,
    'damage',
    'Damaged during testing',
    NULL,
    'damage',
    (SELECT id FROM users WHERE email = 'inventory@northwestern.edu'),
    '{"damage_type": "test_damage", "units_affected": 5}'
) as damage_adjustment_result;

-- Test 15: Check quantity changes table
SELECT 'Test 15: Check quantity changes table' as test_name;
SELECT 
    change_type,
    previous_quantity,
    new_quantity,
    quantity_difference,
    reason,
    reference_type,
    created_at
FROM product_quantity_changes 
WHERE product_id = (SELECT id FROM products WHERE name = 'Test Coffee Beans')
ORDER BY created_at DESC;

-- Test 16: Test bulk order processing simulation
SELECT 'Test 16: Test bulk order processing simulation' as test_name;
-- Create a test order
DO $$
DECLARE
    test_order_id UUID := gen_random_uuid();
    test_user_id UUID;
    test_product_id UUID;
BEGIN
    test_user_id := (SELECT id FROM users WHERE email = 'inventory@northwestern.edu');
    test_product_id := (SELECT id FROM products WHERE name = 'Test Coffee Beans');
    
    -- Insert test order
    INSERT INTO orders (id, user_id, status, raw_amount, tip, total_amount, delivery_address, is_campus_delivery) 
    VALUES (test_order_id, test_user_id, 'pending', 25.98, 2.00, 27.98, 'Test Building, Northwestern University', true);
    
    -- Insert order items
    INSERT INTO order_items (order_id, product_id, product_name, quantity, unit_price, total_price, item_display_name) 
    VALUES (test_order_id, test_product_id, 'Test Coffee Beans', 2, 12.99, 25.98, 'Test Coffee Beans');
    
    -- Process quantity changes
    PERFORM process_order_quantity_changes(test_order_id, test_user_id);
    
    RAISE NOTICE 'Bulk order processed: Order ID %', test_order_id;
END $$;

-- Test 17: Check final product state after bulk order
SELECT 'Test 17: Check final product state after bulk order' as test_name;
SELECT 
    p.name,
    p.stock_quantity,
    p.in_stock,
    p.updated_at
FROM products p
WHERE p.name = 'Test Coffee Beans';

-- Test 18: Test inventory analytics after all changes
SELECT 'Test 18: Test inventory analytics after all changes' as test_name;
SELECT * FROM get_inventory_analytics(1);

-- Test 19: Test low stock products function with different threshold
SELECT 'Test 19: Test low stock products with different threshold' as test_name;
SELECT * FROM get_low_stock_products(100);

-- Test 20: Test product quantity history with different time ranges
SELECT 'Test 20: Test product quantity history with different time ranges' as test_name;
SELECT 
    'Last 7 days' as time_range,
    COUNT(*) as change_count
FROM get_product_quantity_history(
    (SELECT id FROM products WHERE name = 'Test Coffee Beans'),
    7
)
UNION ALL
SELECT 
    'Last 30 days' as time_range,
    COUNT(*) as change_count
FROM get_product_quantity_history(
    (SELECT id FROM products WHERE name = 'Test Coffee Beans'),
    30
);

-- Cleanup test data
DO $$
DECLARE
    test_product_id UUID;
    test_user_id UUID;
BEGIN
    test_product_id := (SELECT id FROM products WHERE name = 'Test Coffee Beans');
    test_user_id := (SELECT id FROM users WHERE email = 'inventory@northwestern.edu');
    
    IF test_product_id IS NOT NULL THEN
        -- Clean up related data
        DELETE FROM product_quantity_changes WHERE product_id = test_product_id;
        DELETE FROM product_low_stock_alerts WHERE product_id = test_product_id;
        DELETE FROM product_restocks WHERE product_id = test_product_id;
        DELETE FROM order_items WHERE product_id = test_product_id;
        DELETE FROM products WHERE id = test_product_id;
        
        RAISE NOTICE 'Product test data cleaned up';
    END IF;
    
    IF test_user_id IS NOT NULL THEN
        -- Clean up test orders
        DELETE FROM order_status_history WHERE order_id IN (
            SELECT id FROM orders WHERE user_id = test_user_id
        );
        DELETE FROM orders WHERE user_id = test_user_id;
        DELETE FROM users WHERE id = test_user_id;
        
        RAISE NOTICE 'User test data cleaned up';
    END IF;
    
    RAISE NOTICE 'All test data cleaned up successfully';
END $$;

-- Final verification
SELECT 'All product quantity monitoring tests completed successfully!' as result;
