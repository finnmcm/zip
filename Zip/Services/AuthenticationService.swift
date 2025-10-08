//
//  AuthenticationService.swift
//  Zip
//

import Foundation
import Supabase

// MARK: - Response Models
struct VerificationResult: Codable {
    let verified: Bool
}

struct DeleteAccountResponse: Codable {
    let success: Bool
    let message: String?
    let userId: String?
    let error: String?
}

protocol AuthenticationServiceProtocol {
    func signUp(email: String, password: String, firstName: String, lastName: String, phoneNumber: String, role: UserRole) async throws -> User
    func signIn(email: String, password: String) async throws -> User
    func signOut() async throws
    func getCurrentUser() async throws -> User?
    func resetPassword(email: String) async throws
    func updateProfile(_ user: User) async throws -> User
    func checkVerificationStatus(email: String) async throws -> Bool
    func resendVerificationEmail(email: String) async throws
    func deleteAccount() async throws
}

final class AuthenticationService: AuthenticationServiceProtocol {
    // MARK: - Singleton
    static let shared = AuthenticationService()
    
    // MARK: - Properties
    private var supabase: SupabaseClient?
    private let configuration = Configuration.shared
    private lazy var supabaseService = SupabaseService.shared
    
    // MARK: - Initialization
    private init() {
        setupSupabaseClient()
    }
    
    // MARK: - Setup
    private func setupSupabaseClient() {
        guard let url = URL(string: configuration.supabaseURL) else {
            print("❌ Invalid Supabase URL: \(configuration.supabaseURL)")
            return
        }
        
        // Check if we have valid credentials
        guard !configuration.supabaseAnonKey.isEmpty && configuration.supabaseAnonKey != "YOUR_DEV_SUPABASE_ANON_KEY" else {
            print("⚠️ Supabase credentials not configured. Authentication will not work.")
            return
        }
        
        self.supabase = SupabaseClient(
            supabaseURL: url,
            supabaseKey: configuration.supabaseAnonKey
        )
        
        print("✅ Supabase authentication client initialized successfully")
    }
    
    // MARK: - Client Status
    var isClientConfigured: Bool {
        return supabase != nil
    }
    
