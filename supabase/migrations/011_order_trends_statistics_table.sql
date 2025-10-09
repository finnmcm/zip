-- Migration: Create order trends and statistics tracking table
-- Date: 2025-10-09
-- Description: Creates a table and materialized views for tracking order trends,
--              business metrics, and performance statistics over time periods

-- Drop existing objects if they exist (for clean migration)
DROP TRIGGER IF EXISTS order_statistics_update_trigger ON orders;
DROP FUNCTION IF EXISTS update_order_statistics_trigger();
DROP FUNCTION IF EXISTS generate_statistics_for_range(TIMESTAMPTZ, TIMESTAMPTZ);
DROP FUNCTION IF EXISTS calculate_order_statistics(time_period_type, TIMESTAMPTZ, TIMESTAMPTZ);
DROP VIEW IF EXISTS recent_order_statistics;
DROP TABLE IF EXISTS order_statistics;
DROP TYPE IF EXISTS time_period_type;

-- Create enum for time period types
CREATE TYPE time_period_type AS ENUM ('hourly', 'daily', 'weekly', 'monthly', 'yearly');

-- Main order statistics table
CREATE TABLE order_statistics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Time period information
    period_type time_period_type NOT NULL,
    period_start TIMESTAMPTZ NOT NULL,
    period_end TIMESTAMPTZ NOT NULL,
    
    -- Order metrics
    total_orders INTEGER NOT NULL DEFAULT 0,
    completed_orders INTEGER NOT NULL DEFAULT 0,
    cancelled_orders INTEGER NOT NULL DEFAULT 0,
    disputed_orders INTEGER NOT NULL DEFAULT 0,
    
    -- Revenue metrics (stored as numeric for precision)
    total_revenue NUMERIC(10, 2) NOT NULL DEFAULT 0,
    total_tips NUMERIC(10, 2) NOT NULL DEFAULT 0,
    average_order_value NUMERIC(10, 2) NOT NULL DEFAULT 0,
    average_tip_amount NUMERIC(10, 2) NOT NULL DEFAULT 0,
    
    -- User metrics
    unique_customers INTEGER NOT NULL DEFAULT 0,
    new_customers INTEGER NOT NULL DEFAULT 0,
    returning_customers INTEGER NOT NULL DEFAULT 0,
    
    -- Product metrics
    total_items_sold INTEGER NOT NULL DEFAULT 0,
    average_items_per_order NUMERIC(10, 2) NOT NULL DEFAULT 0,
    most_popular_product_id UUID,
    most_popular_product_quantity INTEGER DEFAULT 0,
    
    -- Performance metrics
    average_preparation_time_minutes NUMERIC(10, 2),
    average_delivery_time_minutes NUMERIC(10, 2),
    on_time_delivery_percentage NUMERIC(5, 2),
    
    -- Delivery metrics
    campus_delivery_count INTEGER NOT NULL DEFAULT 0,
    off_campus_delivery_count INTEGER NOT NULL DEFAULT 0,
    
    -- Peak time identification
    peak_hour INTEGER, -- 0-23 for hour of day with most orders
    peak_day_of_week INTEGER, -- 0-6 for day of week with most orders (0=Sunday)
    
    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Ensure unique periods
    CONSTRAINT unique_period UNIQUE (period_type, period_start)
);

-- Create indexes for efficient querying
CREATE INDEX idx_order_stats_period_type ON order_statistics(period_type);
CREATE INDEX idx_order_stats_period_start ON order_statistics(period_start);
CREATE INDEX idx_order_stats_period_end ON order_statistics(period_end);
CREATE INDEX idx_order_stats_created_at ON order_statistics(created_at);

-- Enable RLS
ALTER TABLE order_statistics ENABLE ROW LEVEL SECURITY;

-- Policy: Only admins can read statistics
CREATE POLICY "Allow admins to read order statistics"
ON order_statistics
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid()::text 
        AND users.role = 'admin'::user_role
    )
);

