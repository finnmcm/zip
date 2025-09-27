//
//  FCMService.swift
//  Zip
//
//  Created by Finn McMillan on 1/20/25.
//

import Foundation
import UserNotifications
import Firebase
import FirebaseMessaging
import UIKit  // Add this import

/// Service for handling Firebase Cloud Messaging (FCM) operations
@MainActor
final class FCMService: NSObject, ObservableObject {
    
    // MARK: - Singleton
    static let shared = FCMService()
    
    // MARK: - Published Properties
    @Published var fcmToken: String?
    @Published var isAuthorized: Bool = false
    @Published var notificationSettings = NotificationSettings()
    @Published var notifications: [ZipNotification] = []
    @Published var unreadCount: Int = 0
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let supabaseService = SupabaseService.shared
    private let authService = AuthenticationService.shared
    private let keychainService = KeychainService.shared
    private var apnsToken: Data?
    
    // MARK: - Constants
    private enum Keys {
        static let fcmToken = "fcm_token"
        static let notificationSettings = "notification_settings"
        static let notifications = "stored_notifications"
        static let deviceID = "device_id"
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
        print("🔍 DEBUG: FCMService init - logging is working!")
        setupFCM()
        loadStoredData()
        setupPeriodicTokenRefresh()
    }
    
    // MARK: - Setup
    private func setupFCM() {
        print("🔧 FCM: Setting up FCM service...")
        
        // Set up FCM delegate
        Messaging.messaging().delegate = self
        print("✅ FCM: FCM delegate set")
        
        // Set up UNUserNotificationCenter delegate
        UNUserNotificationCenter.current().delegate = self
        print("✅ FCM: UNUserNotificationCenter delegate set")
        
        // Configure FCM
        Messaging.messaging().isAutoInitEnabled = true
        print("✅ FCM: FCM auto-init enabled")
        
        // Check FCM configuration
        print("🔍 FCM: Checking FCM configuration...")
        print("🔍 FCM: FCM isAutoInitEnabled: \(Messaging.messaging().isAutoInitEnabled)")
        
        print("🎯 FCM: FCM setup completed successfully")
    }
    
    private func setupPeriodicTokenRefresh() {
        print("⏰ FCM: Setting up periodic token refresh...")
        
        // Check if we need to refresh token (monthly)
        let lastRefreshKey = "fcm_last_refresh"
        let lastRefresh = userDefaults.object(forKey: lastRefreshKey) as? Date ?? Date.distantPast
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        
        if lastRefresh < oneMonthAgo {
            print("⏰ FCM: Token is older than 1 month, scheduling refresh...")
            Task {
                await refreshFCMToken()
                userDefaults.set(Date(), forKey: lastRefreshKey)
            }
        } else {
            print("⏰ FCM: Token is still fresh (last refresh: \(lastRefresh))")
        }
    }
    
