-- Create orders table with comprehensive fields for webhook management
-- This migration sets up the complete order structure needed for the Stripe webhook functions

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create orders table
CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- User relationship
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Order details
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'preparing', 'out_for_delivery', 'delivered', 'cancelled', 'refunded', 'disputed')),
    raw_amount DECIMAL(10,2) NOT NULL,
    tip DECIMAL(10,2) NOT NULL DEFAULT 0,
    total_amount DECIMAL(10,2) NOT NULL,
    
    -- Delivery information
    delivery_address TEXT NOT NULL,
    delivery_instructions TEXT,
    is_campus_delivery BOOLEAN NOT NULL DEFAULT false,
    estimated_delivery_time TIMESTAMP WITH TIME ZONE,
    actual_delivery_time TIMESTAMP WITH TIME ZONE,
    
    -- Payment information
    payment_intent_id TEXT UNIQUE,
    payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'processing', 'succeeded', 'failed', 'cancelled', 'requires_action')),
    
    -- Refund information
    refund_amount DECIMAL(10,2) DEFAULT 0,
    refund_reason TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_payment_intent_id ON orders(payment_intent_id);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);
CREATE INDEX IF NOT EXISTS idx_orders_delivery_time ON orders(estimated_delivery_time, actual_delivery_time);

-- Create order items table for individual products in orders
CREATE TABLE IF NOT EXISTS order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL, -- Reference to products table
    product_name TEXT NOT NULL,
    product_price DECIMAL(10,2) NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    subtotal DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(order_id, product_id)
);

-- Create indexes for order items
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items(product_id);

-- Create order status history table for tracking status changes
CREATE TABLE IF NOT EXISTS order_status_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    status TEXT NOT NULL,
    previous_status TEXT,
    reason TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id)
);

-- Create indexes for order status history
CREATE INDEX IF NOT EXISTS idx_order_status_history_order_id ON order_status_history(order_id);
CREATE INDEX IF NOT EXISTS idx_order_status_history_status ON order_status_history(status);
CREATE INDEX IF NOT EXISTS idx_order_status_history_created_at ON order_status_history(created_at);

-- Create payment events table for tracking Stripe webhook events
CREATE TABLE IF NOT EXISTS payment_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
    stripe_event_id TEXT NOT NULL UNIQUE,
    stripe_event_type TEXT NOT NULL,
    stripe_object_id TEXT NOT NULL,
    stripe_object_type TEXT NOT NULL,
    amount DECIMAL(10,2),
    currency TEXT DEFAULT 'usd',
    status TEXT NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure we have either order_id or metadata with order_id
    CONSTRAINT check_order_reference CHECK (
        order_id IS NOT NULL OR 
        (metadata->>'order_id') IS NOT NULL
    )
);

-- Create indexes for payment events
CREATE INDEX IF NOT EXISTS idx_payment_events_order_id ON payment_events(order_id);
CREATE INDEX IF NOT EXISTS idx_payment_events_stripe_event_id ON payment_events(stripe_event_id);
CREATE INDEX IF NOT EXISTS idx_payment_events_stripe_event_type ON payment_events(stripe_event_type);
CREATE INDEX IF NOT EXISTS idx_payment_events_created_at ON payment_events(created_at);

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_orders_updated_at 
    BEFORE UPDATE ON orders 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Create function to log order status changes
