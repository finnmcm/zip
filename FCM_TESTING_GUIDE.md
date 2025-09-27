# FCM Database Edge Function Testing Guide

This guide provides comprehensive instructions for testing your Firebase Cloud Messaging (FCM) database edge function that sends push notifications.

## Overview

The FCM testing system consists of:
1. **Test Edge Function** - `send-test-notification` for sending test notifications
2. **Python Test Script** - Automated testing from command line
3. **iOS Test View** - Interactive testing within the app
4. **Database Functions** - FCM token management and retrieval

## Prerequisites

Before testing, ensure you have:
- [ ] Supabase project deployed with FCM functions
- [ ] iOS app with FCM integration configured
- [ ] Python 3.7+ installed (for command line testing)
- [ ] Valid FCM tokens registered in database

## Testing Methods

### 1. iOS App Testing (Recommended for Development)

The easiest way to test FCM notifications is through the built-in iOS test interface:

#### Access the Test Interface
1. Open your Zip iOS app
2. Navigate to **Profile** → **Admin** (if you have admin access)
3. Tap the **"FCM Test"** tab

#### Available Tests
- **Local Notification**: Tests the local notification system
- **FCM Token**: Retrieves and displays the current FCM token
- **Register Token**: Forces FCM token registration with Supabase
- **Send Test Notification**: Sends a test notification via edge function
- **Check Permissions**: Verifies notification permissions

#### Running Tests
1. Select a test type from the segmented control
2. Customize the notification title and message
3. Tap **"Run Test"** for individual tests or **"Run All Tests"** for comprehensive testing
4. View results in the test results section

### 2. Command Line Testing (Python Script)

For automated testing and CI/CD integration:

#### Setup
```bash
# Install required Python packages
pip install requests

# Make the script executable
chmod +x test_fcm_notifications.py
```

#### Basic Usage
```bash
# Test all functionality
python test_fcm_notifications.py \
  --supabase-url "https://your-project.supabase.co" \
  --supabase-key "your-anon-key" \
  --run-all-tests

# Test specific functionality
python test_fcm_notifications.py \
  --supabase-url "https://your-project.supabase.co" \
  --supabase-key "your-anon-key" \
  --test-token-registration

# Send test notification to all users
python test_fcm_notifications.py \
  --supabase-url "https://your-project.supabase.co" \
  --supabase-key "your-anon-key" \
  --send-test-all-users

# Send test notification to specific user
python test_fcm_notifications.py \
  --supabase-url "https://your-project.supabase.co" \
  --supabase-key "your-anon-key" \
  --send-test-notification \
  --user-id "user-uuid-here"
```

#### Available Commands
- `--test-token-registration`: Check FCM token registration in database
- `--test-edge-function`: Test edge function health
- `--send-test-notification`: Send test notification (requires --user-id)
- `--send-test-all-users`: Send test notification to all users
- `--get-user-tokens`: Get FCM tokens for specific user
- `--run-all-tests`: Run all available tests

### 3. Direct Edge Function Testing

Test the edge function directly using curl or HTTP client:

#### Send Test Notification
```bash
curl -X POST "https://your-project.supabase.co/functions/v1/send-test-notification" \
  -H "Authorization: Bearer your-anon-key" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Notification",
    "body": "This is a test notification",
    "type": "test",
    "test_all_users": true
  }'
```

#### Send to Specific User
```bash
curl -X POST "https://your-project.supabase.co/functions/v1/send-test-notification" \
  -H "Authorization: Bearer your-anon-key" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Notification",
    "body": "This is a test notification",
    "type": "test",
    "user_id": "user-uuid-here"
  }'
```

## Database Testing

### Check FCM Token Registration

```sql
-- View all FCM tokens
SELECT * FROM fcm_tokens ORDER BY created_at DESC LIMIT 10;

-- Check tokens for specific user
SELECT * FROM fcm_tokens WHERE user_id = 'user-uuid-here';

-- Check active tokens (updated in last 7 days)
SELECT * FROM get_all_active_fcm_tokens();
```

### Test FCM Functions

