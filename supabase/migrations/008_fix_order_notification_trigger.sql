-- Migration: Fix Order Status Notification Trigger
-- Fixes issues with notifications not working when zippers update order status
-- Uses Supabase Vault for secure configuration storage

-- First, drop the existing trigger and function
DROP TRIGGER IF EXISTS order_status_notification_trigger ON orders;
DROP FUNCTION IF EXISTS send_order_status_notification();

-- Create a configuration table to store the Supabase URL and service key securely
-- This table is managed by service_role only
CREATE TABLE IF NOT EXISTS notification_config (
    id INT PRIMARY KEY DEFAULT 1,
    supabase_url TEXT NOT NULL,
    service_key_encrypted TEXT NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT single_row CHECK (id = 1)
);

-- Enable RLS on the config table
ALTER TABLE notification_config ENABLE ROW LEVEL SECURITY;

-- Only service_role can read the config
CREATE POLICY "Service role can read config" ON notification_config
    FOR SELECT TO service_role USING (true);

-- Only service_role can insert/update the config
CREATE POLICY "Service role can manage config" ON notification_config
    FOR ALL TO service_role USING (true);

-- Recreate the function with proper permissions and RLS bypassing
CREATE OR REPLACE FUNCTION send_order_status_notification()
RETURNS TRIGGER 
SECURITY DEFINER  -- Run with creator's privileges to bypass RLS on fcm_tokens
SET search_path = public  -- Explicitly set search path
LANGUAGE plpgsql
AS $$
DECLARE
    user_fcm_tokens TEXT[];
    notification_title TEXT;
    notification_body TEXT;
    order_data JSONB;
    zip_push_url TEXT;
    request_payload JSONB;
    request_id BIGINT;
    config_record RECORD;
BEGIN
    -- Only trigger for specific status changes
    IF NEW.status NOT IN ('in_progress', 'delivered') THEN
        RETURN NEW;
    END IF;
    
    -- Skip if status didn't actually change
    IF OLD.status IS NOT NULL AND OLD.status = NEW.status THEN
        RETURN NEW;
    END IF;
    
    RAISE LOG 'Order status notification trigger fired for order %: % -> %', NEW.id, OLD.status, NEW.status;
    
    -- Get FCM tokens for the user (bypass RLS by using SECURITY DEFINER)
    SELECT ARRAY_AGG(token) INTO user_fcm_tokens
    FROM fcm_tokens 
    WHERE user_id = NEW.user_id 
    AND updated_at > NOW() - INTERVAL '7 days'; -- Only active tokens
    
    -- If no FCM tokens found, log and return
    IF user_fcm_tokens IS NULL OR array_length(user_fcm_tokens, 1) = 0 THEN
        RAISE LOG 'No active FCM tokens found for user % (order %)', NEW.user_id, NEW.id;
        RETURN NEW;
    END IF;
    
    RAISE LOG 'Found % FCM tokens for user %', array_length(user_fcm_tokens, 1), NEW.user_id;
    
    -- Set notification content based on status
    CASE NEW.status
        WHEN 'in_progress' THEN
            notification_title := '🍕 Your Order is Being Prepared';
            notification_body := 'Your Zip order #' || substring(NEW.id::text, 1, 8) || ' is now being prepared! We''ll notify you when it''s ready for pickup.';
        WHEN 'delivered' THEN
            notification_title := '✅ Order Delivered!';
            notification_body := 'Your Zip order #' || substring(NEW.id::text, 1, 8) || ' has been delivered! Enjoy your order and thank you for choosing Zip!';
        ELSE
            -- This shouldn't happen due to the IF condition above, but just in case
            RAISE LOG 'Unexpected status for notification: %', NEW.status;
            RETURN NEW;
    END CASE;
    
    -- Prepare notification data payload
    -- FCM requires all data values to be strings
    order_data := jsonb_build_object(
        'order_id', NEW.id::text,
        'status', NEW.status,
        'type', 'order_status_update',
        'timestamp', NOW()::text,
        'order_total', NEW.total_amount::text
    );
    
    -- Get configuration from the notification_config table
    BEGIN
        SELECT * INTO config_record FROM notification_config WHERE id = 1;
        
        IF NOT FOUND THEN
            RAISE LOG 'Notification config not found. Please run setup script. Cannot send notification for order %', NEW.id;
            RETURN NEW;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        RAISE LOG 'Error reading notification config: %. Cannot send notification for order %', SQLERRM, NEW.id;
        RETURN NEW;
    END;
    
    -- Construct the zip-push function URL
    zip_push_url := config_record.supabase_url || '/functions/v1/push';
    
    -- Prepare the request payload for the zip-push edge function
    request_payload := jsonb_build_object(
        'fcm_tokens', user_fcm_tokens,
        'title', notification_title,
        'body', notification_body,
        'data', order_data,
        'priority', 'high',
        'sound', 'default',
        'badge', 1
    );
    
    RAISE LOG 'Sending push notification for order % to % devices', NEW.id, array_length(user_fcm_tokens, 1);
    RAISE LOG 'Notification URL: %', zip_push_url;
    
    -- Make HTTP request to zip-push edge function using pg_net
    BEGIN
        -- Use pg_net for async HTTP requests (built into Supabase)
        SELECT net.http_post(
            url := zip_push_url,
            headers := jsonb_build_object(
                'Authorization', 'Bearer ' || config_record.service_key_encrypted,
                'Content-Type', 'application/json'
            ),
            body := request_payload
        ) INTO request_id;
        
        RAISE LOG 'Push notification request submitted for order % (request_id: %)', NEW.id, request_id;
        
    EXCEPTION WHEN OTHERS THEN
        -- Log the error but don't fail the transaction
        RAISE LOG 'Error submitting push notification for order %: % (SQLSTATE: %)', NEW.id, SQLERRM, SQLSTATE;
    END;
    
    RETURN NEW;
