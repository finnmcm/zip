//
//  AuthenticationService.swift
//  Zip
//

import Foundation
import Supabase

protocol AuthenticationServiceProtocol {
    func signUp(email: String, password: String, firstName: String, lastName: String, phoneNumber: String) async throws -> User
    func signIn(email: String, password: String) async throws -> User
    func signOut() async throws
    func getCurrentUser() async throws -> User?
    func resetPassword(email: String) async throws
    func updateProfile(_ user: User) async throws -> User
}

final class AuthenticationService: AuthenticationServiceProtocol {
    // MARK: - Properties
    private var supabase: SupabaseClient?
    private let configuration = Configuration.shared
    
    // MARK: - Initialization
    init() {
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
    func signUp(email: String, password: String, firstName: String, lastName: String, phoneNumber: String) async throws -> User {
        guard let supabase = supabase else {
            throw AuthError.clientNotConfigured
        }
         let session = try await supabase.auth.signUp(email: email, password: password)

        let userId = session.user.id.uuidString.lowercased()
            print("authenticated successfully")
            print(">>> Current UID:", userId)

        
        let newUser: User = User(id: userId, email: email, firstName: firstName, lastName: lastName, phoneNumber: phoneNumber)
        print(newUser)
            _ = try await supabase
                .from("users")
                .insert(newUser)
                .execute()
        return newUser
    }
    
    func signIn(email: String, password: String) async throws -> User {
        guard let supabase = supabase else {
            throw AuthError.clientNotConfigured
        }
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
        //TODO: Implement this
        return nil
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
    
    var errorDescription: String? {
        switch self {
        case .clientNotConfigured:
            return "Authentication service is not configured. Please check your Supabase configuration."
        case .signUpFailed:
            return "Failed to create account. Please try again."
        case .signInFailed:
            return "Invalid email or password. Please try again."
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
        }
    }
}
