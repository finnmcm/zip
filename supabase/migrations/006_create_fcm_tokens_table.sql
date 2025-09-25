-- Create FCM tokens table for storing device tokens
CREATE TABLE IF NOT EXISTS fcm_tokens (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    device_id TEXT NOT NULL,
    platform TEXT NOT NULL DEFAULT 'ios',
    app_version TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, device_id)
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_user_id ON fcm_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_token ON fcm_tokens(token);

-- Add RLS policies
ALTER TABLE fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Policy for users to manage their own tokens
CREATE POLICY "Users can manage their own FCM tokens" ON fcm_tokens
    FOR ALL USING (auth.uid() = user_id);

-- Policy for service role to manage all tokens (for sending notifications)
CREATE POLICY "Service role can manage all FCM tokens" ON fcm_tokens
    FOR ALL USING (auth.role() = 'service_role');

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_fcm_tokens_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_fcm_tokens_updated_at
    BEFORE UPDATE ON fcm_tokens
    FOR EACH ROW
    EXECUTE FUNCTION update_fcm_tokens_updated_at();

-- Create function to clean up old tokens (older than 30 days)
CREATE OR REPLACE FUNCTION cleanup_old_fcm_tokens()
RETURNS void AS $$
BEGIN
    DELETE FROM fcm_tokens 
    WHERE updated_at < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;

-- Create function to get FCM tokens for a user
CREATE OR REPLACE FUNCTION get_user_fcm_tokens(p_user_id UUID)
RETURNS TABLE(token TEXT, device_id TEXT, platform TEXT, app_version TEXT, updated_at TIMESTAMP WITH TIME ZONE) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ft.token,
        ft.device_id,
        ft.platform,
        ft.app_version,
        ft.updated_at
    FROM fcm_tokens ft
    WHERE ft.user_id = p_user_id
    ORDER BY ft.updated_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Create function to get all active FCM tokens (for broadcasting notifications)
CREATE OR REPLACE FUNCTION get_all_active_fcm_tokens()
RETURNS TABLE(user_id UUID, token TEXT, device_id TEXT, platform TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ft.user_id,
        ft.token,
        ft.device_id,
        ft.platform
    FROM fcm_tokens ft
    WHERE ft.updated_at > NOW() - INTERVAL '7 days'  -- Only tokens updated in last 7 days
    ORDER BY ft.updated_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Create function to upsert FCM token for authenticated user
CREATE OR REPLACE FUNCTION upsert_user_fcm_token(
    p_token TEXT,
    p_device_id TEXT,
    p_platform TEXT DEFAULT 'ios',
    p_app_version TEXT DEFAULT '1.0.0'
)
RETURNS JSON AS $$
DECLARE
    current_user_id UUID;
    result JSON;
BEGIN
    -- Get the current authenticated user ID
    current_user_id := auth.uid();
    
    -- Check if user is authenticated
    IF current_user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'User not authenticated'
        );
    END IF;
    
    -- Upsert the FCM token (insert or update on conflict)
    INSERT INTO fcm_tokens (
        user_id,
        token,
        device_id,
        platform,
        app_version,
        created_at,
        updated_at
    ) VALUES (
        current_user_id,
        p_token,
        p_device_id,
        p_platform,
        p_app_version,
        NOW(),
        NOW()
    )
    ON CONFLICT (user_id, device_id) 
    DO UPDATE SET
        token = EXCLUDED.token,
        platform = EXCLUDED.platform,
        app_version = EXCLUDED.app_version,
        updated_at = NOW();
    
    -- Return success response
    RETURN json_build_object(
        'success', true,
        'message', 'FCM token updated successfully',
        'user_id', current_user_id,
        'device_id', p_device_id
    );
    
EXCEPTION
    WHEN OTHERS THEN
        -- Return error response
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to remove FCM token for authenticated user
CREATE OR REPLACE FUNCTION remove_user_fcm_token(p_device_id TEXT)
RETURNS JSON AS $$
DECLARE
    current_user_id UUID;
    deleted_count INTEGER;
BEGIN
    -- Get the current authenticated user ID
    current_user_id := auth.uid();
    
    -- Check if user is authenticated
    IF current_user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'User not authenticated'
        );
    END IF;
    
    -- Delete the FCM token for this user and device
    DELETE FROM fcm_tokens 
    WHERE fcm_tokens.user_id = current_user_id 
    AND fcm_tokens.device_id = p_device_id;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    -- Return success response
    RETURN json_build_object(
        'success', true,
        'message', 'FCM token removed successfully',
        'deleted_count', deleted_count,
        'user_id', current_user_id,
        'device_id', p_device_id
    );
    
EXCEPTION
    WHEN OTHERS THEN
        -- Return error response
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get FCM tokens for authenticated user
CREATE OR REPLACE FUNCTION get_my_fcm_tokens()
RETURNS TABLE(token TEXT, device_id TEXT, platform TEXT, app_version TEXT, updated_at TIMESTAMP WITH TIME ZONE) AS $$
DECLARE
    current_user_id UUID;
BEGIN
    -- Get the current authenticated user ID
    current_user_id := auth.uid();
    
    -- Check if user is authenticated
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;
    
    -- Return FCM tokens for the authenticated user
    RETURN QUERY
    SELECT 
        ft.token,
        ft.device_id,
        ft.platform,
        ft.app_version,
        ft.updated_at
    FROM fcm_tokens ft
    WHERE ft.user_id = current_user_id
    ORDER BY ft.updated_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger function for automatic FCM token creation
CREATE OR REPLACE FUNCTION trigger_create_fcm_token_for_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- This will be called when a new user is inserted
    -- Note: We can't call upsert_user_fcm_token here because it requires auth.uid()
    -- Instead, we'll create a placeholder token that can be updated later
    -- Temporarily disable RLS for this operation
    SET LOCAL row_security = off;
    INSERT INTO fcm_tokens (user_id, token, device_id, platform, app_version)
    VALUES (NEW.id, 'pending_authentication', 'pending_device_id', 'ios', '1.0.0')
    ON CONFLICT (user_id, device_id) DO NOTHING;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on users table
CREATE TRIGGER create_fcm_token_on_user_insert
    AFTER INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION trigger_create_fcm_token_for_new_user();

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON fcm_tokens TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_fcm_tokens(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_all_active_fcm_tokens() TO service_role;
GRANT EXECUTE ON FUNCTION cleanup_old_fcm_tokens() TO service_role;
GRANT EXECUTE ON FUNCTION upsert_user_fcm_token(TEXT, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION upsert_user_fcm_token(TEXT, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION remove_user_fcm_token(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_my_fcm_tokens() TO authenticated;
GRANT EXECUTE ON FUNCTION trigger_create_fcm_token_for_new_user() TO authenticated;
