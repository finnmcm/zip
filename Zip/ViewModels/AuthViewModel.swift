//
//  AuthViewModel.swift
//  Zip
//

import Foundation
import SwiftUI

@MainActor
final class AuthViewModel: ObservableObject {
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

    // In-memory storage for testing
    private var users: [User] = []

    init() {
        // For testing, start with no current user
    }

    var isValidEmail: Bool {
        email.lowercased().hasSuffix("@u.northwestern.edu") || email.lowercased().hasSuffix("@northwestern.edu")
    }
    
    var isValidPassword: Bool {
        password.count >= 8
    }
    
    var doPasswordsMatch: Bool {
        password == confirmPassword
    }
    
    var isValidPhoneNumber: Bool {
        // Basic phone number validation - at least 10 digits
        let digits = phoneNumber.filter { $0.isNumber }
        return digits.count >= 10
    }
    
    var isValidSignUp: Bool {
        isValidEmail && isValidPassword && doPasswordsMatch && !firstName.trimmingCharacters(in: .whitespaces).isEmpty && !lastName.trimmingCharacters(in: .whitespaces).isEmpty && isValidPhoneNumber
    }
    
    var isValidLogin: Bool {
        isValidEmail && !password.isEmpty
    }

    func login() async {
        guard isValidLogin else {
            errorMessage = "Please enter a valid Northwestern email and password"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // For MVP, just create a local user and mark as logged in
        let user = User(email: email, firstName: firstName, lastName: lastName, phoneNumber: phoneNumber)
        currentUser = user
        
        // Add to in-memory storage
        users.append(user)
        
        // Clear form
        clearForm()
    }
    
    func signUp() async {
        guard isValidSignUp else {
            errorMessage = "Please fill in all fields correctly"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Check if user already exists
        if users.contains(where: { $0.email.lowercased() == email.lowercased() }) {
            errorMessage = "An account with this email already exists"
            return
        }
        
        // Create new user
        let user = User(
            email: email,
            firstName: firstName.trimmingCharacters(in: .whitespaces),
            lastName: lastName.trimmingCharacters(in: .whitespaces),
            phoneNumber: phoneNumber.trimmingCharacters(in: .whitespaces)
        )
        
        currentUser = user
        
        // Add to in-memory storage
        users.append(user)
        
        // Clear form
        clearForm()
    }
    
    func toggleMode() {
        isSignUpMode.toggle()
        clearForm()
        errorMessage = nil
    }
    
    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        firstName = ""
        lastName = ""
        phoneNumber = ""
        errorMessage = nil
    }

    func logout() async {
        currentUser = nil
    }
    
    private func loadCurrentUser() {
        // For testing, start with no current user
    }
}


