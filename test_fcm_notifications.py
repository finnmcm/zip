#!/usr/bin/env python3
"""
FCM Notification Testing Script

This script helps you test your FCM notification system by:
1. Testing FCM token registration
2. Sending test notifications via the edge function
3. Verifying notification delivery

Usage:
    python test_fcm_notifications.py --help
    python test_fcm_notifications.py --test-token-registration
    python test_fcm_notifications.py --send-test-notification --user-id <user_id>
    python test_fcm_notifications.py --send-test-all-users
"""

import argparse
import json
import requests
import sys
from typing import Dict, Any, Optional

class FCMTester:
    def __init__(self, supabase_url: str, supabase_anon_key: str):
        self.supabase_url = supabase_url.rstrip('/')
        self.supabase_anon_key = supabase_anon_key
        self.headers = {
            'apikey': supabase_anon_key,
            'Authorization': f'Bearer {supabase_anon_key}',
            'Content-Type': 'application/json'
        }

    def test_token_registration(self) -> bool:
        """Test FCM token registration by checking the database"""
        print("🔍 Testing FCM token registration...")
        
        try:
            # Get FCM tokens from database
            response = requests.post(
                f"{self.supabase_url}/rest/v1/rpc/get_all_active_fcm_tokens",
                headers=self.headers
            )
            
            if response.status_code == 200:
                tokens = response.json()
                print(f"✅ Found {len(tokens)} active FCM tokens in database")
                
                if tokens:
                    print("\n📱 Active FCM tokens:")
                    for i, token in enumerate(tokens[:5]):  # Show first 5
                        print(f"  {i+1}. User: {token['user_id']}")
                        print(f"     Token: {token['token'][:20]}...")
                        print(f"     Device: {token['device_id']}")
                        print(f"     Platform: {token['platform']}")
                        print(f"     Updated: {token['updated_at']}")
                        print()
                else:
                    print("⚠️  No active FCM tokens found. Make sure to register tokens from your iOS app first.")
                
                return True
            else:
                print(f"❌ Failed to get FCM tokens: {response.status_code}")
                print(f"Response: {response.text}")
                return False
                
        except Exception as e:
            print(f"❌ Error testing token registration: {e}")
            return False

    def send_test_notification(self, user_id: Optional[str] = None, test_all_users: bool = False) -> bool:
        """Send a test notification via the edge function"""
        print(f"📤 Sending test notification...")
        if user_id:
            print(f"   Target: User {user_id}")
        elif test_all_users:
            print(f"   Target: All users")
        else:
            print("❌ Either user_id or test_all_users must be specified")
            return False

        # Prepare notification payload
        payload = {
            "title": "🧪 Test Notification",
            "body": "This is a test notification from the FCM testing script",
            "type": "test",
            "data": {
                "test_id": f"test_{int(__import__('time').time())}",
                "source": "testing_script"
            }
        }

        if user_id:
            payload["user_id"] = user_id
        if test_all_users:
            payload["test_all_users"] = True

        try:
            # Call the edge function
            response = requests.post(
                f"{self.supabase_url}/functions/v1/send-test-notification",
                headers=self.headers,
                json=payload
            )

            if response.status_code == 200:
                result = response.json()
                print("✅ Test notification sent successfully!")
                print(f"   Message: {result.get('message', 'No message')}")
                
                if 'results' in result:
                    print(f"   Sent to {len(result['results'])} device(s)")
                    for i, res in enumerate(result['results'][:3]):  # Show first 3
                        print(f"     {i+1}. Device: {res['device_id']} ({res['platform']})")
                        print(f"        Token: {res['token']}")
                
                if 'summary' in result:
                    summary = result['summary']
                    print(f"\n📊 Summary:")
                    print(f"   Total tokens: {summary.get('total_tokens', 'N/A')}")
                    print(f"   Type: {summary.get('notification_type', 'N/A')}")
                    print(f"   Title: {summary.get('title', 'N/A')}")
                    print(f"   Body: {summary.get('body', 'N/A')}")
                
                return True
            else:
                print(f"❌ Failed to send test notification: {response.status_code}")
                print(f"Response: {response.text}")
                return False

        except Exception as e:
            print(f"❌ Error sending test notification: {e}")
            return False

    def test_edge_function_health(self) -> bool:
        """Test if the edge function is deployed and accessible"""
        print("🔍 Testing edge function health...")
        
        try:
            # Try to call the edge function with a simple request
            response = requests.post(
                f"{self.supabase_url}/functions/v1/send-test-notification",
                headers=self.headers,
                json={"test": "health_check"}
            )
            
            # We expect a 400 error for missing required fields, which means the function is working
            if response.status_code in [200, 400]:
                print("✅ Edge function is accessible")
                return True
            else:
                print(f"❌ Edge function returned unexpected status: {response.status_code}")
                print(f"Response: {response.text}")
                return False
                
        except Exception as e:
            print(f"❌ Error testing edge function: {e}")
            return False

    def get_user_fcm_tokens(self, user_id: str) -> bool:
        """Get FCM tokens for a specific user"""
        print(f"🔍 Getting FCM tokens for user: {user_id}")
        
        try:
            response = requests.post(
                f"{self.supabase_url}/rest/v1/rpc/get_user_fcm_tokens",
                headers=self.headers,
                json={"p_user_id": user_id}
            )
            
            if response.status_code == 200:
                tokens = response.json()
                print(f"✅ Found {len(tokens)} FCM tokens for user {user_id}")
                
                for i, token in enumerate(tokens):
                    print(f"  {i+1}. Token: {token['token'][:20]}...")
                    print(f"     Device: {token['device_id']}")
                    print(f"     Platform: {token['platform']}")
                    print(f"     App Version: {token['app_version']}")
                    print(f"     Updated: {token['updated_at']}")
                    print()
                
                return True
            else:
                print(f"❌ Failed to get user FCM tokens: {response.status_code}")
                print(f"Response: {response.text}")
                return False
                
        except Exception as e:
            print(f"❌ Error getting user FCM tokens: {e}")
            return False

