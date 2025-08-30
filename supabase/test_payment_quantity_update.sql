-- Test file for payment quantity update functions
-- This file tests the new functions that update product quantities after successful Stripe payments

-- Test 1: Test the update_product_quantities_after_payment function
-- First, let's create some test data

-- Insert test products
INSERT INTO products (id, name, description, price, category, stock_quantity, in_stock) VALUES
('11111111-1111-1111-1111-111111111111', 'Test Coffee', 'Test coffee product', 4.99, 'Beverages', 50, true),
('22222222-2222-2222-2222-222222222222', 'Test Sandwich', 'Test sandwich product', 8.99, 'Food', 25, true),
('33333333-3333-3333-3333-333333333333', 'Test Snack', 'Test snack product', 2.99, 'Snacks', 100, true)
ON CONFLICT (id) DO NOTHING;

-- Insert test user
INSERT INTO users (id, email, first_name, last_name) VALUES
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'test@u.northwestern.edu', 'Test', 'User')
ON CONFLICT (id) DO NOTHING;

-- Insert test order
INSERT INTO orders (id, user_id, status, raw_amount, tip, total_amount, delivery_address, is_campus_delivery) VALUES
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'confirmed', 15.97, 2.00, 17.97, 'Test Address', true)
ON CONFLICT (id) DO NOTHING;

-- Insert test order items
INSERT INTO order_items (id, order_id, product_id, product_name, quantity, unit_price, total_price) VALUES
('cccccccc-cccc-cccc-cccc-cccccccccccc', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111', 'Test Coffee', 2, 4.99, 9.98),
('dddddddd-dddd-dddd-dddd-dddddddddddd', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222', 'Test Sandwich', 1, 8.99, 8.99)
ON CONFLICT (id) DO NOTHING;

-- Test the function
SELECT 'Testing update_product_quantities_after_payment function...' as test_description;

-- Check initial quantities
SELECT 'Initial product quantities:' as status, name, stock_quantity, in_stock 
FROM products 
WHERE id IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333');

-- Test the function
SELECT update_product_quantities_after_payment(
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'::UUID, 
    'pi_test_payment_intent_123'
) as function_result;

-- Check updated quantities
SELECT 'Updated product quantities:' as status, name, stock_quantity, in_stock 
FROM products 
WHERE id IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333');

-- Check quantity change history
SELECT 'Quantity change history:' as status, 
       p.name as product_name,
       pqc.change_type,
       pqc.previous_quantity,
       pqc.new_quantity,
       pqc.quantity_difference,
       pqc.reason,
       pqc.reference_type,
       pqc.created_at
FROM product_quantity_changes pqc
JOIN products p ON pqc.product_id = p.id
WHERE pqc.reference_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'::UUID
ORDER BY pqc.created_at DESC;

-- Test 2: Test the comprehensive process_payment_success_with_quantities function
SELECT 'Testing process_payment_success_with_quantities function...' as test_description;

-- Create another test order
INSERT INTO orders (id, user_id, status, raw_amount, tip, total_amount, delivery_address, is_campus_delivery) VALUES
('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'pending', 12.97, 1.50, 14.47, 'Test Address 2', true)
ON CONFLICT (id) DO NOTHING;

-- Insert test order items
INSERT INTO order_items (id, order_id, product_id, product_name, quantity, unit_price, total_price) VALUES
('ffffffff-ffff-ffff-ffff-ffffffffffff', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '33333333-3333-3333-3333-333333333333', 'Test Snack', 3, 2.99, 8.97),
('gggggggg-gggg-gggg-gggg-gggggggggggg', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '11111111-1111-1111-1111-111111111111', 'Test Coffee', 1, 4.99, 4.99)
ON CONFLICT (id) DO NOTHING;

-- Check initial order status
SELECT 'Initial order status:' as status, id, status, payment_status, estimated_delivery_time
FROM orders 
WHERE id = 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee';

-- Test the comprehensive function
SELECT process_payment_success_with_quantities(
    'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee'::UUID, 
    'pi_test_payment_intent_456'
) as function_result;

-- Check final order status
SELECT 'Final order status:' as status, id, status, payment_status, estimated_delivery_time, updated_at
FROM orders 
WHERE id = 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee';

-- Check final product quantities
SELECT 'Final product quantities:' as status, name, stock_quantity, in_stock 
FROM products 
WHERE id IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333');

-- Check order status history
SELECT 'Order status history:' as status, 
       osh.status,
       osh.reason,
       osh.metadata,
       osh.created_at
FROM order_status_history osh
WHERE osh.order_id IN ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'::UUID, 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee'::UUID)
ORDER BY osh.created_at DESC;

-- Test 3: Test error handling - insufficient stock
SELECT 'Testing error handling for insufficient stock...' as test_description;

-- Create a product with low stock
INSERT INTO products (id, name, description, price, category, stock_quantity, in_stock) VALUES
('44444444-4444-4444-4444-444444444444', 'Low Stock Product', 'Product with very low stock', 1.99, 'Test', 1, true)
ON CONFLICT (id) DO NOTHING;

-- Create an order that requests more than available
INSERT INTO orders (id, user_id, status, raw_amount, tip, total_amount, delivery_address, is_campus_delivery) VALUES
('hhhhhhhh-hhhh-hhhh-hhhh-hhhhhhhhhhhh', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'confirmed', 5.97, 0.00, 5.97, 'Test Address 3', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO order_items (id, order_id, product_id, product_name, quantity, unit_price, total_price) VALUES
('iiiiiiii-iiii-iiii-iiii-iiiiiiiiiiii', 'hhhhhhhh-hhhh-hhhh-hhhh-hhhhhhhhhhhh', '44444444-4444-4444-4444-444444444444', 'Low Stock Product', 3, 1.99, 5.97)
ON CONFLICT (id) DO NOTHING;

-- This should fail due to insufficient stock
SELECT 'Testing insufficient stock scenario (should fail):' as test_description;
SELECT update_product_quantities_after_payment(
    'hhhhhhhh-hhhh-hhhh-hhhh-hhhhhhhhhhhh'::UUID, 
    'pi_test_payment_intent_789'
) as function_result;

-- Clean up test data (optional - comment out if you want to keep test data)
-- DELETE FROM order_items WHERE order_id IN ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'hhhhhhhh-hhhh-hhhh-hhhh-hhhhhhhhhhhh');
-- DELETE FROM orders WHERE id IN ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'hhhhhhhh-hhhh-hhhh-hhhh-hhhhhhhhhhhh');
-- DELETE FROM products WHERE id IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333', '44444444-4444-4444-4444-444444444444');
-- DELETE FROM users WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
