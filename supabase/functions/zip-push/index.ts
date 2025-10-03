// Generic Supabase Edge Function for sending FCM push notifications
// Takes FCM tokens, notification title and body, and sends to all specified devices
// Uses FCM HTTP v1 API with OAuth 2.0 authentication

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { SignJWT, importPKCS8 } from 'jose'
import * as forge from 'node-forge'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface PushNotificationRequest {
  fcm_tokens: string[]
  title: string
  body: string
  data?: Record<string, string>
  priority?: 'normal' | 'high'
  sound?: string
  badge?: number
}

interface FCMV1Response {
  name?: string  // Message name for successful sends
  error?: {
    code: number
    message: string
    status: string
    details?: any[]
  }
}

interface NotificationResult {
  token: string
  success: boolean
  message_id?: string
  error?: string
}

// OAuth 2.0 token interface
interface AccessToken {
  access_token: string
  token_type: string
  expires_in: number
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { 
      fcm_tokens, 
      title, 
      body, 
      data = {}, 
      priority = 'high',
      sound = 'default',
      badge = 1
    }: PushNotificationRequest = await req.json()
    
    // Validate required fields
    if (!fcm_tokens || !Array.isArray(fcm_tokens) || fcm_tokens.length === 0) {
      return new Response(JSON.stringify({ 
        success: false, 
        error: 'fcm_tokens array is required and must not be empty' 
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      })
    }

    if (!title || !body) {
      return new Response(JSON.stringify({ 
        success: false, 
        error: 'Both title and body are required' 
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      })
    }

    // Get Google Cloud service account credentials from environment
    const serviceAccountEmail = Deno.env.get('FCM_SERVICE_ACCOUNT_EMAIL')
    const serviceAccountPrivateKey = Deno.env.get('FCM_SERVICE_ACCOUNT_PRIVATE_KEY')
    const projectId = Deno.env.get('FCM_PROJECT_ID')
    
    if (!serviceAccountEmail || !serviceAccountPrivateKey || !projectId) {
      console.error('❌ FCM service account credentials not configured')
      return new Response(JSON.stringify({ 
        success: false, 
        error: 'FCM service account credentials not configured. Required: FCM_SERVICE_ACCOUNT_EMAIL, FCM_SERVICE_ACCOUNT_PRIVATE_KEY, FCM_PROJECT_ID' 
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      })
    }

    console.log(`🔔 Sending push notification to ${fcm_tokens.length} device(s)`)
    console.log(`📝 Title: ${title}`)
    console.log(`📝 Body: ${body}`)
    console.log(`📊 Data:`, data)

    // Initialize Supabase client for logging
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    const results: NotificationResult[] = []
    
    // Generate OAuth 2.0 access token
    console.log('🔐 Generating OAuth 2.0 access token...')
    const accessToken = await generateAccessToken(serviceAccountEmail, serviceAccountPrivateKey)
    if (!accessToken) {
      return new Response(JSON.stringify({ 
        success: false, 
        error: 'Failed to generate OAuth 2.0 access token' 
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      })
    }

    // Send notifications to each FCM token
    for (let i = 0; i < fcm_tokens.length; i++) {
      const token = fcm_tokens[i]
      
      if (!token || typeof token !== 'string') {
        console.warn(`⚠️ Invalid token at index ${i}: ${token}`)
        results.push({
          token: `invalid_token_${i}`,
          success: false,
          error: 'Invalid token format'
        })
        continue
      }

      // Validate FCM token format
      if (!isValidFCMToken(token)) {
        console.warn(`⚠️ Invalid FCM token format at index ${i}: ${token.substring(0, 20)}...`)
        results.push({
          token: token.substring(0, 20) + '...',
          success: false,
          error: 'Invalid FCM token format'
        })
        continue
      }

      try {
        const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`
        
        const payload = {
          message: {
            token: token,
            notification: {
              title,
              body,
            },
            data: {
              timestamp: new Date().toISOString(),
              priority,
              ...data
            },
            android: {
              priority: priority.toUpperCase(),
              notification: {
                sound,
                notification_count: badge,
                click_action: 'FLUTTER_NOTIFICATION_CLICK'
              }
            },
            apns: {
              payload: {
                aps: {
                  alert: {
                    title,
                    body,
                  },
                  badge,
                  sound,
                  'content-available': 1,
                  'interruption-level': 'active',
                  'relevance-score': 1.0
                },
              },
            },
          },
        }

        console.log(`📤 Sending to token ${i + 1}/${fcm_tokens.length}: ${token.substring(0, 20)}...`)

        const response = await fetch(fcmUrl, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(payload),
        })

        const responseData: FCMV1Response = await response.json()

        if (response.ok && responseData.name) {
          console.log(`✅ Success for token ${i + 1}: ${responseData.name}`)
          results.push({
            token: token.substring(0, 20) + '...',
            success: true,
            message_id: responseData.name
          })
        } else {
          console.error(`❌ FCM error for token ${i + 1}:`, responseData)
          
          // Check if this is an invalid token error
          if (responseData.error?.code === 400 && 
              responseData.error?.message?.includes('registration token is not a valid FCM registration token')) {
            console.log(`🗑️ Token ${i + 1} is invalid, marking for cleanup: ${token.substring(0, 20)}...`)
            
            // Mark this token for cleanup in the database
            try {
              await cleanupInvalidToken(token, supabase)
            } catch (cleanupError) {
              console.warn(`⚠️ Failed to cleanup invalid token: ${cleanupError.message}`)
            }
          }
          
          results.push({
            token: token.substring(0, 20) + '...',
            success: false,
            error: responseData.error?.message || `HTTP ${response.status}`
          })
        }

        // Add small delay to avoid rate limiting
        if (i < fcm_tokens.length - 1) {
          await new Promise(resolve => setTimeout(resolve, 100))
        }

      } catch (error) {
        console.error(`❌ Network error for token ${i + 1}:`, error)
        results.push({
          token: token.substring(0, 20) + '...',
          success: false,
          error: error.message || 'Network error'
        })
      }
    }

    // Calculate success/failure counts
    const successCount = results.filter(r => r.success).length
    const failureCount = results.length - successCount

    // Log the notification to the database for tracking
    try {
      const { error: logError } = await supabase
        .from('notifications')
        .insert({
          title,
          body,
          type: 'push_notification',
          data: JSON.stringify(data),
          sent_at: new Date().toISOString(),
          recipient_count: fcm_tokens.length,
          success_count: successCount,
          failure_count: failureCount,
          results: JSON.stringify(results)
        })

      if (logError) {
        console.warn('⚠️ Failed to log notification to database:', logError)
      } else {
        console.log('📊 Notification logged to database')
      }
    } catch (logError) {
      console.warn('⚠️ Error logging notification:', logError)
    }

    console.log(`📊 Final Results: ${successCount} successful, ${failureCount} failed`)

    return new Response(JSON.stringify({ 
      success: true, 
      message: `Push notification processed: ${successCount} successful, ${failureCount} failed`,
      summary: {
        total_tokens: fcm_tokens.length,
        successful: successCount,
        failed: failureCount,
        title,
        body,
        priority,
        timestamp: new Date().toISOString()
      },
      results
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error) {
    console.error('❌ Error in zip-push:', error)
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

// Generate OAuth 2.0 access token for Google Cloud API
async function generateAccessToken(serviceAccountEmail: string, privateKey: string): Promise<string | null> {
  try {
    // Clean up the private key format
    let cleanPrivateKey = privateKey
      .replace(/\\n/g, '\n')
      .trim()
    
    console.log('🔑 Private key format detection...')
    console.log('🔑 Key starts with:', cleanPrivateKey.substring(0, 50))
    
    // Create JWT payload
    const now = Math.floor(Date.now() / 1000)
    const payload = {
      iss: serviceAccountEmail,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      exp: now + 3600, // 1 hour from now
      iat: now
    }
    
    // Try to import the key - handle both PKCS#1 and PKCS#8 formats
    let key
    try {
      if (cleanPrivateKey.includes('-----BEGIN PRIVATE KEY-----')) {
        console.log('🔑 Detected PKCS#8 format, importing...')
        key = await importPKCS8(cleanPrivateKey, 'RS256')
        console.log('✅ PKCS#8 key imported successfully')
      } else if (cleanPrivateKey.includes('-----BEGIN RSA PRIVATE KEY-----')) {
        console.log('🔑 Detected PKCS#1 format, converting to PKCS#8...')
        const pkcs8Key = convertPKCS1ToPKCS8(cleanPrivateKey)
        key = await importPKCS8(pkcs8Key, 'RS256')
        console.log('✅ PKCS#1 key converted and imported successfully')
      } else {
        console.error('❌ Unknown private key format')
        console.error('❌ Expected either PKCS#8 (-----BEGIN PRIVATE KEY-----) or PKCS#1 (-----BEGIN RSA PRIVATE KEY-----)')
        return null
      }
    } catch (keyError) {
      console.error('❌ Failed to import private key:', keyError)
      console.error('❌ Key format issue. Please check the private key format.')
      return null
    }
    
    const jwt = await new SignJWT(payload)
      .setProtectedHeader({ alg: 'RS256' })
      .sign(key)
    
    // Exchange JWT for access token
    const tokenUrl = 'https://oauth2.googleapis.com/token'
    const response = await fetch(tokenUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: jwt
      })
    })
    
    if (!response.ok) {
      console.error('❌ Failed to get OAuth token:', await response.text())
      return null
    }
    
    const tokenData: AccessToken = await response.json()
    console.log('✅ OAuth 2.0 token generated successfully')
    return tokenData.access_token
    
  } catch (error) {
    console.error('❌ Error generating OAuth token:', error)
    return null
  }
}

// Convert PKCS#1 private key to PKCS#8 format
function convertPKCS1ToPKCS8(pkcs1Key: string): string {
  try {
    // Parse the PKCS#1 private key
    const privateKey = forge.pki.privateKeyFromPem(pkcs1Key)
    
    // Convert to PKCS#8 format
    const pkcs8Pem = forge.pki.privateKeyToAsn1(privateKey)
    const pkcs8Der = forge.asn1.toDer(pkcs8Pem).getBytes()
    const pkcs8B64 = forge.util.encode64(pkcs8Der)
    
    // Format as PEM
    const pkcs8Key = `-----BEGIN PRIVATE KEY-----\n${pkcs8B64.match(/.{1,64}/g)?.join('\n')}\n-----END PRIVATE KEY-----`
    
    console.log('🔑 Successfully converted PKCS#1 to PKCS#8')
    return pkcs8Key
  } catch (error) {
    console.error('❌ Error converting PKCS#1 to PKCS#8:', error)
    throw new Error('Failed to convert private key format')
  }
}

// Validate FCM token format
function isValidFCMToken(token: string): boolean {
  if (!token || typeof token !== 'string') {
    return false
  }
  
  // FCM tokens should be long strings (typically 140+ characters)
  // and contain only alphanumeric characters and some special chars
  if (token.length < 100 || token.length > 200) {
    console.log(`🔍 Token length validation failed: ${token.length} characters`)
    return false
  }
  
  // Check for valid characters (alphanumeric, hyphens, underscores, colons)
  const validTokenPattern = /^[a-zA-Z0-9:_-]+$/
  if (!validTokenPattern.test(token)) {
    console.log(`🔍 Token character validation failed for: ${token.substring(0, 20)}...`)
    return false
  }
  
  // Additional checks for common invalid patterns
  if (token.includes('null') || token.includes('undefined') || token === 'test_token') {
    console.log(`🔍 Token contains invalid patterns: ${token.substring(0, 20)}...`)
    return false
  }
  
  return true
}

// Clean up invalid token from database
async function cleanupInvalidToken(token: string, supabase: any): Promise<void> {
  try {
    console.log(`🗑️ Cleaning up invalid token: ${token.substring(0, 20)}...`)
    
    const { error } = await supabase
      .from('fcm_tokens')
      .delete()
      .eq('token', token)
    
    if (error) {
      console.error(`❌ Failed to delete invalid token from database: ${error.message}`)
      throw error
    }
    
    console.log(`✅ Successfully removed invalid token from database`)
  } catch (error) {
    console.error(`❌ Error cleaning up invalid token: ${error.message}`)
    throw error
  }
}
