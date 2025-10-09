-- Quick fix for UUID type mismatch error
-- Run this to update the calculate_order_statistics function without re-running the entire migration

CREATE OR REPLACE FUNCTION calculate_order_statistics(
    p_period_type time_period_type,
    p_period_start TIMESTAMPTZ,
    p_period_end TIMESTAMPTZ
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_total_orders INTEGER;
    v_completed_orders INTEGER;
    v_cancelled_orders INTEGER;
    v_disputed_orders INTEGER;
    v_total_revenue NUMERIC(10, 2);
    v_total_tips NUMERIC(10, 2);
    v_unique_customers INTEGER;
    v_new_customers INTEGER;
    v_total_items INTEGER;
    v_campus_deliveries INTEGER;
    v_off_campus_deliveries INTEGER;
    v_most_popular_product UUID;
    v_most_popular_quantity INTEGER;
    v_avg_prep_time NUMERIC(10, 2);
    v_avg_delivery_time NUMERIC(10, 2);
    v_on_time_percentage NUMERIC(5, 2);
BEGIN
    -- Calculate total orders
    SELECT COUNT(*) INTO v_total_orders
    FROM orders
    WHERE created_at >= p_period_start AND created_at < p_period_end;
    
    -- Calculate orders by status
    SELECT 
        COUNT(*) FILTER (WHERE status = 'delivered'),
        COUNT(*) FILTER (WHERE status = 'cancelled'),
        COUNT(*) FILTER (WHERE status = 'disputed')
    INTO v_completed_orders, v_cancelled_orders, v_disputed_orders
    FROM orders
    WHERE created_at >= p_period_start AND created_at < p_period_end;
    
    -- Calculate revenue metrics (only for non-cancelled orders)
    SELECT 
        COALESCE(SUM(total_amount), 0),
        COALESCE(SUM(tip), 0)
    INTO v_total_revenue, v_total_tips
    FROM orders
    WHERE created_at >= p_period_start 
        AND created_at < p_period_end
        AND status IN ('delivered', 'in_progress', 'in_queue');
    
    -- Calculate unique customers
    -- Note: user_id in orders table is text, not UUID
    SELECT COUNT(DISTINCT user_id::text) INTO v_unique_customers
    FROM orders
    WHERE created_at >= p_period_start AND created_at < p_period_end;
    
    -- Calculate new customers (first order in this period)
    SELECT COUNT(DISTINCT user_id::text) INTO v_new_customers
    FROM orders o1
    WHERE o1.created_at >= p_period_start 
        AND o1.created_at < p_period_end
        AND NOT EXISTS (
            SELECT 1 FROM orders o2 
            WHERE o2.user_id::text = o1.user_id::text 
            AND o2.created_at < p_period_start
        );
    
    -- Calculate total items sold (from cart_items table)
    -- Cast IDs to ensure type compatibility
    SELECT COALESCE(SUM(ci.quantity), 0) INTO v_total_items
    FROM cart_items ci
    INNER JOIN orders o ON o.id::text = ci.order_id::text
    WHERE o.created_at >= p_period_start AND o.created_at < p_period_end
        AND o.status IN ('delivered', 'in_progress', 'in_queue');
    
    -- Calculate campus vs off-campus deliveries
    SELECT 
        COUNT(*) FILTER (WHERE is_campus_delivery = true),
        COUNT(*) FILTER (WHERE is_campus_delivery = false)
    INTO v_campus_deliveries, v_off_campus_deliveries
    FROM orders
    WHERE created_at >= p_period_start AND created_at < p_period_end;
    
    -- Find most popular product
    -- Cast IDs to ensure type compatibility
    SELECT ci.product_id, SUM(ci.quantity)
    INTO v_most_popular_product, v_most_popular_quantity
    FROM cart_items ci
    INNER JOIN orders o ON o.id::text = ci.order_id::text
    WHERE o.created_at >= p_period_start AND o.created_at < p_period_end
        AND o.status IN ('delivered', 'in_progress', 'in_queue')
    GROUP BY ci.product_id
    ORDER BY SUM(ci.quantity) DESC
    LIMIT 1;
    
    -- Calculate average preparation time (time from created to updated for delivered orders)
    -- This represents the time from order creation to order completion/delivery
    SELECT 
        COALESCE(AVG(EXTRACT(EPOCH FROM (updated_at - created_at)) / 60), 0)
    INTO v_avg_prep_time
    FROM orders
    WHERE created_at >= p_period_start 
        AND created_at < p_period_end
        AND status = 'delivered';
    
    -- Set delivery time same as prep time since we don't have separate delivery tracking
    v_avg_delivery_time := v_avg_prep_time;
    
    -- Set on-time percentage to NULL since we don't have estimated/actual delivery times
    -- This can be added later when those fields are added to the orders table
    v_on_time_percentage := NULL;
    
    -- Insert or update statistics
    INSERT INTO order_statistics (
        period_type,
        period_start,
        period_end,
        total_orders,
        completed_orders,
        cancelled_orders,
        disputed_orders,
        total_revenue,
        total_tips,
        average_order_value,
        average_tip_amount,
        unique_customers,
        new_customers,
        returning_customers,
        total_items_sold,
        average_items_per_order,
        most_popular_product_id,
        most_popular_product_quantity,
        average_preparation_time_minutes,
        average_delivery_time_minutes,
        on_time_delivery_percentage,
        campus_delivery_count,
        off_campus_delivery_count
    ) VALUES (
        p_period_type,
        p_period_start,
        p_period_end,
        v_total_orders,
        v_completed_orders,
        v_cancelled_orders,
        v_disputed_orders,
        v_total_revenue,
        v_total_tips,
        CASE WHEN v_completed_orders > 0 THEN v_total_revenue / v_completed_orders ELSE 0 END,
        CASE WHEN v_completed_orders > 0 THEN v_total_tips / v_completed_orders ELSE 0 END,
        v_unique_customers,
        v_new_customers,
        v_unique_customers - v_new_customers,
        v_total_items,
        CASE WHEN v_total_orders > 0 THEN v_total_items::NUMERIC / v_total_orders ELSE 0 END,
        v_most_popular_product,
        v_most_popular_quantity,
        v_avg_prep_time,
        v_avg_delivery_time,
        v_on_time_percentage,
        v_campus_deliveries,
        v_off_campus_deliveries
    )
    ON CONFLICT (period_type, period_start)
    DO UPDATE SET
        period_end = EXCLUDED.period_end,
        total_orders = EXCLUDED.total_orders,
        completed_orders = EXCLUDED.completed_orders,
        cancelled_orders = EXCLUDED.cancelled_orders,
        disputed_orders = EXCLUDED.disputed_orders,
        total_revenue = EXCLUDED.total_revenue,
        total_tips = EXCLUDED.total_tips,
        average_order_value = EXCLUDED.average_order_value,
        average_tip_amount = EXCLUDED.average_tip_amount,
        unique_customers = EXCLUDED.unique_customers,
        new_customers = EXCLUDED.new_customers,
        returning_customers = EXCLUDED.returning_customers,
        total_items_sold = EXCLUDED.total_items_sold,
        average_items_per_order = EXCLUDED.average_items_per_order,
        most_popular_product_id = EXCLUDED.most_popular_product_id,
        most_popular_product_quantity = EXCLUDED.most_popular_product_quantity,
        average_preparation_time_minutes = EXCLUDED.average_preparation_time_minutes,
        average_delivery_time_minutes = EXCLUDED.average_delivery_time_minutes,
        on_time_delivery_percentage = EXCLUDED.on_time_delivery_percentage,
        campus_delivery_count = EXCLUDED.campus_delivery_count,
        off_campus_delivery_count = EXCLUDED.off_campus_delivery_count,
        updated_at = NOW();
END;
$$;

-- Regenerate statistics to apply the fix
SELECT generate_statistics_for_range(
    (SELECT MIN(created_at) FROM orders),
    NOW()
);

