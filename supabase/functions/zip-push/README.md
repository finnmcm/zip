# Zip Push - Generic FCM Notification Service

A generic Supabase Edge Function for sending Firebase Cloud Messaging (FCM) push notifications to multiple devices using the modern FCM HTTP v1 API.

## Overview

The `zip-push` function accepts an array of FCM tokens and notification details, then sends push notifications to all specified devices using Firebase's FCM HTTP v1 API with OAuth 2.0 authentication.

## Usage

### Endpoint
```
POST https://your-project.supabase.co/functions/v1/zip-push
```

### Request Body

```typescript
interface PushNotificationRequest {
  fcm_tokens: string[]        // Required: Array of FCM device tokens
  title: string              // Required: Notification title
  body: string               // Required: Notification body text
  data?: Record<string, string>  // Optional: Custom data payload
  priority?: 'normal' | 'high'   // Optional: Notification priority (default: 'high')
  sound?: string             // Optional: Sound file name (default: 'default')
  badge?: number             // Optional: Badge count (default: 1)
}
```

### Example Request

```bash
curl -X POST 'https://your-project.supabase.co/functions/v1/zip-push' \
  -H 'Authorization: Bearer YOUR_SUPABASE_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "fcm_tokens": [
      "fcm_token_1_here",
      "fcm_token_2_here",
      "fcm_token_3_here"
    ],
    "title": "Order Update",
    "body": "Your order #12345 is ready for pickup!",
    "data": {
      "order_id": "12345",
      "type": "order_ready"
    },
    "priority": "high",
    "badge": 1
  }'
```

### Example Response

```json
{
  "success": true,
  "message": "Push notification processed: 3 successful, 0 failed",
  "summary": {
    "total_tokens": 3,
    "successful": 3,
    "failed": 0,
    "title": "Order Update",
    "body": "Your order #12345 is ready for pickup!",
    "priority": "high",
    "timestamp": "2024-01-15T10:30:00.000Z"
  },
  "results": [
    {
      "token": "fcm_token_1_here...",
      "success": true,
      "message_id": "projects/your-project/messages/0:1234567890"
    },
    {
      "token": "fcm_token_2_here...",
      "success": true,
      "message_id": "projects/your-project/messages/0:1234567891"
    },
    {
      "token": "fcm_token_3_here...",
      "success": false,
      "error": "InvalidRegistration"
    }
  ]
}
```

## Features

### 🔄 **Batch Processing**
- Sends notifications to multiple FCM tokens in a single request
- Processes tokens sequentially with rate limiting protection
- Returns detailed results for each token

### 📊 **Comprehensive Logging**
- Logs all notification attempts to the `notifications` table
- Tracks success/failure counts
- Stores detailed results for debugging

### 🛡️ **Error Handling**
- Validates input parameters
- Handles FCM API errors gracefully
- Continues processing even if individual tokens fail
- Returns detailed error information

### 🎯 **Cross-Platform Support**
- Optimized payloads for both Android and iOS
- Proper APNS configuration for iOS
- Android-specific notification settings

## Environment Variables

The function requires the following environment variables:

- `FCM_SERVICE_ACCOUNT_EMAIL`: Email of your Google Cloud service account (required)
- `FCM_SERVICE_ACCOUNT_PRIVATE_KEY`: Private key of your service account (required)
- `FCM_PROJECT_ID`: Your Firebase/Google Cloud project ID (required)
- `SUPABASE_URL`: Your Supabase project URL (auto-configured)
- `SUPABASE_SERVICE_ROLE_KEY`: Service role key for database access (auto-configured)

## Database Schema

The function logs notifications to the `notifications` table with the following structure:

```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  type TEXT DEFAULT 'push_notification',
  data JSONB,
  sent_at TIMESTAMPTZ DEFAULT NOW(),
  recipient_count INTEGER,
  success_count INTEGER,
  failure_count INTEGER,
  results JSONB
);
```

## Error Responses

### 400 Bad Request
```json
{
  "success": false,
  "error": "fcm_tokens array is required and must not be empty"
}
```

### 500 Internal Server Error
```json
{
  "success": false,
  "error": "FCM service account credentials not configured. Required: FCM_SERVICE_ACCOUNT_EMAIL, FCM_SERVICE_ACCOUNT_PRIVATE_KEY, FCM_PROJECT_ID"
}
```

## Rate Limiting

The function includes built-in rate limiting:
- 100ms delay between token processing
- Handles FCM rate limits gracefully
- Continues processing even if individual requests fail

## Use Cases

- **Order Updates**: Notify customers when orders are ready
- **Promotional Messages**: Send marketing notifications to user segments
- **System Alerts**: Broadcast important app updates or maintenance notices
- **User Engagement**: Send personalized notifications based on user behavior

## Security

- Requires Supabase authentication
- Uses service role key for database operations
- Validates all input parameters
- Logs all notification attempts for audit trails

## Setup Instructions

### 1. Create Google Cloud Service Account

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project (`zip-push`)
3. Navigate to **IAM & Admin** → **Service Accounts**
4. Click **Create Service Account**
5. Name: `fcm-notification-service`
6. Description: `Service account for FCM push notifications`
7. Click **Create and Continue**
8. Grant the following roles:
   - **Firebase Cloud Messaging API Admin** (or **Cloud Messaging Admin**)
9. Click **Done**

### 2. Generate Service Account Key

1. Find your newly created service account
2. Click on it → **Keys** tab → **Add Key** → **Create new key**
3. Choose **JSON** format
4. Download the JSON file
5. Extract the following values:
   - `client_email` → This is your `FCM_SERVICE_ACCOUNT_EMAIL`
   - `private_key` → This is your `FCM_SERVICE_ACCOUNT_PRIVATE_KEY`
   - `project_id` → This is your `FCM_PROJECT_ID`

### 3. Set Environment Variables

Using Supabase CLI:
```bash
supabase secrets set FCM_SERVICE_ACCOUNT_EMAIL="your-service-account@project.iam.gserviceaccount.com"
supabase secrets set FCM_SERVICE_ACCOUNT_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY_HERE\n-----END PRIVATE KEY-----"
supabase secrets set FCM_PROJECT_ID="your-firebase-project-id"
```

Or using Supabase Dashboard:
1. Go to your Supabase project → **Settings** → **Edge Functions**
2. Add each environment variable

## Deployment

1. Ensure your FCM service account credentials are set in the environment variables
2. Deploy the function using Supabase CLI:
   ```bash
   supabase functions deploy zip-push
   ```
3. Test with a small batch of tokens first
4. Monitor the logs for any issues

## Testing

You can test the function using the Supabase dashboard or any HTTP client:

1. Go to your Supabase project dashboard
2. Navigate to Edge Functions
3. Select `zip-push`
4. Use the test interface with sample data

## Monitoring

- Check the `notifications` table for delivery statistics
- Monitor Supabase function logs for errors
- Use FCM console to verify message delivery
- Track success/failure rates in your application
