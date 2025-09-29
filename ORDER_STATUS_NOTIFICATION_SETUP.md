# Order Status Notification Setup Guide

This guide explains how to set up automatic push notifications when order status changes to `in_progress` or `delivered`.

## Overview

The system consists of:
1. **Database Trigger**: Automatically fires when order status is updated
2. **Notification Function**: Calls your `zip-push` edge function
3. **FCM Integration**: Uses existing FCM token management system

## Setup Instructions

### 1. Apply the Database Migration

Choose one of the two migration files based on your setup:

#### Option A: Full HTTP Implementation (Recommended)
```bash
supabase db reset  # If you want to start fresh
# OR
supabase migration up  # To apply new migrations
```

#### Option B: Simple pg_net Implementation
If you prefer the simpler approach using `pg_net` extension:
- Use the `008_order_status_notification_simple.sql` migration instead

### 2. Configure Environment Variables

You need to set these database-level configuration variables:

#### Using Supabase CLI:
```bash
# Set your Supabase project URL
supabase sql --execute "ALTER DATABASE postgres SET app.supabase_url = 'https://your-project-id.supabase.co';"

# Set your service role key (for edge function authentication)
supabase sql --execute "ALTER DATABASE postgres SET app.supabase_service_key = 'your-service-role-key-here';"
```

#### Using Supabase Dashboard:
1. Go to your project dashboard
2. Navigate to **Settings** → **Database**
3. Run these SQL commands in the SQL editor:

```sql
-- Set your Supabase project URL
ALTER DATABASE postgres SET app.supabase_url = 'https://your-project-id.supabase.co';

-- Set your service role key
ALTER DATABASE postgres SET app.supabase_service_key = 'your-service-role-key-here';
```

### 3. Verify Edge Function Configuration

Ensure your `zip-push` edge function has the required environment variables:

```bash
# Check current secrets
supabase secrets list

# Set FCM credentials if not already set
supabase secrets set FCM_SERVICE_ACCOUNT_EMAIL="your-service-account@project.iam.gserviceaccount.com"
supabase secrets set FCM_SERVICE_ACCOUNT_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY_HERE\n-----END PRIVATE KEY-----"
supabase secrets set FCM_PROJECT_ID="your-firebase-project-id"
```

## How It Works

### Trigger Flow
1. **Order Status Update**: When an order's status is updated to `in_progress` or `delivered`
2. **Token Retrieval**: System fetches all active FCM tokens for the order's user
3. **Notification Generation**: Creates appropriate notification content based on status
4. **Edge Function Call**: Calls your `zip-push` function with the notification payload
5. **Logging**: Records the notification attempt in the `notifications` table

### Notification Content

#### For `in_progress` status:
- **Title**: "🍕 Your Order is Being Prepared"
- **Body**: "Your Zip order #12345678 is now being prepared! We'll notify you when it's ready for pickup."

#### For `delivered` status:
- **Title**: "✅ Order Delivered!"
- **Body**: "Your Zip order #12345678 has been delivered! Enjoy your order and thank you for choosing Zip!"

### Data Payload
Each notification includes:
```json
{
  "order_id": "uuid-string",
  "status": "in_progress" | "delivered",
  "type": "order_status_update",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "order_total": 15.99,
  "user_id": "user-uuid"
}
```

## Testing

### 1. Test with Existing Order
```sql
-- Test the notification system with an existing order
SELECT test_order_notification_manual(
    'your-order-uuid-here'::UUID, 
    'in_progress'
);
```

### 2. Monitor Notifications
```sql
-- View recent order status notifications
SELECT * FROM order_notification_log 
ORDER BY status_updated_at DESC 
LIMIT 10;
```

### 3. Check FCM Token Status
```sql
-- Verify FCM tokens are registered
SELECT 
    user_id,
    COUNT(*) as token_count,
    MAX(updated_at) as last_updated
FROM fcm_tokens 
WHERE updated_at > NOW() - INTERVAL '7 days'
GROUP BY user_id;
```

### 4. Manual Order Status Update
```sql
-- Update an order status to trigger notification
UPDATE orders 
SET status = 'in_progress' 
WHERE id = 'your-order-uuid-here';
```

## Monitoring & Debugging

### 1. View Notification Logs
```sql
-- Check all notifications
SELECT * FROM notifications 
WHERE type = 'push_notification' 
ORDER BY sent_at DESC 
LIMIT 20;
```

### 2. Check Trigger Activity
```sql
-- View recent order updates that triggered notifications
SELECT 
    o.id,
    o.user_id,
    o.status,
    o.updated_at,
    n.title,
    n.sent_at,
    n.success_count,
    n.failure_count
FROM orders o
LEFT JOIN notifications n ON n.data->>'order_id' = o.id::text
WHERE o.status IN ('in_progress', 'delivered')
AND o.updated_at > NOW() - INTERVAL '1 day'
ORDER BY o.updated_at DESC;
```

### 3. Debug FCM Token Issues
```sql
-- Check for users without active FCM tokens
SELECT 
    u.id,
    u.email,
    COUNT(ft.token) as token_count
FROM users u
LEFT JOIN fcm_tokens ft ON ft.user_id = u.id 
    AND ft.updated_at > NOW() - INTERVAL '7 days'
GROUP BY u.id, u.email
HAVING COUNT(ft.token) = 0;
```

## Troubleshooting

### Common Issues

1. **No notifications being sent**
   - Check if FCM tokens are registered and active
   - Verify environment variables are set correctly
   - Check edge function logs for errors

2. **Environment variable errors**
   - Ensure `app.supabase_url` and `app.supabase_service_key` are set
   - Verify the service role key has proper permissions

3. **FCM authentication errors**
   - Check FCM service account credentials in edge function
   - Verify the service account has FCM permissions

4. **HTTP request failures**
   - Check network connectivity from database to edge functions
   - Verify edge function is deployed and accessible

### Debug Commands

```sql
-- Check configuration
SELECT 
    current_setting('app.supabase_url', true) as supabase_url,
    CASE 
        WHEN current_setting('app.supabase_service_key', true) IS NOT NULL 
        THEN 'SET' 
        ELSE 'NOT SET' 
    END as service_key_status;

-- Test FCM token retrieval
SELECT * FROM fcm_tokens 
WHERE user_id = 'test-user-uuid' 
AND updated_at > NOW() - INTERVAL '7 days';
```

## Security Considerations

1. **Service Role Key**: Keep your service role key secure and rotate regularly
2. **FCM Credentials**: Store FCM service account credentials securely in edge function secrets
3. **RLS Policies**: Ensure proper Row Level Security policies are in place
4. **Token Cleanup**: Old FCM tokens are automatically cleaned up after 30 days

## Performance Notes

1. **Async Processing**: The trigger uses async HTTP calls to avoid blocking order updates
2. **Token Filtering**: Only sends to active tokens (updated within last 7 days)
3. **Error Handling**: Failed notifications don't prevent order status updates
4. **Rate Limiting**: Built-in delays prevent overwhelming the FCM API

## Future Enhancements

Consider these improvements:
1. **Notification Preferences**: Allow users to customize notification types
2. **Retry Logic**: Implement retry for failed notifications
3. **Analytics**: Track notification open rates and engagement
4. **Multi-language**: Support multiple languages for notifications
5. **Rich Notifications**: Add images or action buttons to notifications