    // MARK: - Permission Management
    func requestNotificationPermission() async -> Bool {
        print("🔔 FCM: Requesting notification permission...")
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound, .provisional]
            )
            
            print("🔔 FCM: Permission request result: \(granted)")
            
            await MainActor.run {
                self.isAuthorized = granted
            }
            print("🔔 FCM: isAuthorized set to: \(granted)")
            
            if granted {
                print("🔔 FCM: Permission granted, registering for remote notifications...")
                await registerForRemoteNotifications()
            } else {
                print("⚠️ FCM: Permission denied by user")
            }
            
            return granted
        } catch {
            print("❌ FCM: Failed to request notification permission: \(error)")
            print("❌ FCM: Error type: \(type(of: error))")
            return false
        }
    }
    
    private func registerForRemoteNotifications() async {
        print("📱 FCM: Registering for remote notifications...")
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
        print("✅ FCM: Remote notification registration initiated")
    }
    
    // MARK: - APNS Token Management
    func setAPNSToken(_ token: Data) {
        self.apnsToken = token
        print("✅ FCM: APNS token received: \(token.map { String(format: "%02x", $0) }.joined())")
        
        // Set APNS token for FCM
        Messaging.messaging().apnsToken = token
        print("✅ FCM: APNS token set for Firebase Messaging")
    }
    
    func checkNotificationPermission() async {
        print("🔍 FCM: Checking current notification permission status...")
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        print("🔍 FCM: Current authorization status: \(settings.authorizationStatus.rawValue)")
        print("🔍 FCM: Alert setting: \(settings.alertSetting.rawValue)")
        print("🔍 FCM: Badge setting: \(settings.badgeSetting.rawValue)")
        print("🔍 FCM: Sound setting: \(settings.soundSetting.rawValue)")
        
        await MainActor.run {
            self.isAuthorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
        }
        print("🔍 FCM: isAuthorized updated to: \(isAuthorized)")
    }
    
    // MARK: - Token Management
    func getFCMToken() async -> String? {
        // Check if we have APNS token first
        if apnsToken == nil {
            print("❌ FCM: No APNS token available. Requesting notification permission first...")
            
            // Request notification permission and APNS token
            let hasPermission = await requestNotificationPermission()
            if !hasPermission {
                print("❌ FCM: Notification permission denied")
                return nil
            }
            
            // Wait a bit for APNS token to be received
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            // Check again if we have APNS token after requesting permission
            if apnsToken == nil {
                print("❌ FCM: Still no APNS token after requesting permission")
                return nil
            }
        }
        
        do {
            let token = try await Messaging.messaging().token()
            await MainActor.run {
                self.fcmToken = token
            }
            print("✅ FCM: Successfully retrieved FCM token")
            print("🔍 FCM: Full FCM token for testing: \(token)")
            return token
        } catch {
            print("❌ FCM: Failed to get FCM token: \(error)")
            return nil
        }
    }
    
    func refreshFCMToken() async {
        print("🔄 FCM: Refreshing FCM token...")
        do {
            print("🔄 FCM: Deleting current FCM token...")
            try await Messaging.messaging().deleteToken()
            print("✅ FCM: Current token deleted")
            
            print("🔄 FCM: Requesting new FCM token...")
            let newToken = try await Messaging.messaging().token()
            print("✅ FCM: New token received: \(newToken.prefix(20))...")
            
            await MainActor.run {
                self.fcmToken = newToken
            }
            print("✅ FCM: fcmToken property updated")
            
            print("🔄 FCM: Registering new token with Supabase...")
            await registerTokenWithSupabase(newToken)
            
            // Update last refresh timestamp
            userDefaults.set(Date(), forKey: "fcm_last_refresh")
            print("✅ FCM: Token refresh timestamp updated")
        } catch {
            print("❌ FCM: Failed to refresh FCM token: \(error)")
            print("❌ FCM: Error type: \(type(of: error))")
        }
    }
    
    private func registerTokenWithSupabase(_ token: String) async {
        do {
            print("🔍 FCM: Attempting to get current user for token registration...")
            guard let user = try await authService.getCurrentUser() else {
                print("⚠️ FCM: No authenticated user to register token with")
                return
            }
            
            print("👤 FCM: Registering token for user: \(user.email)")
            print("👤 FCM: User ID: \(user.id)")
            
            // Get device ID and app version
            let deviceID = getDeviceID()
            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
            
            print("📱 FCM: Device ID: \(deviceID)")
            print("📱 FCM: App Version: \(appVersion)")
            print("🎯 FCM: Token: \(token.prefix(20))...")
            
            // Call the Supabase service to register the FCM token
            print("🔄 FCM: Calling supabaseService.registerFCMToken...")
            print("🔍 FCM: SupabaseService client configured: \(supabaseService.isClientConfigured)")
            let success = try await supabaseService.registerFCMToken(
                token: token,
                deviceId: deviceID,
                platform: "ios",
                appVersion: appVersion
            )
            
            if success {
                print("✅ FCM: Token registered successfully with Supabase")
            } else {
                print("❌ FCM: Token registration returned false")
            }
        } catch {
            print("❌ FCM: Failed to register token with Supabase: \(error)")
            print("❌ FCM: Error details: \(error.localizedDescription)")
            print("❌ FCM: Error type: \(type(of: error))")
            
        }
    }
    
    func getDeviceID() -> String {
        print("📱 FCM: Getting device ID...")
        if let deviceID = userDefaults.string(forKey: Keys.deviceID) {
            print("📱 FCM: Found existing device ID: \(deviceID)")
            return deviceID
        }
        
        print("📱 FCM: No existing device ID, generating new one...")
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        print("📱 FCM: Generated device ID: \(deviceID)")
        userDefaults.set(deviceID, forKey: Keys.deviceID)
        print("📱 FCM: Device ID saved to UserDefaults")
        return deviceID
    }
    
    // MARK: - Notification Handling
    func handleNotification(_ userInfo: [AnyHashable: Any]) {
        print("📨 FCM: ===== NOTIFICATION RECEIVED =====")
        print("📨 FCM: Full userInfo: \(userInfo)")
        print("📨 FCM: App state: \(UIApplication.shared.applicationState.rawValue)")
        
        let title: String
        let body: String
        
        // Check if this is a remote notification with APS data
        if let aps = userInfo["aps"] as? [String: Any] {
            print("📨 FCM: APS data found: \(aps)")
            
            // Extract title and body from APS alert
            if let alert = aps["alert"] as? [String: Any] {
                title = alert["title"] as? String ?? "Zip"
                body = alert["body"] as? String ?? ""
                print("📨 FCM: Extracted from APS alert - title: \(title), body: \(body)")
            } else {
                title = userInfo["title"] as? String ?? "Zip"
                body = userInfo["body"] as? String ?? ""
                print("📨 FCM: Extracted from userInfo - title: \(title), body: \(body)")
            }
        } else {
            print("📨 FCM: No APS data - treating as local notification")
            print("📨 FCM: Available keys: \(userInfo.keys)")
            
            // For local notifications, extract directly from userInfo
            title = userInfo["title"] as? String ?? "Zip"
            body = userInfo["body"] as? String ?? ""
            print("📨 FCM: Extracted from userInfo - title: \(title), body: \(body)")
        }
        
        let typeString = userInfo["type"] as? String ?? "general"
        let type = NotificationType(rawValue: typeString) ?? .general
        print("📨 FCM: Notification type: \(typeString) -> \(type)")
        
        // Extract custom data
        var data: [String: String] = [:]
        for (key, value) in userInfo {
            let keyString = String(describing: key)
            if keyString != "aps" && keyString != "title" && keyString != "body" && keyString != "type" {
                data[keyString] = String(describing: value)
            }
        }
        print("📨 FCM: Custom data extracted: \(data)")
        
        let notification = ZipNotification(
            title: title,
            body: body,
            data: data,
            type: type
        )
        print("📨 FCM: Created ZipNotification: \(notification)")
        
        addNotification(notification)
    }
    
    private func addNotification(_ notification: ZipNotification) {
        print("📨 FCM: Adding notification to list...")
        notifications.insert(notification, at: 0)
        print("📨 FCM: Notification added at index 0. Total notifications: \(notifications.count)")
        updateUnreadCount()
        saveNotifications()
        print("📨 FCM: Notification saved to UserDefaults")
    }
    
    func markAsRead(_ notification: ZipNotification) {
        print("📨 FCM: Marking notification as read: \(notification.id)")
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            print("📨 FCM: Found notification at index: \(index)")
            notifications[index] = ZipNotification(
                id: notification.id,
                title: notification.title,
                body: notification.body,
                data: notification.data,
                timestamp: notification.timestamp,
                type: notification.type,
                isRead: true
            )
            print("📨 FCM: Notification marked as read")
            updateUnreadCount()
            saveNotifications()
            print("📨 FCM: Updated notification saved to UserDefaults")
        } else {
            print("⚠️ FCM: Notification not found in list: \(notification.id)")
        }
    }
    
    func markAllAsRead() {
        print("📨 FCM: Marking all notifications as read...")
        print("📨 FCM: Total notifications to mark: \(notifications.count)")
        for i in 0..<notifications.count {
            notifications[i] = ZipNotification(
                id: notifications[i].id,
                title: notifications[i].title,
                body: notifications[i].body,
                data: notifications[i].data,
                timestamp: notifications[i].timestamp,
                type: notifications[i].type,
                isRead: true
            )
        }
        print("📨 FCM: All notifications marked as read")
        updateUnreadCount()
        saveNotifications()
        print("📨 FCM: Updated notifications saved to UserDefaults")
    }
    
    func clearAllNotifications() {
        print("📨 FCM: Clearing all notifications...")
        print("📨 FCM: Current notification count: \(notifications.count)")
        notifications.removeAll()
        print("📨 FCM: All notifications cleared")
        updateUnreadCount()
        saveNotifications()
        print("📨 FCM: Empty notification list saved to UserDefaults")
    }
    
    func removeNotification(withId id: String) {
        print("📨 FCM: Removing notification with ID: \(id)")
        print("📨 FCM: Current notification count: \(notifications.count)")
        notifications.removeAll { $0.id == id }
        print("📨 FCM: Notification removed. New count: \(notifications.count)")
        updateUnreadCount()
        saveNotifications()
        print("📨 FCM: Updated notification list saved to UserDefaults")
    }
    
    private func updateUnreadCount() {
        let previousCount = unreadCount
        unreadCount = notifications.filter { !$0.isRead }.count
        print("📨 FCM: Updated unread count: \(previousCount) -> \(unreadCount)")
    }
    
    // MARK: - Settings Management
    func updateNotificationSettings(_ settings: NotificationSettings) {
        print("⚙️ FCM: Updating notification settings...")
        print("⚙️ FCM: New settings: \(settings)")
        notificationSettings = settings
        saveNotificationSettings()
        print("⚙️ FCM: Notification settings updated and saved")
    }
    
    func toggleNotificationType(_ type: NotificationType) {
        print("⚙️ FCM: Toggling notification type: \(type)")
        let currentValue = notificationSettings.isEnabled(for: type)
        print("⚙️ FCM: Current value for \(type): \(currentValue)")
        notificationSettings.setEnabled(!currentValue, for: type)
        print("⚙️ FCM: New value for \(type): \(!currentValue)")
        saveNotificationSettings()
        print("⚙️ FCM: Notification settings saved")
    }
    
    // MARK: - Data Persistence
    private func loadStoredData() {
        print("💾 FCM: Loading stored data from UserDefaults...")
        
        // Load FCM token
        fcmToken = userDefaults.string(forKey: Keys.fcmToken)
        if fcmToken != nil {
            print("💾 FCM: Loaded stored FCM token: \(fcmToken!.prefix(20))...")
        } else {
            print("💾 FCM: No stored FCM token found")
        }
        
        // Load notification settings
        if let settingsData = userDefaults.data(forKey: Keys.notificationSettings),
           let settings = try? JSONDecoder().decode(NotificationSettings.self, from: settingsData) {
            notificationSettings = settings
            print("💾 FCM: Loaded notification settings: \(settings)")
        } else {
            print("💾 FCM: No stored notification settings found")
        }
        
        // Load stored notifications
        if let notificationsData = userDefaults.data(forKey: Keys.notifications),
           let storedNotifications = try? JSONDecoder().decode([ZipNotification].self, from: notificationsData) {
            notifications = storedNotifications
            print("💾 FCM: Loaded \(storedNotifications.count) stored notifications")
            updateUnreadCount()
        } else {
            print("💾 FCM: No stored notifications found")
        }
        
        print("💾 FCM: Data loading completed")
    }
    
    private func saveNotifications() {
        print("💾 FCM: Saving \(notifications.count) notifications to UserDefaults...")
        if let data = try? JSONEncoder().encode(notifications) {
            userDefaults.set(data, forKey: Keys.notifications)
            print("💾 FCM: Notifications saved successfully")
        } else {
            print("❌ FCM: Failed to encode notifications for saving")
        }
    }
    
    private func saveNotificationSettings() {
        print("💾 FCM: Saving notification settings to UserDefaults...")
        if let data = try? JSONEncoder().encode(notificationSettings) {
            userDefaults.set(data, forKey: Keys.notificationSettings)
            print("💾 FCM: Notification settings saved successfully")
        } else {
            print("❌ FCM: Failed to encode notification settings for saving")
        }
    }
    
    // MARK: - Authentication Integration
    func onUserLogin() async {
        print("🔄 FCM: onUserLogin called")
        
        // First, request notification permissions
        let hasPermission = await requestNotificationPermission()
        print("🔔 FCM: Notification permission granted: \(hasPermission)")
        
        // Get FCM token and register with Supabase
        if let token = await getFCMToken() {
            print("🎯 FCM: Got token, registering with Supabase: \(token.prefix(20))...")
            await registerTokenWithSupabase(token)
        } else {
            print("❌ FCM: Failed to get FCM token")
        }
    }
    
    /// Manual method to force FCM token registration (for debugging)
    func forceRegisterFCMToken() async {
        print("🔄 FCM: Force registering FCM token...")
        await onUserLogin()
    }
    
    func onUserLogout() {
        print("🚪 FCM: onUserLogout called")
        print("🚪 FCM: Clearing local notifications and resetting token...")
        
        // Clear local notifications and reset token
        print("🚪 FCM: Current notification count: \(notifications.count)")
        notifications.removeAll()
        print("🚪 FCM: Notifications cleared")
        
        unreadCount = 0
        print("🚪 FCM: Unread count reset to 0")
        
        fcmToken = nil
        print("🚪 FCM: FCM token cleared")
        
        userDefaults.removeObject(forKey: Keys.fcmToken)
        print("🚪 FCM: FCM token removed from UserDefaults")
        
        saveNotifications()
        print("🚪 FCM: Empty notification list saved")
        print("🚪 FCM: User logout cleanup completed")
    }
}

