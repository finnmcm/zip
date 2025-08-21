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
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentUser: User?
    @Published var isSignUpMode: Bool = false

    private let databaseManager = DatabaseManager.shared

    init() {
        // Load current user from persistence
        loadCurrentUser()
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
    
    var isValidSignUp: Bool {
        isValidEmail && isValidPassword && doPasswordsMatch && !firstName.trimmingCharacters(in: .whitespaces).isEmpty && !lastName.trimmingCharacters(in: .whitespaces).isEmpty
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
        let user = User(email: email, firstName: firstName, lastName: lastName)
        currentUser = user
        
        // Save user to persistence
        var users = databaseManager.loadUsers()
        users.append(user)
        databaseManager.saveUsers(users)
        
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
        let existingUsers = databaseManager.loadUsers()
        if existingUsers.contains(where: { $0.email.lowercased() == email.lowercased() }) {
            errorMessage = "An account with this email already exists"
            return
        }
        
        // Create new user
        let user = User(
            email: email,
            firstName: firstName.trimmingCharacters(in: .whitespaces),
            lastName: lastName.trimmingCharacters(in: .whitespaces)
        )
        
        currentUser = user
        
        // Save user to persistence
        var users = databaseManager.loadUsers()
        users.append(user)
        databaseManager.saveUsers(users)
        
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
        errorMessage = nil
    }

    func logout() async {
        currentUser = nil
        // Clear current user from persistence
        databaseManager.clearModel(User.self, key: "currentUser")
    }
    
    private func loadCurrentUser() {
        // For MVP, just check if there's a user in persistence
        let users = databaseManager.loadUsers()
        currentUser = users.first
    }
}


