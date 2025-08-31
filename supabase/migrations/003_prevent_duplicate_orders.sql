-- Migration: Prevent Duplicate Orders
-- This migration adds constraints and indexes to prevent duplicate orders

-- Add unique constraint to prevent multiple pending orders with same user and items within a time window
-- This will be enforced at the application level, but we can add helpful indexes

-- Add index for faster duplicate checking
CREATE INDEX IF NOT EXISTS idx_orders_user_status_created 
ON orders(user_id, status, created_at);

-- Add index for faster order item lookups
CREATE INDEX IF NOT EXISTS idx_order_items_order_id 
ON order_items(order_id);

-- Add function to check for duplicate orders
CREATE OR REPLACE FUNCTION check_duplicate_order(
    p_user_id UUID,
    p_cart_items JSONB
) RETURNS BOOLEAN AS $$
DECLARE
    duplicate_count INTEGER;
BEGIN
    -- Check for pending orders within the last 30 minutes with same items
    SELECT COUNT(*) INTO duplicate_count
    FROM orders o
    WHERE o.user_id = p_user_id 
      AND o.status = 'pending'
      AND o.created_at > NOW() - INTERVAL '30 minutes'
      AND EXISTS (
          -- Check if order has the same items
          SELECT 1
          FROM order_items oi
          WHERE oi.order_id = o.id
          GROUP BY oi.order_id
          HAVING COUNT(*) = jsonb_array_length(p_cart_items)
          AND COUNT(*) = (
              SELECT COUNT(*)
              FROM jsonb_array_elements(p_cart_items) AS item
              WHERE item->>'product_id' IN (
                  SELECT oi2.product_id::text
                  FROM order_items oi2
                  WHERE oi2.order_id = o.id
              )
          )
      );
    
    RETURN duplicate_count > 0;
END;
$$ LANGUAGE plpgsql;

-- Add comment explaining the function
COMMENT ON FUNCTION check_duplicate_order IS 'Checks if a user has a duplicate pending order with the same cart items within the last 30 minutes';

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION check_duplicate_order TO authenticated;