// MARK: - MessagingDelegate
extension FCMService: MessagingDelegate {
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("🔄 FCM: MessagingDelegate - Received registration token: \(fcmToken ?? "nil")")
        
        Task { @MainActor in
            print("🔄 FCM: MessagingDelegate - Updating fcmToken property...")
            self.fcmToken = fcmToken
            
            if let token = fcmToken {
                print("🔄 FCM: MessagingDelegate - Saving token to UserDefaults...")
                userDefaults.set(token, forKey: Keys.fcmToken)
                print("🔄 FCM: MessagingDelegate - Registering token with Supabase...")
                await registerTokenWithSupabase(token)
            } else {
                print("⚠️ FCM: MessagingDelegate - No token received")
            }
        }
    }
    
}

// MARK: - UNUserNotificationCenterDelegate
extension FCMService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("📨 FCM: ===== FOREGROUND NOTIFICATION =====")
        print("📨 FCM: Notification received while app is in foreground")
        print("📨 FCM: Notification content: \(notification.request.content)")
        
        // Handle notification when app is in foreground
        let userInfo = notification.request.content.userInfo
        Task { @MainActor in
            handleNotification(userInfo)
        }
        
        // Show notification even when app is in foreground
        print("📨 FCM: Showing notification with banner, badge, and sound")
        print("📨 FCM: Notification title: \(notification.request.content.title)")
        print("📨 FCM: Notification body: \(notification.request.content.body)")
        print("📨 FCM: Notification badge: \(notification.request.content.badge?.intValue ?? 0)")
        print("📨 FCM: Notification sound: \(notification.request.content.sound?.description ?? "none")")
        
        // Use the most permissive presentation options
        // Note: In iOS 14+, we need to use the new presentation options
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .badge, .sound, .list])
        } else {
            completionHandler([.alert, .badge, .sound])
        }
    }
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("📨 FCM: ===== NOTIFICATION TAPPED =====")
        print("📨 FCM: User tapped on notification")
        print("📨 FCM: Response action: \(response.actionIdentifier)")
        
        // Handle notification tap
        let userInfo = response.notification.request.content.userInfo
        Task { @MainActor in
            handleNotification(userInfo)
            
            // Mark as read when tapped
            if let notification = notifications.first {
                markAsRead(notification)
            }
        }
        
        completionHandler()
    }
}

