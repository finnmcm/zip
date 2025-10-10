-- Migration to restore product inventory when orders are cancelled
-- This ensures that when an order status changes to 'cancelled', 
-- the product quantities are added back to inventory

-- Create function to restore product quantities from a cancelled order
CREATE OR REPLACE FUNCTION restore_inventory_on_cancel()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_order_was_confirmed BOOLEAN := FALSE;
BEGIN
    -- Only restore inventory if:
    -- 1. The status changed to 'cancelled'
    -- 2. The order was previously in a confirmed state (in_queue, in_progress, or delivered)
    --    This prevents restoring inventory for orders that were cancelled before payment
    
    IF NEW.status = 'cancelled' AND OLD.status IS DISTINCT FROM 'cancelled' THEN
        -- Check if the order was previously confirmed (had inventory deducted)
        v_order_was_confirmed := OLD.status IN ('in_queue', 'in_progress', 'delivered');
        
        IF v_order_was_confirmed THEN
            -- Restore quantities based on order items
            UPDATE products p
            SET quantity = p.quantity + oi.quantity
            FROM order_items oi
            WHERE oi.order_id = NEW.id
              AND oi.product_id = p.id;
            
            -- Log the restoration (optional - for debugging)
            RAISE NOTICE 'Restored inventory for cancelled order %', NEW.id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Create trigger to fire when order status is updated
DROP TRIGGER IF EXISTS trigger_restore_inventory_on_cancel ON orders;

CREATE TRIGGER trigger_restore_inventory_on_cancel
    AFTER UPDATE OF status ON orders
    FOR EACH ROW
    WHEN (NEW.status = 'cancelled' AND OLD.status IS DISTINCT FROM 'cancelled')
    EXECUTE FUNCTION restore_inventory_on_cancel();

-- Grant necessary permissions
DO $$
BEGIN
    GRANT EXECUTE ON FUNCTION restore_inventory_on_cancel() TO service_role;
    GRANT EXECUTE ON FUNCTION restore_inventory_on_cancel() TO authenticated;
EXCEPTION WHEN undefined_object THEN
    -- Roles may not exist in local env; ignore
    NULL;
END $$;

-- Add helpful comment
COMMENT ON FUNCTION restore_inventory_on_cancel() IS 
'Automatically restores product inventory quantities when an order is cancelled. 
Only restores inventory for orders that were previously confirmed (in_queue, in_progress, or delivered).';

COMMENT ON TRIGGER trigger_restore_inventory_on_cancel ON orders IS 
'Fires when an order status changes to cancelled to restore product quantities back to inventory.';