def main():
    parser = argparse.ArgumentParser(description='Test FCM notification system')
    parser.add_argument('--supabase-url', required=True, help='Supabase project URL')
    parser.add_argument('--supabase-key', required=True, help='Supabase anon key')
    parser.add_argument('--test-token-registration', action='store_true', 
                       help='Test FCM token registration')
    parser.add_argument('--test-edge-function', action='store_true',
                       help='Test edge function health')
    parser.add_argument('--send-test-notification', action='store_true',
                       help='Send a test notification')
    parser.add_argument('--user-id', help='User ID for targeted notification')
    parser.add_argument('--test-all-users', action='store_true',
                       help='Send test notification to all users')
    parser.add_argument('--get-user-tokens', help='Get FCM tokens for specific user ID')
    parser.add_argument('--run-all-tests', action='store_true',
                       help='Run all available tests')

    args = parser.parse_args()

    # Initialize tester
    tester = FCMTester(args.supabase_url, args.supabase_key)

    success_count = 0
    total_tests = 0

    if args.run_all_tests:
        print("🚀 Running all FCM tests...\n")
        
        # Test edge function health
        total_tests += 1
        if tester.test_edge_function_health():
            success_count += 1
        print()

        # Test token registration
        total_tests += 1
        if tester.test_token_registration():
            success_count += 1
        print()

        # Send test notification to all users
        total_tests += 1
        if tester.send_test_notification(test_all_users=True):
            success_count += 1
        print()

    else:
        # Run individual tests
        if args.test_edge_function:
            total_tests += 1
            if tester.test_edge_function_health():
                success_count += 1

        if args.test_token_registration:
            total_tests += 1
            if tester.test_token_registration():
                success_count += 1

        if args.send_test_notification:
            total_tests += 1
            if tester.send_test_notification(user_id=args.user_id, test_all_users=args.test_all_users):
                success_count += 1

        if args.get_user_tokens:
            total_tests += 1
            if tester.get_user_fcm_tokens(args.get_user_tokens):
                success_count += 1

    # Print summary
    print(f"\n📊 Test Results: {success_count}/{total_tests} tests passed")
    
    if success_count == total_tests:
        print("🎉 All tests passed!")
        sys.exit(0)
    else:
        print("❌ Some tests failed. Check the output above for details.")
        sys.exit(1)

if __name__ == "__main__":
    main()