// MARK: - Helper Extensions
extension FCMService {
    /// Get notifications filtered by type
    func notifications(for type: NotificationType) -> [ZipNotification] {
        return notifications.filter { $0.type == type }
    }
    
    /// Get unread notifications
    var unreadNotifications: [ZipNotification] {
        return notifications.filter { !$0.isRead }
    }
    
    /// Check if notifications are enabled for a specific type
    func isEnabled(for type: NotificationType) -> Bool {
        return notificationSettings.isEnabled(for: type)
    }
    
    /// Check notification settings and provide detailed feedback
    func checkNotificationSettings() async {
        print("🔍 FCM: Checking notification settings...")
        
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        print("🔍 FCM: Current notification settings:")
        print("  - Authorization: \(settings.authorizationStatus.rawValue)")
        print("  - Alert: \(settings.alertSetting.rawValue)")
        print("  - Badge: \(settings.badgeSetting.rawValue)")
        print("  - Sound: \(settings.soundSetting.rawValue)")
        print("  - Lock Screen: \(settings.lockScreenSetting.rawValue)")
        print("  - Notification Center: \(settings.notificationCenterSetting.rawValue)")
        print("  - Car Play: \(settings.carPlaySetting.rawValue)")
        print("  - Critical Alert: \(settings.criticalAlertSetting.rawValue)")
        print("  - Announcement: \(settings.announcementSetting.rawValue)")
        print("  - App state: \(UIApplication.shared.applicationState.rawValue)")
        
        // Check if notifications will work
        if settings.authorizationStatus == .denied {
            print("❌ FCM: Notifications are denied by user")
        } else if settings.authorizationStatus == .notDetermined {
            print("⚠️ FCM: Notification permission not determined")
        } else if settings.alertSetting == .disabled {
            print("⚠️ FCM: Alert notifications are disabled")
        } else {
            print("✅ FCM: Notifications should work properly")
        }
    }
    