    // MARK: - Authentication Methods
    func signUp(email: String, password: String, firstName: String, lastName: String, phoneNumber: String, role: UserRole = .customer) async throws -> User {
        guard let supabase = supabase else {
            throw AuthError.clientNotConfigured
        }
        
        do {
            let session = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: ["first_name": AnyJSON(firstName), "last_name": AnyJSON(lastName), "phone_number": AnyJSON(phoneNumber), "role": AnyJSON(role.rawValue)]
            )

            let userId = session.user.id.uuidString.lowercased()
            print("✅ User authenticated successfully")
            print(">>> Current UID:", userId)

            // Create user profile in database
            let newUser = User(
                id: userId, 
                email: email, 
                firstName: firstName, 
                lastName: lastName, 
                phoneNumber: phoneNumber, 
                storeCredit: 0.0, 
                role: role,
                verified: false,
                fcmToken: nil
            )
            print("Creating user profile:", newUser)
            
            // Register FCM token for new user after profile creation
            await FCMService.shared.onUserLogin()
                
            return newUser
            
        } catch let error as AuthError {
            // Re-throw our custom auth errors
            print("❌ Authentication error: \(error.localizedDescription)")
            throw error
        } catch {
            // Handle other authentication errors
            print("❌ Signup failed: \(error)")
            print("❌ Error type: \(type(of: error))")
            print("❌ Error description: \(error.localizedDescription)")
            
            // Parse Supabase auth errors
            let errorMessage = error.localizedDescription.lowercased()
            
            // Check for specific error patterns
            if errorMessage.contains("user already registered") || 
               errorMessage.contains("email already exists") ||
               errorMessage.contains("already registered") {
                throw AuthError.emailAlreadyInUse
            } else if errorMessage.contains("password") && 
                      (errorMessage.contains("weak") || errorMessage.contains("short") || errorMessage.contains("invalid")) {
                throw AuthError.weakPassword
            } else if errorMessage.contains("too many requests") || 
                      errorMessage.contains("rate limit") {
                throw AuthError.rateLimitExceeded
            } else if errorMessage.contains("network") || 
                      errorMessage.contains("connection") {
                throw AuthError.networkError
            } else if errorMessage.contains("invalid email") {
                throw AuthError.invalidEmail
            } else {
                // For any other auth-related error, throw a generic sign up failed error
                throw AuthError.signUpFailed
            }
        }
    }
    
    func signIn(email: String, password: String) async throws -> User {
        guard let supabase = supabase else {
            throw AuthError.clientNotConfigured
        }
        
        do {
            let result = try await supabase.auth.signIn(email: email, password: password)
            let userID = result.user.id.uuidString.lowercased()
            
            let profileResponse: User = try await supabase
                .from("users")
                .select()
                .eq("id", value: userID)
                .single()
                .execute()
                .value
            return profileResponse
            
        } catch {
            print("❌ Sign in error: \(error)")
            print("❌ Error type: \(type(of: error))")
            print("❌ Error description: \(error.localizedDescription)")
            
            // Parse Supabase auth errors
            let errorMessage = error.localizedDescription.lowercased()
            
            // Check for specific error patterns
            if errorMessage.contains("invalid login credentials") || 
               errorMessage.contains("invalid email or password") {
                throw AuthError.invalidCredentials
            } else if errorMessage.contains("email not confirmed") || 
                      errorMessage.contains("email confirmation") {
                throw AuthError.emailNotConfirmed
            } else if errorMessage.contains("too many requests") || 
                      errorMessage.contains("rate limit") {
                throw AuthError.rateLimitExceeded
            } else if errorMessage.contains("user not found") {
                throw AuthError.userNotFound
            } else if errorMessage.contains("network") || 
                      errorMessage.contains("connection") {
                throw AuthError.networkError
            } else {
                // For any other auth-related error, throw a generic sign in failed error
                throw AuthError.signInFailed
            }
        }
    }
    
    func signOut() async throws {
        guard let supabase = supabase else {
            throw AuthError.clientNotConfigured
        }
        
        do {
            try await supabase.auth.signOut()
            print("✅ User signed out successfully")
        } catch {
            print("❌ Signout error: \(error)")
            throw AuthError.signOutFailed
        }
    }
    
    func getCurrentUser() async throws -> User? {
        guard let supabase = supabase else {
            throw AuthError.clientNotConfigured
        }
        
        do {
            // Get the current session
            let session = try await supabase.auth.session
            
            let user = session.user
            let userID = user.id.uuidString.lowercased()
            
            print("🔍 AuthenticationService: Session user ID: \(userID)")
            print("🔍 AuthenticationService: Session user email: \(user.email ?? "nil")")
            
            // First, let's check if the user exists in the users table
            let userExistsResponse = try await supabase
                .from("users")
                .select("id, email")
                .eq("id", value: userID)
                .execute()
            
            print("🔍 AuthenticationService: User exists query result: \(userExistsResponse)")
            
            // If no user found, wait a bit and try again (for timing issues)
            if userExistsResponse.data.isEmpty {
                print("⚠️ AuthenticationService: No user found, waiting 2 seconds and retrying...")
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                
                let retryResponse = try await supabase
                    .from("users")
                    .select("id, email")
                    .eq("id", value: userID)
                    .execute()
                
                print("🔍 AuthenticationService: Retry query result: \(retryResponse)")
                
                if retryResponse.data.isEmpty {
                    print("❌ AuthenticationService: User still not found after retry")
                    throw AuthError.userNotFound
                }
            }
            
            // Fetch user profile from database
            let profileResponse: User = try await supabase
                .from("users")
                .select()
                .eq("id", value: userID)
                .single()
                .execute()
                .value
            
            print("✅ AuthenticationService: Current user found: \(profileResponse.email)")
            return profileResponse
            
        } catch {
            print("❌ AuthenticationService: Error getting current user: \(error)")
            print("❌ AuthenticationService: Error type: \(type(of: error))")
            if let postgrestError = error as? PostgrestError {
                print("❌ AuthenticationService: PostgrestError code: \(postgrestError.code ?? "nil")")
                print("❌ AuthenticationService: PostgrestError message: \(postgrestError.message)")
            }
            return nil
        }
    }
    
    func resetPassword(email: String) async throws {
        guard let supabase = supabase else {
            throw AuthError.clientNotConfigured
        }
        
        do {
            try await supabase.auth.resetPasswordForEmail(email)
            print("✅ Password reset email sent to: \(email)")
        } catch {
            print("❌ Password reset error: \(error)")
            throw AuthError.passwordResetFailed
        }
    }
    
    func updateProfile(_ user: User) async throws -> User {
        guard let supabase = supabase else {
            throw AuthError.clientNotConfigured
        }
        
        do {
            let updatedUser: AuthUser = try await supabase
                .from("users")
                .update(user)
                .eq("id", value: user.id)
                .select()
                .single()
                .execute()
                .value
            
            print("✅ User profile updated successfully: \(updatedUser.email)")
            return updatedUser.toUser()
            
        } catch let error as PostgrestError {
            print("❌ Database error updating profile: \(error)")
            throw AuthError.databaseError(error.localizedDescription)
        } catch {
            print("❌ Profile update error: \(error)")
            throw AuthError.profileUpdateFailed
        }
    }
    
    func checkVerificationStatus(email: String) async throws -> Bool {
        guard let supabase = supabase else {
            throw AuthError.clientNotConfigured
        }
        
        do {
            // Call the database function with lowercase email to ensure case consistency
            let lowercaseEmail = email.lowercased()
            print("🔍 Checking verification for email: \(email) (normalized to: \(lowercaseEmail))")
            let response: [VerificationResult] = try await supabase
                .rpc("check_email_verification", params: ["user_email": lowercaseEmail])
                .execute()
                .value
            
            // The function returns a table with verified boolean
            // Return the first result's verified status, or false if no results
            print("RPC response: \(response)")
            print("Response count: \(response.count)")
            if let firstResult = response.first {
                print("✅ Found user with verified status: \(firstResult.verified)")
                return firstResult.verified
            } else {
                print("⚠️ No results returned - user may not exist in database or case mismatch")
                print("💡 Try updating your SQL function to use: WHERE LOWER(u.email) = LOWER(user_email)")
                return false
            }
            
        } catch {
            // Handle any errors (network, database, etc.)
            print("Error checking email verification: \(error)")
            throw error
        }
    }
    
    func resendVerificationEmail(email: String) async throws {
        guard let supabase = supabase else {
            throw AuthError.clientNotConfigured
        }
        
        do {
            // Supabase resend API for email confirmation
            // The resend method sends a new OTP (one-time password) for signup confirmation
            _ = try await supabase.auth.resend(email: email, type: .signup)
            
            print("✅ Verification email resent to: \(email)")
        } catch {
            print("❌ Error resending verification email: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            
            // Check if the error is due to rate limiting
            let errorDescription = error.localizedDescription.lowercased()
            if errorDescription.contains("rate") || errorDescription.contains("too many") || errorDescription.contains("limit") {
                throw AuthError.rateLimitExceeded
            }
            
            throw AuthError.verificationEmailFailed
        }
    }
    
    func deleteAccount() async throws {
        guard let supabase = supabase else {
            throw AuthError.clientNotConfigured
        }
        
        do {
            // Get current user to verify they're authenticated
            guard let currentUser = try await getCurrentUser() else {
                throw AuthError.userNotFound
            }
            
            print("🗑️ Starting account deletion for user: \(currentUser.email)")
            
            // Get the current session to get the access token
            let session = try await supabase.auth.session
            let accessToken = session.accessToken
            
            // Call the Edge Function to delete the user account
            let response: DeleteAccountResponse = try await supabase.functions.invoke(
                "delete-user-account"
            )
            
            // Check if the response indicates success
            if response.success {
                print("✅ Account deleted successfully for user: \(currentUser.email)")
                print("ℹ️ User has been deleted from both database and Auth system")
            } else {
                print("❌ Account deletion failed: \(response.error ?? "Unknown error")")
                throw AuthError.accountDeletionFailed
            }
            
        } catch {
            print("❌ Error deleting account: \(error)")
            print("❌ Error type: \(type(of: error))")
            print("❌ Error description: \(error.localizedDescription)")
            
            // Parse specific errors
            let errorMessage = error.localizedDescription.lowercased()
            
            if errorMessage.contains("network") || errorMessage.contains("connection") {
                throw AuthError.networkError
            } else if errorMessage.contains("not found") {
                throw AuthError.userNotFound
            } else {
                throw AuthError.accountDeletionFailed
            }
        }
    }
}