CREATE OR REPLACE FUNCTION log_order_status_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Only log if status actually changed
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO order_status_history (
            order_id, 
            status, 
            previous_status, 
            reason,
            metadata
        ) VALUES (
            NEW.id,
            NEW.status,
            OLD.status,
            CASE 
                WHEN NEW.status = 'cancelled' THEN 'Order cancelled'
                WHEN NEW.status = 'refunded' THEN 'Order refunded'
                WHEN NEW.status = 'disputed' THEN 'Order disputed'
                WHEN NEW.status = 'confirmed' THEN 'Payment confirmed'
                WHEN NEW.status = 'delivered' THEN 'Order delivered'
                ELSE 'Status updated'
            END,
            jsonb_build_object(
                'payment_intent_id', NEW.payment_intent_id,
                'refund_amount', NEW.refund_amount,
                'refund_reason', NEW.refund_reason
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically log status changes
CREATE TRIGGER log_order_status_changes
    AFTER UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION log_order_status_change();

-- Create function to validate order amounts
CREATE OR REPLACE FUNCTION validate_order_amounts()
RETURNS TRIGGER AS $$
BEGIN
    -- Ensure total_amount equals raw_amount + tip
    IF NEW.total_amount != (NEW.raw_amount + NEW.tip) THEN
        RAISE EXCEPTION 'Total amount must equal raw amount plus tip';
    END IF;
    
    -- Ensure amounts are positive
    IF NEW.raw_amount < 0 OR NEW.tip < 0 OR NEW.total_amount < 0 THEN
        RAISE EXCEPTION 'All amounts must be positive';
    END IF;
    
    -- Ensure refund amount doesn't exceed total amount
    IF NEW.refund_amount > NEW.total_amount THEN
        RAISE EXCEPTION 'Refund amount cannot exceed total amount';
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to validate order amounts
CREATE TRIGGER validate_order_amounts_trigger
    BEFORE INSERT OR UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION validate_order_amounts();

-- Create RLS (Row Level Security) policies
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_events ENABLE ROW LEVEL SECURITY;

-- Policy for orders: users can only see their own orders
CREATE POLICY "Users can view own orders" ON orders
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own orders" ON orders
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own orders" ON orders
    FOR UPDATE USING (auth.uid() = user_id);

-- Policy for order items: users can only see items from their own orders
CREATE POLICY "Users can view own order items" ON order_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM orders 
            WHERE orders.id = order_items.order_id 
            AND orders.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert own order items" ON order_items
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM orders 
            WHERE orders.id = order_items.order_id 
            AND orders.user_id = auth.uid()
        )
    );

-- Policy for order status history: users can only see history from their own orders
CREATE POLICY "Users can view own order status history" ON order_status_history
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM orders 
            WHERE orders.id = order_status_history.order_id 
            AND orders.user_id = auth.uid()
        )
    );

-- Policy for payment events: users can only see events from their own orders
CREATE POLICY "Users can view own payment events" ON payment_events
    FOR SELECT USING (
        order_id IS NULL OR
        EXISTS (
            SELECT 1 FROM orders 
            WHERE orders.id = payment_events.order_id 
            AND orders.user_id = auth.uid()
        )
    );

-- Allow service role to perform all operations (for webhook functions)
CREATE POLICY "Service role can perform all operations" ON orders
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can perform all operations" ON order_items
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can perform all operations" ON order_status_history
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can perform all operations" ON payment_events
    FOR ALL USING (auth.role() = 'service_role');

-- Insert initial order statuses for reference
INSERT INTO order_status_history (order_id, status, reason, metadata) 
SELECT 
    '00000000-0000-0000-0000-000000000000'::UUID,
    status,
    'Initial status reference',
    '{}'::jsonb
FROM unnest(ARRAY['pending', 'confirmed', 'preparing', 'out_for_delivery', 'delivered', 'cancelled', 'refunded', 'disputed']) AS status
ON CONFLICT DO NOTHING;

-- Create view for order summary with latest status
CREATE OR REPLACE VIEW order_summary AS
SELECT 
    o.id,
    o.user_id,
    o.status,
    o.raw_amount,
    o.tip,
    o.total_amount,
    o.delivery_address,
    o.is_campus_delivery,
    o.estimated_delivery_time,
    o.actual_delivery_time,
    o.payment_intent_id,
    o.payment_status,
    o.refund_amount,
    o.refund_reason,
    o.created_at,
    o.updated_at,
    -- Get latest status change reason
    (SELECT reason FROM order_status_history 
     WHERE order_id = o.id 
     ORDER BY created_at DESC 
     LIMIT 1) as latest_status_reason,
    -- Count items in order
    (SELECT COUNT(*) FROM order_items WHERE order_id = o.id) as item_count
FROM orders o;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;

-- Grant permissions on the view
GRANT SELECT ON order_summary TO anon, authenticated, service_role;

-- Create function to get order with items
CREATE OR REPLACE FUNCTION get_order_with_items(order_uuid UUID)
RETURNS TABLE (
    order_data JSONB,
    items_data JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        to_jsonb(o.*) as order_data,
        COALESCE(
            (SELECT jsonb_agg(to_jsonb(oi.*)) 
             FROM order_items oi 
             WHERE oi.order_id = o.id), 
            '[]'::jsonb
        ) as items_data
    FROM orders o
    WHERE o.id = order_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION get_order_with_items(UUID) TO anon, authenticated, service_role;