-- Policy: Only admins can insert/update statistics
CREATE POLICY "Allow admins to insert order statistics"
ON order_statistics
FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid()::text 
        AND users.role = 'admin'::user_role
    )
);

CREATE POLICY "Allow admins to update order statistics"
ON order_statistics
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid()::text 
        AND users.role = 'admin'::user_role
    )
);

-- Function to calculate statistics for a given time period
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

-- Function to automatically update statistics when orders change
CREATE OR REPLACE FUNCTION update_order_statistics_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Update daily statistics for the order's creation date
    PERFORM calculate_order_statistics(
        'daily'::time_period_type,
        DATE_TRUNC('day', COALESCE(NEW.created_at, OLD.created_at)),
        DATE_TRUNC('day', COALESCE(NEW.created_at, OLD.created_at)) + INTERVAL '1 day'
    );
    
    RETURN NEW;
END;
$$;

-- Create trigger for automatic statistics updates
CREATE TRIGGER order_statistics_update_trigger
AFTER INSERT OR UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION update_order_statistics_trigger();

-- Function to generate statistics for a date range
CREATE OR REPLACE FUNCTION generate_statistics_for_range(
    p_start_date TIMESTAMPTZ,
    p_end_date TIMESTAMPTZ
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_current_date TIMESTAMPTZ;
BEGIN
    -- Generate daily statistics
    v_current_date := DATE_TRUNC('day', p_start_date);
    WHILE v_current_date < p_end_date LOOP
        PERFORM calculate_order_statistics(
            'daily'::time_period_type,
            v_current_date,
            v_current_date + INTERVAL '1 day'
        );
        v_current_date := v_current_date + INTERVAL '1 day';
    END LOOP;
    
    -- Generate weekly statistics
    v_current_date := DATE_TRUNC('week', p_start_date);
    WHILE v_current_date < p_end_date LOOP
        PERFORM calculate_order_statistics(
            'weekly'::time_period_type,
            v_current_date,
            v_current_date + INTERVAL '1 week'
        );
        v_current_date := v_current_date + INTERVAL '1 week';
    END LOOP;
    
    -- Generate monthly statistics
    v_current_date := DATE_TRUNC('month', p_start_date);
    WHILE v_current_date < p_end_date LOOP
        PERFORM calculate_order_statistics(
            'monthly'::time_period_type,
            v_current_date,
            v_current_date + INTERVAL '1 month'
        );
        v_current_date := v_current_date + INTERVAL '1 month';
    END LOOP;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION calculate_order_statistics TO authenticated;
GRANT EXECUTE ON FUNCTION generate_statistics_for_range TO authenticated;

-- Add helpful comments
COMMENT ON TABLE order_statistics IS 'Tracks aggregated order trends and business metrics over various time periods. Used for analytics and reporting.';
COMMENT ON FUNCTION calculate_order_statistics IS 'Calculates and stores order statistics for a specific time period. Automatically called by triggers but can also be called manually to backfill data.';
COMMENT ON FUNCTION generate_statistics_for_range IS 'Generates statistics for all time periods (daily, weekly, monthly) within a date range. Useful for backfilling historical data.';
COMMENT ON TYPE time_period_type IS 'Defines the granularity of time periods for order statistics aggregation.';

-- Create a view for easy access to recent statistics
CREATE OR REPLACE VIEW recent_order_statistics AS
SELECT 
    period_type,
    period_start,
    period_end,
    total_orders,
    completed_orders,
    cancelled_orders,
    total_revenue,
    average_order_value,
    unique_customers,
    new_customers,
    average_delivery_time_minutes
FROM order_statistics
WHERE period_start >= NOW() - INTERVAL '30 days'
ORDER BY period_start DESC;

-- Grant access to the view
GRANT SELECT ON recent_order_statistics TO authenticated;

COMMENT ON VIEW recent_order_statistics IS 'Simplified view of order statistics from the last 30 days for quick access to recent trends.';

