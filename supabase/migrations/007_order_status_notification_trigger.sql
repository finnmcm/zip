-- Migration: Order Status Notification Trigger
-- Creates a trigger that sends push notifications when order status changes to 'in_progress' or 'delivered'

-- Create function to send push notification when order status changes
CREATE OR REPLACE FUNCTION send_order_status_notification()
RETURNS TRIGGER AS $$
DECLARE
    user_fcm_tokens TEXT[];
    notification_title TEXT;
    notification_body TEXT;
    order_data JSON;
    zip_push_url TEXT;
    supabase_url TEXT;
    supabase_service_key TEXT;
    request_payload JSON;
    request_id UUID;
BEGIN
    -- Only trigger for specific status changes
    IF NEW.status NOT IN ('in_progress', 'delivered') THEN
        RETURN NEW;
    END IF;
    
    -- Skip if status didn't actually change
    IF OLD.status = NEW.status THEN
        RETURN NEW;
    END IF;
    
    RAISE LOG 'Order status notification trigger fired for order %: % -> %', NEW.id, OLD.status, NEW.status;
    
    -- Get FCM tokens for the user
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
    order_data := json_build_object(
        'order_id', NEW.id::text,
        'status', NEW.status,
        'type', 'order_status_update',
        'timestamp', NOW()::text,
        'order_total', NEW.total_amount
    );
    
    -- Get Supabase configuration
    supabase_url := current_setting('app.supabase_url', true);
    supabase_service_key := current_setting('app.supabase_service_key', true);
    
    -- Construct the zip-push function URL
    zip_push_url := supabase_url || '/functions/v1/zip-push';
    
    -- Prepare the request payload for the zip-push edge function
    request_payload := json_build_object(
        'fcm_tokens', user_fcm_tokens,
        'title', notification_title,
        'body', notification_body,
        'data', order_data,
        'priority', 'high',
        'sound', 'default',
        'badge', 1
    );
    
    RAISE LOG 'Sending push notification for order % to % devices', NEW.id, array_length(user_fcm_tokens, 1);
    RAISE LOG 'Notification payload: %', request_payload;
    
    -- Make HTTP request to zip-push edge function using pg_net
    BEGIN
        -- Use pg_net for async HTTP requests (built into Supabase)
        SELECT net.http_post(
            url := zip_push_url,
            headers := jsonb_build_object(
                'Authorization', 'Bearer ' || supabase_service_key,
                'Content-Type', 'application/json'
            ),
            body := request_payload::jsonb
        ) INTO request_id;
        
        RAISE LOG 'Push notification request submitted for order % (request_id: %)', NEW.id, request_id;
        
        -- Log the notification attempt (notifications table will be created by zip-push function)
        -- INSERT INTO notifications (...) -- Commented out until table exists
        
    EXCEPTION WHEN OTHERS THEN
        -- Log the error but don't fail the transaction
        RAISE LOG 'Error submitting push notification for order %: %', NEW.id, SQLERRM;
        
        -- Log error (notifications table will be created by zip-push function)
        -- INSERT INTO notifications (...) -- Commented out until table exists
    END;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger on the orders table
DROP TRIGGER IF EXISTS order_status_notification_trigger ON orders;
CREATE TRIGGER order_status_notification_trigger
    AFTER UPDATE OF status ON orders
    FOR EACH ROW
    EXECUTE FUNCTION send_order_status_notification();

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION send_order_status_notification() TO service_role;

-- Add configuration settings for the trigger (these should be set via Supabase dashboard or CLI)
-- Example: ALTER DATABASE postgres SET app.supabase_url = 'https://your-project.supabase.co';
-- Example: ALTER DATABASE postgres SET app.supabase_service_key = 'your-service-role-key';

-- Create a function to test the notification system
CREATE OR REPLACE FUNCTION test_order_status_notification(p_order_id UUID)
RETURNS JSON AS $$
DECLARE
    order_record RECORD;
    result JSON;
BEGIN
    -- Get the order details
    SELECT * INTO order_record
    FROM orders 
    WHERE id = p_order_id;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Order not found',
            'order_id', p_order_id
        );
    END IF;
    
    -- Manually trigger the notification function
    -- We'll simulate an update by calling the function directly
    BEGIN
        PERFORM send_order_status_notification();
        result := json_build_object(
            'success', true,
            'message', 'Test notification triggered',
            'order_id', p_order_id,
            'user_id', order_record.user_id,
            'current_status', order_record.status
        );
    EXCEPTION WHEN OTHERS THEN
        result := json_build_object(
            'success', false,
            'error', SQLERRM,
            'order_id', p_order_id
        );
    END;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions for testing function
GRANT EXECUTE ON FUNCTION test_order_status_notification(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION test_order_status_notification(UUID) TO service_role;

-- Create a view to monitor notification activity
-- Note: This view will work once the notifications table is created by the zip-push function
CREATE OR REPLACE VIEW order_notification_log AS
SELECT 
    o.id as order_id,
    o.user_id,
    o.status,
    o.updated_at as status_updated_at,
    NULL::TEXT as title,
    NULL::TEXT as body,
    NULL::TIMESTAMPTZ as sent_at,
    NULL::INTEGER as success_count,
    NULL::INTEGER as failure_count,
    NULL::TEXT as type
FROM orders o
WHERE o.status IN ('in_progress', 'delivered')
ORDER BY o.updated_at DESC;

-- Grant permissions for the view
GRANT SELECT ON order_notification_log TO authenticated;
GRANT SELECT ON order_notification_log TO service_role;

-- Add helpful comments
COMMENT ON FUNCTION send_order_status_notification() IS 'Automatically sends push notifications when order status changes to in_progress or delivered';
COMMENT ON TRIGGER order_status_notification_trigger ON orders IS 'Triggers push notifications on order status updates';
COMMENT ON FUNCTION test_order_status_notification(UUID) IS 'Test function to manually trigger order status notifications';
COMMENT ON VIEW order_notification_log IS 'View to monitor order status notifications and their delivery status';