// MARK: - Authentication Errors
enum AuthError: LocalizedError {
    case clientNotConfigured
    case signUpFailed
    case signInFailed
    case signOutFailed
    case passwordResetFailed
    case profileUpdateFailed
    case databaseError(String)
    case userNotFound
    case verificationEmailFailed
    case rateLimitExceeded
    case invalidCredentials
    case emailNotConfirmed
    case networkError
    case emailAlreadyInUse
    case weakPassword
    case invalidEmail
    case accountDeletionFailed
    
    var errorDescription: String? {
        switch self {
        case .clientNotConfigured:
            return "Authentication service is not configured. Please check your Supabase configuration."
        case .signUpFailed:
            return "Failed to create account. Please try again."
        case .signInFailed:
            return "Sign in failed. Please check your credentials and try again."
        case .signOutFailed:
            return "Failed to sign out. Please try again."
        case .passwordResetFailed:
            return "Failed to send password reset email. Please try again."
        case .profileUpdateFailed:
            return "Failed to update profile. Please try again."
        case .databaseError(let message):
            return "Database error: \(message)"
        case .userNotFound:
            return "User profile not found. Please contact support."
        case .verificationEmailFailed:
            return "Failed to resend verification email. Please try again."
        case .rateLimitExceeded:
            return "Too many requests. Please wait a moment before trying again."
        case .invalidCredentials:
            return "Invalid email or password. Please check your credentials and try again."
        case .emailNotConfirmed:
            return "Please verify your email address before signing in. Check your inbox for a confirmation link."
        case .networkError:
            return "Network connection error. Please check your internet connection and try again."
        case .emailAlreadyInUse:
            return "This email is already registered. Please sign in or use a different email."
        case .weakPassword:
            return "Password is too weak. Please use a stronger password with at least 8 characters."
        case .invalidEmail:
            return "Invalid email format. Please enter a valid email address."
        case .accountDeletionFailed:
            return "Failed to delete account. Please try again or contact support."
        }
    }
}
