# Quick Start: Fix Order Notifications for Zippers

## The Problem You Had
Your database function for sending notifications only worked when the zipper (person fulfilling the order) was the same person who placed the order. This happened because:

1. The function couldn't access the Supabase URL and service key needed to call the push notification edge function
2. Row Level Security (RLS) was blocking access to FCM tokens when a different user updated the order

## The Fix
The new migration creates a secure configuration table and uses elevated privileges to bypass RLS.

## Setup (3 Steps - Takes 5 minutes)

### Step 1: Apply the Migration
```bash
cd /Users/finnmcmillion/Zip/supabase
supabase db push
```

This creates:
- ✅ Fixed notification trigger function
- ✅ `notification_config` table for storing credentials
- ✅ Proper permissions and RLS policies

### Step 2: Configure Your Credentials

1. **Get your values from Supabase Dashboard:**
   - Go to Dashboard → Settings → API
   - Copy **Project URL** (looks like `https://abcdef123456.supabase.co`)
   - Copy **service_role** key (⚠️ Keep this secret!)

2. **Edit `setup_notification_config.sql`:**
   - Open `/Users/finnmcmillion/Zip/supabase/setup_notification_config.sql`
   - Find lines 20-21:
     ```sql
     v_supabase_url TEXT := 'YOUR_SUPABASE_PROJECT_URL_HERE';
     v_service_key TEXT := 'YOUR_SERVICE_ROLE_KEY_HERE';
     ```
   - Replace with your actual values

3. **Run the setup script:**
   - Go to Supabase Dashboard → SQL Editor
   - Paste the entire contents of your edited `setup_notification_config.sql`
   - Click **Run**
   - You should see: ✅ Configuration created successfully!

### Step 3: Test It
1. Place an order as a customer
2. Log in as a different user (zipper)
3. Accept the order (status changes to `in_progress`)
4. Customer should receive a push notification! 🎉

## Verify It's Working

### Check Database Logs
Supabase Dashboard → Database → Logs

Look for:
```
Order status notification trigger fired for order XXX
Found N FCM tokens for user XXX
Push notification request submitted for order XXX
```

### Check Edge Function Logs
Supabase Dashboard → Edge Functions → zip-push → Logs

Should show successful push notification deliveries.

### Check Configuration
```sql
-- Run this to verify your config is set up
SELECT 
    supabase_url,
    left(service_key_encrypted, 20) || '...' as key_preview
FROM notification_config
WHERE id = 1;
```

## Security Notes
- ⚠️ **DO NOT** commit `setup_notification_config.sql` with real credentials to git
- The service role key is stored in the database table (not in code)
- Only service_role and postgres can read the config table
- The key is labeled `service_key_encrypted` but note: it's stored as plain text in this table (protected by RLS)

## Troubleshooting

**No notification received?**
1. Check customer has FCM tokens: `SELECT * FROM fcm_tokens WHERE user_id = 'USER_ID';`
2. Check database logs for errors
3. Verify config exists: `SELECT * FROM notification_config WHERE id = 1;`
4. Ensure zip-push edge function is deployed

**"Notification config not found" error?**
- Run the setup script (Step 2)
- Verify table exists: `SELECT * FROM notification_config;`

**Permission denied errors?**
- Ensure migration 008 ran completely
- Check grants: The function needs SELECT on `fcm_tokens` and `notification_config`

## How It Works Now

```
1. Zipper updates order status (e.g., accepts order)
   ↓
2. Database trigger fires (order_status_notification_trigger)
   ↓
3. Trigger function runs with elevated privileges (SECURITY DEFINER)
   - Reads notification_config table (gets URL + service key)
   - Reads fcm_tokens table (bypasses RLS)
   - Builds notification payload
   ↓
4. Calls zip-push edge function via HTTP (using pg_net)
   ↓
5. Edge function sends FCM notification to customer's device
   ↓
6. Customer receives notification! 🎉
```

## Files Changed
- ✅ `/supabase/migrations/008_fix_order_notification_trigger.sql` - New migration
- ✅ `/supabase/setup_notification_config.sql` - Configuration script
- ✅ `/supabase/NOTIFICATION_TRIGGER_SETUP.md` - Detailed documentation
- ✅ `/supabase/QUICK_START_NOTIFICATIONS.md` - This file

## Next Steps After Setup
Once working, you can:
- Monitor notification delivery rates
- Add more status changes to trigger notifications (optional)
- Set up monitoring/alerting for failed notifications
- Consider adding notification preferences for users

---

Need help? Check the full documentation in `NOTIFICATION_TRIGGER_SETUP.md`

