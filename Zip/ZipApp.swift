//
//  ZipApp.swift
//  Zip
//
//  Created by Finn McMillan on 8/19/25.
//

import SwiftUI
import Inject
import Stripe
import Firebase
import FirebaseMessaging
import UserNotifications
import UIKit

@main
struct ZipApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        #if DEBUG
        Bundle(path: "/Applications/InjectionIII.app/Contents/Resources/iOSInjection.bundle")?.load()
        #endif
        
        // Initialize Firebase
        FirebaseApp.configure()
        print("✅ Firebase initialized successfully")
        
        // Initialize Stripe publishable key
        let publishableKey = Configuration.shared.stripePublishableKey
        if !publishableKey.isEmpty && !publishableKey.contains("YOUR_") {
            STPAPIClient.shared.publishableKey = publishableKey
            print("✅ Stripe initialized with publishable key (length: \(publishableKey.count))")
        } else {
            print("⚠️ Stripe publishable key not configured. Payments will be disabled.")
        }
    }
    @ObserveInjection var inject
    
    var body: some Scene {
        
        WindowGroup {
           ContentView()
        //   ConfigurationStatusView()
                .enableInjection()  // Just once here
        }
    }
}

// MARK: - AppDelegate for APNS
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Set up UNUserNotificationCenter delegate
        UNUserNotificationCenter.current().delegate = FCMService.shared
        
        return true
    }
    
    // Handle APNS token registration
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("✅ APNS: Device token received")
        FCMService.shared.setAPNSToken(deviceToken)
    }
    
    // Handle APNS registration failure
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ APNS: Failed to register for remote notifications: \(error)")
    }
}
