//
//  AuthViewModel.swift
//  Zip
//

import Foundation
import SwiftUI

@MainActor
final class AuthViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var phoneNumber: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentUser: User?
    @Published var isSignUpMode: Bool = false
    @Published var isAuthenticated: Bool = false
    @Published var rememberMe: Bool = false
    
    // MARK: - Callbacks
    var onAuthenticationSuccess: (() -> Void)?
    var onEmailVerificationSuccess: (() -> Void)?

    // MARK: - Services
    private let authService = AuthenticationService.shared
    private let keychainService = KeychainService.shared
    private let fcmService = FCMService.shared
    
    // MARK: - Verification Status Checking
    private var verificationCheckTimer: Timer?
    
    // MARK: - Initialization
    init() {
        Task {
            await checkCurrentUser()
            loadSavedCredentials()
        }
    }
    
    // MARK: - Validation Logic
    var isValidEmail: Bool {
        email.isValidNorthwesternEmail
    }
    
    var isValidPassword: Bool {
        password.isValidPassword
    }
    
    var doPasswordsMatch: Bool {
        password == confirmPassword
    }
    
    var isValidPhoneNumber: Bool {
        phoneNumber.isValidPhoneNumber
    }
    
    var isValidSignUp: Bool {
        isValidEmail && 
        isValidPassword && 
        doPasswordsMatch && 
        !firstName.isEmptyOrWhitespace && 
        !lastName.isEmptyOrWhitespace && 
        isValidPhoneNumber
    }
    
    var isValidLogin: Bool {
        isValidEmail && !password.isEmpty
    }
    
    // MARK: - Authentication Methods
    func signUp() async {
        guard isValidSignUp else {
            errorMessage = "Please fill in all fields correctly"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let user = try await authService.signUp(
                email: email.trimmed,
                password: password,
                firstName: firstName.trimmed,
                lastName: lastName.trimmed,
                phoneNumber: phoneNumber.trimmed
            )
            
            currentUser = user
            isAuthenticated = true
            clearForm()
            errorMessage = nil
            
            print("✅ User signed up successfully: \(user.email)")
            
            // Initialize FCM for the authenticated user
            await fcmService.onUserLogin()
            
            // Start periodic verification checking for unverified users
            if !user.verified {
                startVerificationStatusChecking()
            }
            
            // Notify that authentication was successful
            onAuthenticationSuccess?()
            
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
            print("❌ Signup error: \(error)")
        } catch {
            errorMessage = "An unexpected error occurred. Please try again."
            print("❌ Unexpected signup error: \(error)")
        }
    }
    
    func login() async {
        guard isValidLogin else {
            errorMessage = "Please enter a valid Northwestern email and password"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let user = try await authService.signIn(
                email: email.trimmed,
                password: password
            )
            
            currentUser = user
            isAuthenticated = true
            errorMessage = nil
            
            // Save credentials to keychain if remember me is enabled
            if rememberMe {
                _ = keychainService.saveCredentials(
                    email: email.trimmed,
                    password: password,
                    rememberMe: true
                )
            } else {
                // Clear any existing saved credentials
                _ = keychainService.clearCredentials()
            }
            
            clearForm()
            
            print("✅ User signed in successfully: \(user.email)")
            
            // Initialize FCM for the authenticated user
            await fcmService.onUserLogin()
            
            // Start periodic verification checking for unverified users
            if !user.verified {
                startVerificationStatusChecking()
            }
            
            // Notify that authentication was successful
            onAuthenticationSuccess?()
            
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
            print("❌ Signin error: \(error)")
        } catch {
            errorMessage = "An unexpected error occurred. Please try again."
            print("❌ Unexpected signin error: \(error)")
        }
    }
    
    func logout() async {
        do {
            try await authService.signOut()
            currentUser = nil
            isAuthenticated = false
            
            // Clear saved credentials on logout
            _ = keychainService.clearCredentials()
            rememberMe = false
            
            // Stop verification checking
            stopVerificationStatusChecking()
            
            // Clean up FCM for the logged out user
            fcmService.onUserLogout()
            
            print("✅ User signed out successfully")
        } catch {
            print("❌ Signout error: \(error)")
            // Even if signout fails, clear local state
            currentUser = nil
            isAuthenticated = false
            _ = keychainService.clearCredentials()
            rememberMe = false
            
            // Stop verification checking
            stopVerificationStatusChecking()
        }
    }
    
    func resetPassword() async {
        guard isValidEmail else {
            errorMessage = "Please enter a valid Northwestern email address"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await authService.resetPassword(email: email.trimmed)
            errorMessage = "Password reset email sent to \(email)"
            print("✅ Password reset email sent successfully")
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
            print("❌ Password reset error: \(error)")
        } catch {
            errorMessage = "An unexpected error occurred. Please try again."
            print("❌ Unexpected password reset error: \(error)")
        }
    }
    
    func updateProfile() async {
        guard let user = currentUser else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let updatedUser = try await authService.updateProfile(user)
            currentUser = updatedUser
            errorMessage = nil
            print("✅ Profile updated successfully")
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
            print("❌ Profile update error: \(error)")
        } catch {
            errorMessage = "An unexpected error occurred. Please try again."
            print("❌ Unexpected profile update error: \(error)")
        }
    }
    
    // MARK: - UI State Management
    func toggleMode() {
        isSignUpMode.toggle()
        clearForm()
        errorMessage = nil
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    func toggleRememberMe() {
        rememberMe.toggle()
    }
    
    // MARK: - Helper Methods
    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        firstName = ""
        lastName = ""
        phoneNumber = ""
        errorMessage = nil
        // Note: Don't clear rememberMe here as it should persist across form clears
    }
    
    /// Loads saved credentials from keychain if available
    private func loadSavedCredentials() {
        guard let credentials = keychainService.loadCredentials() else {
            print("ℹ️ AuthViewModel: No saved credentials found")
            return
        }
        
        email = credentials.email
        password = credentials.password
        rememberMe = credentials.rememberMe
        
        print("✅ AuthViewModel: Loaded saved credentials for \(credentials.email)")
    }
    
    /// Attempts to auto-login with saved credentials
    func attemptAutoLogin() async {
        guard rememberMe, !email.isEmpty, !password.isEmpty else {
            print("ℹ️ AuthViewModel: No saved credentials for auto-login")
            return
        }
        
        print("🔄 AuthViewModel: Attempting auto-login...")
        await login()
    }
    
    private func checkCurrentUser() async {
        do {
            if let user = try await authService.getCurrentUser() {
                currentUser = user
                isAuthenticated = true
                print("✅ Current user found: \(user.email)")
                
                // Initialize FCM for the authenticated user (keychain login)
                await fcmService.onUserLogin()
                
                // Start periodic verification checking for unverified users
                if !user.verified {
                    startVerificationStatusChecking()
                }
            } else {
                currentUser = nil
                isAuthenticated = false
                print("ℹ️ No current user found")
            }
        } catch {
            print("❌ Error checking current user: \(error)")
            currentUser = nil
            isAuthenticated = false
        }
    }

    // MARK: - User Data Management
    
    /// Updates the current user's orders
    /// - Parameter orders: Array of orders to assign to the current user
    func updateUserOrders(_ orders: [Order]) {
        print("👤 AuthViewModel: updateUserOrders called with \(orders.count) orders")
        guard let currentUser = currentUser else { 
            print("❌ AuthViewModel: No current user to update orders for")
            return 
        }
        
        print("👤 AuthViewModel: Updating orders for user: \(currentUser.email)")
        // Create a new user instance with updated orders
                    let updatedUser = User(
                id: currentUser.id,
                email: currentUser.email,
                firstName: currentUser.firstName,
                lastName: currentUser.lastName,
                phoneNumber: currentUser.phoneNumber,
                storeCredit: currentUser.storeCredit,
                role: currentUser.role,
                verified: currentUser.verified,
                fcmToken: currentUser.fcmToken,
                createdAt: currentUser.createdAt,
                updatedAt: currentUser.updatedAt
            )
        updatedUser.orders = orders
        
        // Update the current user
        self.currentUser = updatedUser
        
        print("✅ AuthViewModel: Updated user orders: \(orders.count) orders")
    }
    
    // MARK: - Verification Status Checking
    
    /// Starts periodic checking of verification status for unverified users
    private func startVerificationStatusChecking() {
        // Stop any existing timer
        stopVerificationStatusChecking()
        
        // Check every 30 seconds
        verificationCheckTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task {
                await self?.checkVerificationStatus()
            }
        }
        
        print("🔄 Started verification status checking")
    }
    
    /// Stops periodic verification status checking
    private func stopVerificationStatusChecking() {
        verificationCheckTimer?.invalidate()
        verificationCheckTimer = nil
        print("⏹️ Stopped verification status checking")
    }
    
    /// Checks the current verification status and updates the user if verified
    @MainActor
    private func checkVerificationStatus() async {
        guard let currentUser = currentUser, !currentUser.verified else {
            // User is already verified or not logged in, stop checking
            stopVerificationStatusChecking()
            return
        }
        
        // Check if user is authenticated before checking verification status
        guard isAuthenticated else {
            print("⚠️ User not authenticated, stopping verification status checking")
            stopVerificationStatusChecking()
            return
        }
        
        do {
            print("🔍 AuthViewModel: Checking verification for user: \(currentUser.email)")
            let isVerified = try await authService.checkVerificationStatus(email: currentUser.email)
            if isVerified {
                // User is now verified, create a new user object to ensure UI update
                let updatedUser = User(
                    id: currentUser.id,
                    email: currentUser.email,
                    firstName: currentUser.firstName,
                    lastName: currentUser.lastName,
                    phoneNumber: currentUser.phoneNumber,
                    storeCredit: currentUser.storeCredit,
                    role: currentUser.role,
                    verified: true,
                    fcmToken: currentUser.fcmToken,
                    createdAt: currentUser.createdAt,
                    updatedAt: Date()
                )
                self.currentUser = updatedUser
                
                // Stop checking since user is now verified
                stopVerificationStatusChecking()
                
                print("✅ User email verified successfully")
                print("✅ Updated currentUser.verified to: \(self.currentUser?.verified ?? false)")
                print("🔍 Current user object: \(String(describing: self.currentUser))")
                
                // Trigger callback to refresh products
                print("🔄 Triggering product refresh callback...")
                onEmailVerificationSuccess?()
            }
        } catch {
            print("❌ Error checking verification status: \(error)")
            // If there's an auth error, stop checking
            if error.localizedDescription.contains("session") || error.localizedDescription.contains("Auth") {
                print("⚠️ Auth error detected, stopping verification status checking")
                stopVerificationStatusChecking()
            }
        }
    }
}
/*
🔄 FCM: onUserLogin called
🔔 FCM: Notification permission granted: true
❌ FCM: No APNS token available. Requesting notification permission first...
✅ APNS: Device token received
✅ FCM: APNS token received: 8040c467fa8df8af22d52812fc1df9d1ab7a9a66a7f64b1db9aff546071dc24967a003634aa1fa3b10fe542c5cb06389eb6342e37ead43c763176b36a2931e975906dbc14a700db18dc2a46963630478
✅ FCM: APNS token set for Firebase Messaging
❌ FCM: Failed to get FCM token
✅ User signed up successfully: Finnmcm@u.northwestern.edu
🔄 FCM: onUserLogin called
🔧 Configuration: Using SUPABASE_URL from Info.plist: https://wsctzrofxhluocxeekor.supabase.co
🔧 Configuration: Using SUPABASE_KEY from Info.plist (length: 208)
🔧 Configuration: Using SUPABASE_KEY from Info.plist (length: 208)
🔧 Configuration: Using SUPABASE_KEY from Info.plist (length: 208)
✅ Supabase client initialized successfully
⏰ OrderStatusViewModel: Starting refresh timer with 30.0 second interval
🚀 MainTabView: onAppear triggered
🔗 MainTabView: Setting up OrderStatusViewModel callback...
✅ MainTabView: OrderStatusViewModel callback set up successfully
👤 MainTabView: User authenticated, refreshing orders for: Finnmcm@u.northwestern.edu
🔍 EmailVerificationBanner: currentUser = Optional(Zip.User)
🔍 EmailVerificationBanner: shouldShowBanner = true
🔍 EmailVerificationBanner: Showing banner for user.verified = false
🔍 EmailVerificationBanner: currentUser = Optional(Zip.User)
🔍 EmailVerificationBanner: shouldShowBanner = true
🔍 EmailVerificationBanner: Showing banner for user.verified = false
🔄 MainTabView: Starting to refresh user orders for userId: 7ec6fdc6-25f8-4b21-8906-c4f7b9930dd2
🔧 Configuration: Using SUPABASE_URL from Info.plist: https://wsctzrofxhluocxeekor.supabase.co
🔧 Configuration: Using SUPABASE_KEY from Info.plist (length: 208)
🔧 Configuration: Using SUPABASE_KEY from Info.plist (length: 208)
🔧 Configuration: Using SUPABASE_KEY from Info.plist (length: 208)
✅ Supabase client initialized successfully
🔗 MainTabView: Supabase client configured: true
📡 MainTabView: Fetching orders from Supabase...
🔍 SupabaseService: Fetching products from database...
🔔 FCM: Notification permission granted: true
✅ APNS: Device token received
✅ FCM: APNS token received: 8040c467fa8df8af22d52812fc1df9d1ab7a9a66a7f64b1db9aff546071dc24967a003634aa1fa3b10fe542c5cb06389eb6342e37ead43c763176b36a2931e975906dbc14a700db18dc2a46963630478
✅ FCM: APNS token set for Firebase Messaging
✅ Successfully fetched 0 orders for user: 7ec6fdc6-25f8-4b21-8906-c4f7b9930dd2
✅ MainTabView: Successfully fetched 0 orders from Supabase
👤 MainTabView: Updating user orders in AuthViewModel...
👤 AuthViewModel: updateUserOrders called with 0 orders
👤 AuthViewModel: Updating orders for user: Finnmcm@u.northwestern.edu
✅ AuthViewModel: Updated user orders: 0 orders
✅ MainTabView: User orders updated in AuthViewModel
🎯 MainTabView: Loading active order from pre-fetched orders...
🎯 OrderStatusViewModel: Loading active order from 0 pre-fetched orders
ℹ️ OrderStatusViewModel: No active orders found in pre-fetched orders
✅ MainTabView: Active order loaded from pre-fetched orders
✅ Successfully fetched 143 products from Supabase
✅ FCM: Successfully retrieved FCM token
🎯 FCM: Got token, registering with Supabase: cN1sEJuZVEbHqlW_ic77...
✅ Successfully fetched 143 product images for 143 products from Supabase
✅ Successfully assigned 143 images to 143 products
✅ Successfully loaded 143 products from Supabase
❌ AuthenticationService: Error getting current user: PostgrestError(detail: nil, hint: nil, code: Optional("PGRST116"), message: "Cannot coerce the result to a single JSON object")
*/