```sql
-- Test token registration function
SELECT upsert_user_fcm_token(
    'test_token_123456789',
    'test_device_id_12345',
    'ios',
    '1.0.0'
);

-- Test token retrieval
SELECT * FROM get_user_fcm_tokens('user-uuid-here');

-- Clean up test data
DELETE FROM fcm_tokens WHERE token LIKE 'test_token_%';
```

## Troubleshooting

### Common Issues

#### 1. No FCM Tokens Found
**Symptoms**: "No FCM tokens found" error
**Solutions**:
- Ensure users have logged in and granted notification permissions
- Check that FCM token registration is working in the app
- Verify the `fcm_tokens` table exists and has data

#### 2. Edge Function Not Found
**Symptoms**: 404 error when calling edge function
**Solutions**:
- Deploy the edge function: `supabase functions deploy send-test-notification`
- Check function name matches exactly
- Verify Supabase project URL is correct

#### 3. Permission Denied
**Symptoms**: 401/403 errors
**Solutions**:
- Check Supabase anon key is correct
- Verify RLS policies allow the operation
- Ensure user is authenticated for user-specific operations

#### 4. Notifications Not Received
**Symptoms**: Test shows success but no notification appears
**Solutions**:
- Check device notification permissions
- Verify FCM token is valid and not expired
- Check device is connected to internet
- Look for errors in device logs

### Debug Information

#### iOS App Logs
Look for these log messages in Xcode console:
- `🔍 FCM: FCM setup completed successfully`
- `✅ FCM: Token registered successfully with Supabase`
- `📨 FCM: ===== NOTIFICATION RECEIVED =====`

#### Edge Function Logs
Check Supabase dashboard → Functions → Logs for:
- `🔔 Test notification request:`
- `📱 Found X active FCM tokens`
- `✅ Successfully processed X notifications`

#### Database Logs
Monitor the `fcm_tokens` table for:
- New token registrations
- Token updates
- Cleanup operations

## Testing Checklist

### Pre-Test Setup
- [ ] FCM tokens registered in database
- [ ] Edge function deployed
- [ ] iOS app has notification permissions
- [ ] Test devices are connected to internet

### Basic Functionality Tests
- [ ] FCM token generation and registration
- [ ] Local notification display
- [ ] Edge function health check
- [ ] Test notification sending
- [ ] Notification reception on device

### Advanced Tests
- [ ] Multiple device token management
- [ ] Token refresh and update
- [ ] Error handling and recovery
- [ ] Performance under load
- [ ] Offline/online state handling

### Production Readiness
- [ ] All tests pass consistently
- [ ] Error handling works properly
- [ ] Logging provides sufficient debug info
- [ ] Performance meets requirements
- [ ] Security policies are enforced

## Performance Testing

### Load Testing
```bash
# Send multiple test notifications
for i in {1..10}; do
  python test_fcm_notifications.py \
    --supabase-url "https://your-project.supabase.co" \
    --supabase-key "your-anon-key" \
    --send-test-all-users
  sleep 1
done
```

### Monitoring
- Monitor Supabase function execution time
- Check database query performance
- Monitor FCM delivery rates
- Track error rates and types

## Security Considerations

### Testing in Production
- Use test-specific notification types
- Implement rate limiting
- Monitor for abuse
- Use separate test user accounts

### Data Privacy
- Test data should be clearly marked
- Clean up test data regularly
- Don't use real user data in tests
- Respect user notification preferences

## Integration with CI/CD

### GitHub Actions Example
```yaml
name: FCM Testing
on: [push, pull_request]

jobs:
  test-fcm:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Set up Python
        uses: actions/setup-python@v2
        with:
          python-version: '3.9'
      - name: Install dependencies
        run: pip install requests
      - name: Run FCM tests
        run: |
          python test_fcm_notifications.py \
            --supabase-url ${{ secrets.SUPABASE_URL }} \
            --supabase-key ${{ secrets.SUPABASE_ANON_KEY }} \
            --run-all-tests
```

## Next Steps

After successful testing:
1. Deploy edge function to production
2. Update iOS app with production configuration
3. Set up monitoring and alerting
4. Create user documentation
5. Plan for scaling and optimization

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review logs for error messages
3. Test with simplified scenarios
4. Verify all prerequisites are met
5. Contact support with detailed error information

Remember to always test in a development environment before deploying to production!