    /// Test local notification to verify notification system works
    func testLocalNotification() async {
        print("🔔 FCM: Testing local notification...")
        
        // Check current notification settings
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        print("🔔 FCM: Current notification settings:")
        print("  - Authorization: \(settings.authorizationStatus.rawValue)")
        print("  - Alert: \(settings.alertSetting.rawValue)")
        print("  - Badge: \(settings.badgeSetting.rawValue)")
        print("  - Sound: \(settings.soundSetting.rawValue)")
        print("  - App state: \(UIApplication.shared.applicationState.rawValue)")
        
        // Check if notifications are properly configured
        if settings.authorizationStatus != .authorized && settings.authorizationStatus != .provisional {
            print("⚠️ FCM: Notifications not authorized. Status: \(settings.authorizationStatus.rawValue)")
            return
        }
        
        if settings.alertSetting == .disabled {
            print("⚠️ FCM: Alert notifications are disabled")
        }
        
        if settings.badgeSetting == .disabled {
            print("⚠️ FCM: Badge notifications are disabled")
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Test Local Notification"
        content.body = "This is a test to verify notification system works"
        content.sound = .default
        content.badge = 1
        
        // Add userInfo data to simulate a real notification
        content.userInfo = [
            "title": "Test Local Notification",
            "body": "This is a test to verify notification system works",
            "type": "test",
            "aps": [
                "alert": [
                    "title": "Test Local Notification",
                    "body": "This is a test to verify notification system works"
                ],
                "badge": 1,
                "sound": "default"
            ]
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "test-notification", content: content, trigger: trigger)
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ FCM: Local notification scheduled successfully")
            print("🔔 FCM: Notification will appear in 1 second...")
            
            // Check if the notification was actually scheduled
            let pendingRequests = await UNUserNotificationCenter.current().pendingNotificationRequests()
            print("📋 FCM: Pending notifications: \(pendingRequests.count)")
            for request in pendingRequests {
                print("📋 FCM: Pending - ID: \(request.identifier), Title: \(request.content.title)")
            }
            
        } catch {
            print("❌ FCM: Failed to schedule local notification: \(error)")
        }
    }
    