END;
$$;

-- Recreate the trigger on the orders table
CREATE TRIGGER order_status_notification_trigger
    AFTER UPDATE OF status ON orders
    FOR EACH ROW
    EXECUTE FUNCTION send_order_status_notification();

-- Grant necessary permissions to the function
-- This allows the function to be executed by any authenticated user
GRANT EXECUTE ON FUNCTION send_order_status_notification() TO authenticated;
GRANT EXECUTE ON FUNCTION send_order_status_notification() TO service_role;
GRANT EXECUTE ON FUNCTION send_order_status_notification() TO postgres;

-- Grant permissions for the function to access fcm_tokens table
-- This is critical - the function needs to read from fcm_tokens regardless of RLS
GRANT SELECT ON fcm_tokens TO postgres;
GRANT SELECT ON notification_config TO postgres;

-- Grant permissions on the config table
GRANT ALL ON notification_config TO service_role;
GRANT SELECT ON notification_config TO postgres;

-- Ensure pg_net extension is enabled (it should be by default in Supabase)
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Add helpful comments
COMMENT ON FUNCTION send_order_status_notification() IS 'Automatically sends push notifications when order status changes to in_progress or delivered. Runs with elevated privileges to bypass RLS.';
COMMENT ON TRIGGER order_status_notification_trigger ON orders IS 'Triggers push notifications on order status updates. Works regardless of who updates the order.';
COMMENT ON TABLE notification_config IS 'Stores Supabase URL and service key for notification triggers. Managed by service_role only.';

-- ================================================================
-- IMPORTANT: Configuration Setup Required
-- ================================================================
-- After running this migration, you MUST configure the notification settings.
-- Run the setup_notification_config.sql script to insert your configuration.
-- 
-- You'll need:
-- - Your Supabase Project URL (from Dashboard → Settings → API → Project URL)
-- - Your Service Role Key (from Dashboard → Settings → API → service_role key)
-- ================================================================

