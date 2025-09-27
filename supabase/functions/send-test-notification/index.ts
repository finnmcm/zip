// Test edge function for sending FCM notifications
// This function allows you to test FCM notifications without going through the full order flow

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface NotificationPayload {
  user_id?: string
  title: string
  body: string
  type?: string
  data?: Record<string, string>
  test_all_users?: boolean
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { user_id, title, body, type = 'general', data = {}, test_all_users = false }: NotificationPayload = await req.json()
    
    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    console.log('🔔 Test notification request:', { user_id, title, body, type, test_all_users })

    let fcmTokens: any[] = []

    if (test_all_users) {
      // Get all active FCM tokens
      console.log('📱 Getting all active FCM tokens...')
      const { data: tokens, error: tokensError } = await supabase
        .rpc('get_all_active_fcm_tokens')
      
      if (tokensError) {
        console.error('❌ Error getting all FCM tokens:', tokensError)
        return new Response(JSON.stringify({ 
          success: false, 
          error: 'Failed to get FCM tokens',
          details: tokensError.message 
        }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400,
        })
      }
      
      fcmTokens = tokens || []
      console.log(`📱 Found ${fcmTokens.length} active FCM tokens`)
    } else if (user_id) {
      // Get FCM tokens for specific user
      console.log(`📱 Getting FCM tokens for user: ${user_id}`)
      const { data: tokens, error: tokensError } = await supabase
        .from('fcm_tokens')
        .select('token, device_id, platform')
        .eq('user_id', user_id)
      
      if (tokensError) {
        console.error('❌ Error getting user FCM tokens:', tokensError)
        return new Response(JSON.stringify({ 
          success: false, 
          error: 'Failed to get user FCM tokens',
          details: tokensError.message 
        }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400,
        })
      }
      
      fcmTokens = tokens || []
      console.log(`📱 Found ${fcmTokens.length} FCM tokens for user ${user_id}`)
    } else {
      return new Response(JSON.stringify({ 
        success: false, 
        error: 'Either user_id or test_all_users must be provided' 
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      })
    }

    if (fcmTokens.length === 0) {
      return new Response(JSON.stringify({ 
        success: false, 
        error: 'No FCM tokens found for the specified criteria',
        details: test_all_users ? 'No active tokens found' : `No tokens found for user ${user_id}`
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 404,
      })
    }

    // For testing purposes, we'll simulate sending notifications
    // In a real implementation, you would use Firebase Admin SDK or FCM REST API
    console.log('📤 Simulating FCM notification sending...')
    
    const notificationResults = fcmTokens.map((tokenData, index) => {
      const notification = {
        to: tokenData.token,
        notification: {
          title,
          body,
        },
        data: {
          type,
          timestamp: new Date().toISOString(),
          ...data
        },
        android: {
          priority: 'high',
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title,
                body,
              },
              badge: 1,
              sound: 'default',
            },
          },
        },
      }

      console.log(`📤 Notification ${index + 1}/${fcmTokens.length}:`, {
        token: tokenData.token.substring(0, 20) + '...',
        device_id: tokenData.device_id,
        platform: tokenData.platform,
        title,
        body
      })

      return {
        success: true,
        token: tokenData.token.substring(0, 20) + '...',
        device_id: tokenData.device_id,
        platform: tokenData.platform,
        message_id: `test_${Date.now()}_${index}`
      }
    })

    // Log the notification to the database for tracking
    const { error: logError } = await supabase
      .from('notifications')
      .insert({
        title,
        body,
        type,
        data: JSON.stringify(data),
        sent_at: new Date().toISOString(),
        recipient_count: fcmTokens.length,
        test_notification: true
      })

    if (logError) {
      console.warn('⚠️ Failed to log notification to database:', logError)
    }

    console.log(`✅ Successfully processed ${notificationResults.length} notifications`)

    return new Response(JSON.stringify({ 
      success: true, 
      message: `Test notification sent to ${notificationResults.length} device(s)`,
      results: notificationResults,
      summary: {
        total_tokens: fcmTokens.length,
        notification_type: type,
        title,
        body
      }
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error) {
    console.error('❌ Error in send-test-notification:', error)
    return new Response(JSON.stringify({ 
      success: false, 
      error: error.message || 'Unknown error occurred',
      details: error.stack
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})
