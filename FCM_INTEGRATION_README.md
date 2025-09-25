# Firebase Cloud Messaging (FCM) Integration

This document outlines the Firebase Cloud Messaging integration for the Zip iOS app, including setup, configuration, and usage.

## Overview

Firebase Cloud Messaging (FCM) has been integrated into the Zip app to provide push notifications for:
- Order updates (placed, confirmed, in progress, ready, delivered, cancelled)
- Payment updates
- Store updates and announcements
- Promotional offers
- General notifications

## Architecture

### Components

1. **FCMService** - Main service handling FCM operations
2. **Notification Models** - Data structures for notifications
3. **Supabase Integration** - Token storage and management
4. **UI Components** - Notification settings and center views
5. **Authentication Integration** - Automatic token registration on login

### Flow

```
App Launch → Firebase Init → FCM Token Generation → User Login → Token Registration with Supabase
                                                                                    ↓
User Receives Notification ← FCM ← Supabase Edge Function ← Backend Service
```

## Setup Instructions

### 1. Firebase Project Setup

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add an iOS app to your project
3. Download `GoogleService-Info.plist` and place it in the project root
4. Enable Cloud Messaging in the Firebase Console

### 2. iOS Configuration

#### Info.plist Configuration
Add the following keys to your `Info.plist`:

```xml
<key>FIREBASE_API_KEY</key>
<string>YOUR_FIREBASE_API_KEY</string>
<key>FIREBASE_SENDER_ID</key>
<string>YOUR_FIREBASE_SENDER_ID</string>
<key>FIREBASE_PROJECT_ID</key>
<string>your-firebase-project-id</string>
<key>FIREBASE_GOOGLE_APP_ID</key>
<string>YOUR_FIREBASE_GOOGLE_APP_ID</string>
```

#### App Initialization
Firebase is initialized in `ZipApp.swift`:

```swift
init() {
    // Initialize Firebase
    FirebaseApp.configure()
    print("✅ Firebase initialized successfully")
}
```

### 3. Supabase Database Setup

Run the migration to create the FCM tokens table:

```sql
-- Run the migration file
supabase db push
```

This creates:
- `fcm_tokens` table for storing device tokens
- RLS policies for security
- Helper functions for token management
- Cleanup functions for old tokens

### 4. Backend Integration

#### Edge Function for Sending Notifications

Create an edge function to send notifications via FCM:

```typescript
// supabase/functions/send-notification/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { user_id, title, body, type, data } = await req.json()
    
    // Get FCM tokens for the user
    const { data: tokens } = await supabase
      .from('fcm_tokens')
      .select('token')
      .eq('user_id', user_id)
    
    // Send notification via FCM
    // Implementation depends on your FCM server setup
    
    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
```

## Usage

### Requesting Notification Permission

```swift
let fcmService = FCMService.shared
let granted = await fcmService.requestNotificationPermission()
```

### Sending Notifications

Notifications are automatically sent from your backend when:
- Order status changes
- Payment is processed
- Store updates occur
- Promotions are available

### Managing Notification Settings

Users can manage their notification preferences in the Profile tab:
- Navigate to Profile → Notification Settings
- Toggle specific notification types on/off
- View notification statistics

### Viewing Notifications

Users can view their notifications in the Profile tab:
- Navigate to Profile → Notifications
- Filter by notification type
- Mark notifications as read
- Clear all notifications

## Notification Types

### Order Updates
- **order_update**: General order status changes
- **order_ready**: Order is ready for pickup
- **order_delivered**: Order has been delivered
- **order_cancelled**: Order has been cancelled

### Payment Updates
- **payment_update**: Payment status changes

### Store Updates
- **store_update**: Store announcements and updates

### Promotions
- **promotion**: Special offers and discounts

### General
- **general**: Other notifications

## Security

### Row Level Security (RLS)
- Users can only manage their own FCM tokens
- Service role can manage all tokens for sending notifications
- Tokens are automatically cleaned up after 30 days of inactivity

### Token Management
- Tokens are stored securely in Supabase
- Device IDs are used to prevent duplicate registrations
- Tokens are refreshed automatically when they change

## Testing

### Local Testing
1. Use Firebase Console to send test notifications
2. Check device logs for FCM token generation
3. Verify token registration in Supabase database

### Production Testing
1. Deploy edge functions to Supabase
2. Test notification sending from your backend
3. Monitor notification delivery rates

## Troubleshooting

### Common Issues

1. **Notifications not received**
   - Check notification permissions
   - Verify FCM token is registered
   - Check device network connectivity

2. **Token registration fails**
   - Verify Supabase configuration
   - Check RLS policies
   - Ensure user is authenticated

3. **Notifications not showing in foreground**
   - Check UNUserNotificationCenter delegate implementation
   - Verify notification presentation options

### Debug Information

Enable debug logging by checking the console for:
- FCM token generation
- Token registration with Supabase
- Notification reception
- Permission status changes

## Future Enhancements

1. **Rich Notifications**
   - Add images and actions to notifications
   - Implement notification categories

2. **Scheduled Notifications**
   - Send notifications at specific times
   - Implement notification scheduling

3. **Analytics**
   - Track notification open rates
   - Monitor user engagement

4. **A/B Testing**
   - Test different notification formats
   - Optimize notification timing

## Dependencies

- Firebase iOS SDK
- Firebase Messaging
- Supabase iOS SDK
- UserNotifications framework

## Files Modified

- `ZipApp.swift` - Firebase initialization
- `Configuration.swift` - Firebase configuration
- `FCMService.swift` - Main FCM service
- `Notification.swift` - Notification models
- `SupabaseService.swift` - Token registration
- `AuthViewModel.swift` - Authentication integration
- `ProfileView.swift` - UI integration
- `MainTabView.swift` - Badge display
- `NotificationSettingsView.swift` - Settings UI
- `NotificationCenterView.swift` - Notification display

## Database Schema

```sql
CREATE TABLE fcm_tokens (
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
```

This integration provides a robust foundation for push notifications in the Zip app, with proper security, user control, and scalability.
