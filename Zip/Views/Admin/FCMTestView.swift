//
//  FCMTestView.swift
//  Zip
//
//  Created by Finn McMillan on 1/20/25.
//

import SwiftUI

struct FCMTestView: View {
    @StateObject private var fcmService = FCMService.shared
    private let supabaseService = SupabaseService.shared
    @State private var testResults: [TestResult] = []
    @State private var isLoading = false
    @State private var testMessage = "Test notification from iOS app"
    @State private var testTitle = "🧪 FCM Test"
    @State private var selectedTestType: TestType = .localNotification
    
    enum TestType: String, CaseIterable {
        case localNotification = "Local Notification"
        case immediateNotification = "Immediate Notification"
        case notificationStyles = "Notification Styles"
        case checkSettings = "Check Settings"
        case fcmToken = "FCM Token"
        case registerToken = "Register Token"
        case sendTestNotification = "Send Test Notification"
        case checkPermissions = "Check Permissions"
    }
    
    struct TestResult: Identifiable {
        let id = UUID()
        let test: String
        let success: Bool
        let message: String
        let timestamp: Date
        
        init(test: String, success: Bool, message: String) {
            self.test = test
            self.success = success
            self.message = message
            self.timestamp = Date()
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // FCM Status Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("FCM Status")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        StatusRow(title: "FCM Token", value: fcmService.fcmToken?.prefix(20).appending("...") ?? "Not available")
                        StatusRow(title: "Authorized", value: fcmService.isAuthorized ? "Yes" : "No")
                        StatusRow(title: "Notifications Count", value: "\(fcmService.notifications.count)")
                        StatusRow(title: "Unread Count", value: "\(fcmService.unreadCount)")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Test Configuration
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Test Configuration")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Test Type")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Picker("Test Type", selection: $selectedTestType) {
                                ForEach(TestType.allCases, id: \.self) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notification Title")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField("Test title", text: $testTitle)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notification Message")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField("Test message", text: $testMessage, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Test Actions
                    VStack(spacing: 12) {
                        Button(action: runSelectedTest) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "play.fill")
                                }
                                Text("Run Test")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedTestType == .localNotification ? Color.blue : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isLoading)
                        
                        Button(action: runAllTests) {
                            HStack {
                                Image(systemName: "play.rectangle.fill")
                                Text("Run All Tests")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isLoading)
                        
                        Button(action: clearResults) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Clear Results")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                    
                    // Test Results
                    if !testResults.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Test Results")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            LazyVStack(spacing: 8) {
                                ForEach(testResults.reversed()) { result in
                                    TestResultRow(result: result)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("FCM Testing")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func runSelectedTest() {
        Task {
            await performTest(selectedTestType)
        }
    }
    
    private func runAllTests() {
        Task {
            for testType in TestType.allCases {
                await performTest(testType)
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            }
        }
    }
    
    private func performTest(_ testType: TestType) async {
        await MainActor.run {
            isLoading = true
        }
        
        let result: TestResult
        
        switch testType {
        case .localNotification:
            result = await testLocalNotification()
            
        case .immediateNotification:
            result = await testImmediateNotification()
            
        case .notificationStyles:
            result = await testNotificationStyles()
            
        case .checkSettings:
            result = await testCheckSettings()
            
        case .fcmToken:
            result = await testFCMToken()
            
        case .registerToken:
            result = await testTokenRegistration()
            
        case .sendTestNotification:
            result = await testFCMToken()
            
        case .checkPermissions:
            result = await testPermissions()
        }
        
        await MainActor.run {
            testResults.append(result)
            isLoading = false
        }
    }
    
    private func testLocalNotification() async -> TestResult {
        do {
            await fcmService.testLocalNotification()
            return TestResult(
                test: "Local Notification",
                success: true,
                message: "Local notification scheduled successfully"
            )
        } catch {
            return TestResult(
                test: "Local Notification",
                success: false,
                message: "Failed to schedule local notification: \(error.localizedDescription)"
            )
        }
    }
    
    private func testFCMToken() async -> TestResult {
        do {
            let token = await fcmService.getFCMToken()
            if let token = token {
                return TestResult(
                    test: "FCM Token",
                    success: true,
                    message: "FCM token retrieved: \(token.prefix(20))..."
                )
            } else {
                return TestResult(
                    test: "FCM Token",
                    success: false,
                    message: "Failed to retrieve FCM token"
                )
            }
        } catch {
            return TestResult(
                test: "FCM Token",
                success: false,
                message: "Error getting FCM token: \(error.localizedDescription)"
            )
        }
    }
    
    private func testTokenRegistration() async -> TestResult {
        do {
            await fcmService.forceRegisterFCMToken()
            return TestResult(
                test: "Token Registration",
                success: true,
                message: "FCM token registration completed"
            )
        } catch {
            return TestResult(
                test: "Token Registration",
                success: false,
                message: "Failed to register FCM token: \(error.localizedDescription)"
            )
        }
    }
    
    
    private func testPermissions() async -> TestResult {
        do {
            await fcmService.checkNotificationPermission()
            let isAuthorized = fcmService.isAuthorized
            
            return TestResult(
                test: "Check Permissions",
                success: isAuthorized,
                message: isAuthorized ? "Notification permissions granted" : "Notification permissions denied"
            )
        } catch {
            return TestResult(
                test: "Check Permissions",
                success: false,
                message: "Error checking permissions: \(error.localizedDescription)"
            )
        }
    }
    
    private func testImmediateNotification() async -> TestResult {
        do {
            await fcmService.testImmediateNotification()
            return TestResult(
                test: "Immediate Notification",
                success: true,
                message: "Immediate notification scheduled successfully"
            )
        } catch {
            return TestResult(
                test: "Immediate Notification",
                success: false,
                message: "Failed to schedule immediate notification: \(error.localizedDescription)"
            )
        }
    }
    
    private func testNotificationStyles() async -> TestResult {
        do {
            await fcmService.testNotificationStyles()
            return TestResult(
                test: "Notification Styles",
                success: true,
                message: "Multiple notification styles scheduled successfully"
            )
        } catch {
            return TestResult(
                test: "Notification Styles",
                success: false,
                message: "Failed to schedule style test notifications: \(error.localizedDescription)"
            )
        }
    }
    
    private func testCheckSettings() async -> TestResult {
        do {
            await fcmService.checkNotificationSettings()
            return TestResult(
                test: "Check Settings",
                success: true,
                message: "Notification settings checked - see console for details"
            )
        } catch {
            return TestResult(
                test: "Check Settings",
                success: false,
                message: "Error checking notification settings: \(error.localizedDescription)"
            )
        }
    }
    
    private func clearResults() {
        testResults.removeAll()
    }
}

struct StatusRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

struct TestResultRow: View {
    let result: FCMTestView.TestResult
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(result.success ? .green : .red)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(result.test)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(result.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                
                Text(result.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    FCMTestView()
}

