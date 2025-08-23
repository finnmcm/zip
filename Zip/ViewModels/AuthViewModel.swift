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

    // MARK: - Services
    private let authService = AuthenticationService()
    
    // MARK: - Initialization
    init() {
        Task {
            await checkCurrentUser()
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
            clearForm()
            errorMessage = nil
            
            print("✅ User signed in successfully: \(user.email)")
            
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
            print("✅ User signed out successfully")
        } catch {
            print("❌ Signout error: \(error)")
            // Even if signout fails, clear local state
            currentUser = nil
            isAuthenticated = false
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
    
    // MARK: - Helper Methods
    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        firstName = ""
        lastName = ""
        phoneNumber = ""
        errorMessage = nil
    }
    
    private func checkCurrentUser() async {
        do {
            if let user = try await authService.getCurrentUser() {
                currentUser = user
                isAuthenticated = true
                print("✅ Current user found: \(user.email)")
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
}