    /// Test immediate notification (no delay) to see if it appears
    func testImmediateNotification() async {
        print("🔔 FCM: Testing immediate notification...")
        
        await checkNotificationSettings()
        
        let content = UNMutableNotificationContent()
        content.title = "Immediate Test"
        content.body = "This should appear immediately"
        content.sound = .default
        content.badge = 1
        
        // Add userInfo data
        content.userInfo = [
            "title": "Immediate Test",
            "body": "This should appear immediately",
            "type": "test",
            "aps": [
                "alert": [
                    "title": "Immediate Test",
                    "body": "This should appear immediately"
                ],
                "badge": 1,
                "sound": "default"
            ]
        ]
        
        // Create immediate trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: "immediate-test-\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ FCM: Immediate notification scheduled successfully")
            print("🔔 FCM: Notification should appear in 0.1 seconds...")
        } catch {
            print("❌ FCM: Failed to schedule immediate notification: \(error)")
        }
    }
    
    /// Test notification with different presentation styles
    func testNotificationStyles() async {
        print("🔔 FCM: Testing different notification styles...")
        
        // Test 1: Basic notification
        let content1 = UNMutableNotificationContent()
        content1.title = "Style Test 1"
        content1.body = "Basic notification"
        content1.sound = .default
        content1.badge = 1
        
        let trigger1 = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let request1 = UNNotificationRequest(identifier: "style-test-1", content: content1, trigger: trigger1)
        
        // Test 2: Notification with subtitle
        let content2 = UNMutableNotificationContent()
        content2.title = "Style Test 2"
        content2.subtitle = "With Subtitle"
        content2.body = "This notification has a subtitle"
        content2.sound = .default
        content2.badge = 2
        
        let trigger2 = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
        let request2 = UNNotificationRequest(identifier: "style-test-2", content: content2, trigger: trigger2)
        
        // Test 3: Notification with custom sound
        let content3 = UNMutableNotificationContent()
        content3.title = "Style Test 3"
        content3.body = "With custom sound"
        content3.sound = .default
        content3.badge = 3
        
        let trigger3 = UNTimeIntervalNotificationTrigger(timeInterval: 1.5, repeats: false)
        let request3 = UNNotificationRequest(identifier: "style-test-3", content: content3, trigger: trigger3)
        
        do {
            try await UNUserNotificationCenter.current().add(request1)
            try await UNUserNotificationCenter.current().add(request2)
            try await UNUserNotificationCenter.current().add(request3)
            print("✅ FCM: All style test notifications scheduled successfully")
            print("🔔 FCM: Notifications will appear at 0.5s, 1.0s, and 1.5s...")
        } catch {
            print("❌ FCM: Failed to schedule style test notifications: \(error)")
        }
    }
}
