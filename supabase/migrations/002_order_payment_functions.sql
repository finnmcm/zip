-- Functions to update order status and adjust product quantities atomically by payment_intent_id

-- Ensure helpful index exists
CREATE INDEX IF NOT EXISTS idx_orders_payment_intent_id ON orders(payment_intent_id);

-- Update order status and, on successful confirmation, decrement product quantities
-- No logging to auxiliary tables; only mutate orders, products
CREATE OR REPLACE FUNCTION update_order_status_and_inventory(
    p_payment_intent_id TEXT,
    p_new_status TEXT
) RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_order_id UUID;
    v_prev_status TEXT;
    v_quantities_updated BOOLEAN := FALSE;
BEGIN
    IF p_payment_intent_id IS NULL OR length(trim(p_payment_intent_id)) = 0 THEN
        RETURN json_build_object('ok', FALSE, 'error', 'missing_payment_intent_id');
    END IF;

    -- Lock the order row for update to avoid race conditions
    SELECT id, status::text INTO v_order_id, v_prev_status
    FROM orders
    WHERE payment_intent_id = p_payment_intent_id
    FOR UPDATE;

    IF v_order_id IS NULL THEN
        -- Nothing to do
        RETURN json_build_object('ok', TRUE, 'skipped', TRUE, 'reason', 'order_not_found');
    END IF;

    -- Only adjust inventory on first transition to a successful payment state
    IF lower(p_new_status) = 'in_queue' AND lower(coalesce(v_prev_status, '')) <> 'in_queue' THEN
        -- Decrement product quantities based on order items; clamp at zero
        -- Support schema where stock_quantity/in_stock are used
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'products' AND column_name = 'stock_quantity'
        ) THEN
            UPDATE products p
            SET stock_quantity = GREATEST(p.stock_quantity - oi.quantity, 0),
                in_stock = CASE WHEN GREATEST(p.stock_quantity - oi.quantity, 0) > 0 THEN TRUE ELSE FALSE END
            FROM order_items oi
            WHERE oi.order_id = v_order_id
              AND oi.product_id = p.id;
        ELSE
            UPDATE products p
            SET quantity = GREATEST(p.quantity - oi.quantity, 0)
            FROM order_items oi
            WHERE oi.order_id = v_order_id
              AND oi.product_id = p.id;
        END IF;

        v_quantities_updated := TRUE;
    END IF;

    -- Update order status (avoid write if status unchanged)
    UPDATE orders
    SET status = p_new_status::order_status,
        updated_at = NOW()
    WHERE id = v_order_id AND status IS DISTINCT FROM p_new_status::order_status;

    RETURN json_build_object(
        'ok', TRUE,
        'order_id', v_order_id,
        'previous_status', v_prev_status,
        'new_status', p_new_status,
        'quantities_updated', v_quantities_updated
    );
END;
$$;

-- Grant execute to service role and authenticated callers as needed
DO $$
BEGIN
  GRANT EXECUTE ON FUNCTION update_order_status_and_inventory(TEXT, TEXT) TO service_role;
  GRANT EXECUTE ON FUNCTION update_order_status_and_inventory(TEXT, TEXT) TO authenticated;
EXCEPTION WHEN undefined_object THEN
  -- roles may not exist in local env; ignore
  NULL;
END $$;

-- Alternative function: update by order_id with optional payment_intent_id assignment
CREATE OR REPLACE FUNCTION update_order_status_and_inventory_by_order_id(
    p_order_id UUID,
    p_new_status TEXT,
    p_payment_intent_id TEXT DEFAULT NULL
) RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_prev_status TEXT;
    v_quantities_updated BOOLEAN := FALSE;
BEGIN
    IF p_order_id IS NULL THEN
        RETURN json_build_object('ok', FALSE, 'error', 'missing_order_id');
    END IF;

    -- Lock order
    SELECT status::text INTO v_prev_status
    FROM orders
    WHERE id = p_order_id
    FOR UPDATE;

    IF v_prev_status IS NULL THEN
        RETURN json_build_object('ok', TRUE, 'skipped', TRUE, 'reason', 'order_not_found');
    END IF;

    -- If provided, set payment_intent_id when not already set
    IF p_payment_intent_id IS NOT NULL THEN
        UPDATE orders
        SET payment_intent_id = COALESCE(payment_intent_id, p_payment_intent_id)
        WHERE id = p_order_id;
    END IF;

    -- Adjust inventory on first confirm
    IF lower(p_new_status) = 'in_queue' AND lower(coalesce(v_prev_status, '')) <> 'in_queue' THEN
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'products' AND column_name = 'stock_quantity'
        ) THEN
            UPDATE products p
            SET stock_quantity = GREATEST(p.stock_quantity - oi.quantity, 0),
                in_stock = CASE WHEN GREATEST(p.stock_quantity - oi.quantity, 0) > 0 THEN TRUE ELSE FALSE END
            FROM order_items oi
            WHERE oi.order_id = p_order_id
              AND oi.product_id = p.id;
        ELSE
            UPDATE products p
            SET quantity = GREATEST(p.quantity - oi.quantity, 0)
            FROM order_items oi
            WHERE oi.order_id = p_order_id
              AND oi.product_id = p.id;
        END IF;
        v_quantities_updated := TRUE;
    END IF;

    -- Update status
    UPDATE orders
    SET status = p_new_status::order_status,
        updated_at = NOW()
    WHERE id = p_order_id AND status IS DISTINCT FROM p_new_status::order_status;

    RETURN json_build_object(
        'ok', TRUE,
        'order_id', p_order_id,
        'previous_status', v_prev_status,
        'new_status', p_new_status,
        'quantities_updated', v_quantities_updated
    );
END;
$$;

DO $$
BEGIN
  GRANT EXECUTE ON FUNCTION update_order_status_and_inventory_by_order_id(UUID, TEXT, TEXT) TO service_role;
  GRANT EXECUTE ON FUNCTION update_order_status_and_inventory_by_order_id(UUID, TEXT, TEXT) TO authenticated;
EXCEPTION WHEN undefined_object THEN
  NULL;
END $$;


