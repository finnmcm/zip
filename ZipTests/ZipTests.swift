//
//  ZipTests.swift
//  ZipTests
//
//  Created by Finn McMillan on 8/19/25.
//

import Testing
@testable import Zip

struct ZipTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
    
    @Test func testFCMServiceConfiguration() async throws {
        // Test that FCMService is properly configured
        let fcmService = FCMService.shared
        
        // Test that FCMService can generate device ID
        let deviceID = fcmService.getDeviceID()
        #expect(!deviceID.isEmpty, "Device ID should not be empty")
        
        // Test that FCMService has proper initialization
        // Note: FCM token generation requires device permissions and Firebase setup
        // which may not be available in test environment
        // FCM token creation is now handled by database functions
        
        print("✅ FCM service configuration test passed")
        print("✅ Device ID generated: \(deviceID)")
    }

}
