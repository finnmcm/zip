-- Test script to verify FCM token registration
-- Run this in your Supabase SQL editor to test the function

-- First, let's see what's currently in the fcm_tokens table
SELECT * FROM fcm_tokens ORDER BY created_at DESC LIMIT 10;

-- Test the upsert_user_fcm_token function directly
-- Replace 'your-user-id-here' with an actual user ID from your users table
SELECT upsert_user_fcm_token(
    'test_fcm_token_123456789',
    'test_device_id_12345',
    'ios',
    '1.0.0'
);

-- Check the result
SELECT * FROM fcm_tokens WHERE token = 'test_fcm_token_123456789';

-- Test with a different device ID for the same user (should create new row)
SELECT upsert_user_fcm_token(
    'test_fcm_token_987654321',
    'test_device_id_67890',
    'ios',
    '1.0.0'
);

-- Check both tokens for the user
SELECT * FROM fcm_tokens ORDER BY created_at DESC LIMIT 5;

-- Test updating an existing token (same user, same device)
SELECT upsert_user_fcm_token(
    'updated_fcm_token_111111111',
    'test_device_id_12345',
    'ios',
    '1.0.0'
);

-- Verify the token was updated
SELECT * FROM fcm_tokens WHERE device_id = 'test_device_id_12345';

-- Clean up test data
DELETE FROM fcm_tokens WHERE token LIKE 'test_fcm_token_%' OR token LIKE 'updated_fcm_token_%';
