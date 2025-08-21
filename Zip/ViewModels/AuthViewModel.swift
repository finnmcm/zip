//
//  AuthViewModel.swift
//  Zip
//

import Foundation
import SwiftUI

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentUser: User?

    private let databaseManager = DatabaseManager.shared

    init() {
        // Load current user from persistence
        loadCurrentUser()
    }

    var isValidEmail: Bool {
        email.lowercased().hasSuffix("@u.northwestern.edu") || email.lowercased().hasSuffix("@northwestern.edu")
    }

    func login() async {
        guard isValidEmail else {
            errorMessage = "Use your Northwestern email"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // For MVP, just create a local user and mark as logged in
        let user = User(email: email, firstName: "", lastName: "")
        currentUser = user
        
        // Save user to persistence
        var users = databaseManager.loadUsers()
        users.append(user)
        databaseManager.saveUsers(users)
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


