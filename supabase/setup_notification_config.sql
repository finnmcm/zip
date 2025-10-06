-- Setup Script for Order Notification Trigger Configuration
-- 
-- ⚠️ SECURITY WARNING ⚠️
-- This script will contain your service role key after you fill it in.
-- DO NOT commit this file to git after adding real credentials!
-- The key will be stored securely in the database, not in your code.
--
-- INSTRUCTIONS:
-- 1. Find your Supabase project values:
--    - Project URL: Supabase Dashboard → Settings → API → Project URL
--    - Service Role Key: Supabase Dashboard → Settings → API → service_role key
-- 
-- 2. Replace the placeholders below with your actual values
-- 3. Run this script in the Supabase SQL Editor (copy/paste the whole file)
-- 4. After running, DO NOT save this file with real credentials in git
--
-- IMPORTANT: You must be authenticated as service_role or have proper permissions
--

-- ==================================================================
-- REPLACE THESE VALUES WITH YOUR ACTUAL SUPABASE PROJECT VALUES
-- ==================================================================

DO $$
DECLARE
    v_supabase_url TEXT := 'YOUR_SUPABASE_PROJECT_URL_HERE';
    v_service_key TEXT := 'YOUR_SERVICE_ROLE_KEY_HERE';
    v_existing_count INT;
BEGIN
    -- Validate that placeholders were replaced
    IF v_supabase_url = 'YOUR_SUPABASE_PROJECT_URL_HERE' THEN
        RAISE EXCEPTION 'Please replace YOUR_SUPABASE_PROJECT_URL_HERE with your actual Supabase project URL (e.g., https://abcdefgh.supabase.co)';
    END IF;
    
    IF v_service_key = 'YOUR_SERVICE_ROLE_KEY_HERE' THEN
        RAISE EXCEPTION 'Please replace YOUR_SERVICE_ROLE_KEY_HERE with your actual service role key';
    END IF;
    
    -- Check if URL format is valid
    IF v_supabase_url NOT LIKE 'https://%' THEN
        RAISE EXCEPTION 'Supabase URL must start with https://';
    END IF;
    
    -- Check if configuration already exists
    SELECT COUNT(*) INTO v_existing_count FROM notification_config WHERE id = 1;
    
    IF v_existing_count > 0 THEN
        -- Update existing configuration
        UPDATE notification_config
        SET 
            supabase_url = v_supabase_url,
            service_key_encrypted = v_service_key,
            updated_at = NOW()
        WHERE id = 1;
        
        RAISE NOTICE '✅ Configuration updated successfully!';
    ELSE
        -- Insert new configuration
        INSERT INTO notification_config (id, supabase_url, service_key_encrypted)
        VALUES (1, v_supabase_url, v_service_key);
        
        RAISE NOTICE '✅ Configuration created successfully!';
    END IF;
    
    RAISE NOTICE 'Supabase URL: %', v_supabase_url;
    RAISE NOTICE 'Service key: %', left(v_service_key, 20) || '... (hidden)';
    RAISE NOTICE '';
    RAISE NOTICE 'The notification trigger is now configured and ready to use!';
END $$;

-- ==================================================================
-- VERIFICATION
-- ==================================================================

-- Verify the configuration was inserted correctly
DO $$
DECLARE
    config_record RECORD;
BEGIN
    SELECT * INTO config_record FROM notification_config WHERE id = 1;
    
    IF FOUND THEN
        RAISE NOTICE '✅ Configuration found in database:';
        RAISE NOTICE '   URL: %', config_record.supabase_url;
        RAISE NOTICE '   Key: %', left(config_record.service_key_encrypted, 20) || '... (hidden)';
        RAISE NOTICE '   Updated: %', config_record.updated_at;
        RAISE NOTICE '';
        RAISE NOTICE '🎉 Notification trigger is ready! Test by having a zipper accept an order.';
    ELSE
        RAISE WARNING '❌ No configuration found! The trigger will not be able to send notifications.';
        RAISE WARNING '   Please check that the migration ran successfully and try again.';
    END IF;
END $$;

-- ==================================================================
-- OPTIONAL: VIEW CURRENT CONFIGURATION (SERVICE ROLE ONLY)
-- ==================================================================

-- View the current configuration (uncomment to run)
-- SELECT 
--     id,
--     supabase_url,
--     left(service_key_encrypted, 20) || '...' as service_key_preview,
--     updated_at
-- FROM notification_config;

