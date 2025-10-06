# Order Status Notification Trigger Setup Guide

## Problem
The order status notification trigger was failing when zippers (delivery personnel) updated order statuses because:
1. Configuration for the Supabase URL and service key was not accessible to the trigger
2. Row Level Security (RLS) policies were blocking the trigger's access to FCM tokens
3. The trigger lacked proper permissions to execute HTTP requests

## Solution
Migration `008_fix_order_notification_trigger.sql` fixes these issues by:
1. Creating a secure `notification_config` table to store Supabase URL and service role key
2. Using `SECURITY DEFINER` to bypass RLS policies when reading FCM tokens
3. Granting explicit permissions to access `fcm_tokens`, `notification_config`, and `pg_net`
4. Adding comprehensive error handling and logging

## Required Setup Steps

### Step 1: Apply the Migration
First, apply the new migration to your Supabase database:

```bash
cd supabase
supabase db push
```

Or manually run the SQL file in your Supabase SQL Editor.

### Step 2: Configure Notification Settings
You need to insert configuration into the `notification_config` table. This stores your Supabase URL and service role key securely.

**Using the Setup Script (Recommended)**

1. Open the file `supabase/setup_notification_config.sql`
2. Find these lines near the top:
   ```sql
   v_supabase_url TEXT := 'YOUR_SUPABASE_PROJECT_URL_HERE';
   v_service_key TEXT := 'YOUR_SERVICE_ROLE_KEY_HERE';
   ```
3. Replace the placeholders with your actual values:
   - **Project URL**: Supabase Dashboard → Settings → API → Project URL
     - Example: `https://abcdefghijklmnop.supabase.co`
   - **Service Role Key**: Supabase Dashboard → Settings → API → service_role key
     - ⚠️ Keep this secret! Never commit it to git or share it publicly
4. Go to your Supabase project dashboard → **SQL Editor**
5. Paste the entire contents of the modified `setup_notification_config.sql` file
6. Run the query
7. You should see: `✅ Configuration created successfully!`

**Manual Configuration (Alternative)**

If you prefer to insert the configuration manually:

```sql
-- Replace with your actual values
INSERT INTO notification_config (id, supabase_url, service_key_encrypted)
VALUES (
    1,
    'https://YOUR_PROJECT_REF.supabase.co',
    'YOUR_SERVICE_ROLE_KEY'
)
ON CONFLICT (id) DO UPDATE
SET 
    supabase_url = EXCLUDED.supabase_url,
    service_key_encrypted = EXCLUDED.service_key_encrypted,
    updated_at = NOW();
```

### Step 3: Verify the Configuration
The setup script includes verification. You should see output like:

```
✅ Configuration found in database:
   URL: https://your-project.supabase.co
   Key: eyJhbGciOiJIUzI1NiIs... (hidden)
   Updated: 2025-01-15 10:30:00

🎉 Notification trigger is ready! Test by having a zipper accept an order.
```

You can also manually verify:

```sql
SELECT 
    supabase_url,
    left(service_key_encrypted, 20) || '...' as key_preview,
    updated_at
FROM notification_config
WHERE id = 1;
```

### Step 4: Test the Trigger
Test that notifications work correctly:

1. Create a test order as a customer
2. Have a zipper accept the order (updates status to `in_progress`)
3. Check the Supabase logs to verify the trigger fired:
   - Go to **Database** → **Database** → **Logs**
   - Look for log messages starting with "Order status notification trigger fired"
4. Verify the customer receives a push notification

## Troubleshooting

### Issue: Trigger fires but no notification sent
**Symptoms:** Logs show "Order status notification trigger fired" but no notification arrives

**Solutions:**
1. Check that database configuration is set (Step 2)
2. Verify FCM tokens exist for the user:
```sql
SELECT * FROM fcm_tokens WHERE user_id = 'YOUR_USER_ID';
```
3. Check that zip-push edge function is deployed and working
4. Review edge function logs in Supabase Dashboard → Edge Functions → zip-push → Logs

### Issue: "No active FCM tokens found"
**Symptoms:** Logs show "No active FCM tokens found for user X"

**Solutions:**
1. Ensure the user has registered their device for push notifications
2. Check the app's FCM registration code is working
3. Verify tokens aren't older than 7 days (they expire):
```sql
SELECT token, updated_at FROM fcm_tokens WHERE user_id = 'YOUR_USER_ID';
```

### Issue: "Notification config not found"
**Symptoms:** Logs show "Notification config not found. Please run setup script"

**Solutions:**
1. Ensure migration 008 was applied successfully (check that `notification_config` table exists)
2. Run the `setup_notification_config.sql` script to insert configuration
3. Verify the configuration exists:
```sql
SELECT * FROM notification_config WHERE id = 1;
```

### Issue: Permission denied errors
**Symptoms:** Logs show permission errors when accessing fcm_tokens or pg_net

**Solutions:**
1. Ensure migration 008 was fully applied
2. Manually grant permissions:
```sql
GRANT SELECT ON fcm_tokens TO postgres;
GRANT USAGE ON SCHEMA net TO postgres;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA net TO postgres;
```

## How It Works

### The Flow
1. Zipper accepts order → Status changes to `in_progress`
2. Database trigger `order_status_notification_trigger` fires
3. Trigger function `send_order_status_notification()` executes:
   - Fetches FCM tokens for the order's customer (bypasses RLS using `SECURITY DEFINER`)
   - Constructs notification message based on order status
   - Calls zip-push edge function via HTTP POST using `pg_net`
4. zip-push edge function sends notification to customer's device(s)

### Security Considerations
- The trigger function uses `SECURITY DEFINER` to run with elevated privileges
- This is necessary to bypass Row Level Security (RLS) policies
- The function only reads FCM tokens and order data - it cannot modify any data
- The service role key is stored securely at the database level
- Only authenticated users with proper permissions can trigger updates

## Alternative Approach (Client-Side Notifications)
If you prefer not to use database triggers, you can keep using the client-side approach:

1. Remove the trigger:
```sql
DROP TRIGGER IF EXISTS order_status_notification_trigger ON orders;
```

2. Ensure `sendOrderStatusNotification()` is called in:
   - `acceptOrder()` method (already implemented ✅)
   - `completeOrder()` method (already implemented ✅)

The client-side approach is simpler but requires the app to be running and have network connectivity when status changes occur.

## Monitoring
To monitor notification delivery, check:
1. **Database Logs**: Supabase Dashboard → Database → Logs
2. **Edge Function Logs**: Supabase Dashboard → Edge Functions → zip-push → Logs
3. **pg_net Requests**: Query the `net._http_response` table for HTTP request history

```sql
-- View recent notification requests
SELECT * FROM net._http_response 
ORDER BY created_at DESC 
LIMIT 10;
```

