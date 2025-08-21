//
//  AuthenticationService.swift
//  Zip
//

import Foundation

protocol AuthenticationServiceProtocol {
    func isValidNorthwesternEmail(_ email: String) -> Bool
    func login(email: String) async throws -> User
    func logout() async
    func currentUser() -> User?
}

final class AuthenticationService: AuthenticationServiceProtocol {
    private let databaseManager = DatabaseManager.shared
    
    func isValidNorthwesternEmail(_ email: String) -> Bool {
        email.lowercased().hasSuffix("@u.northwestern.edu") || email.lowercased().hasSuffix("@northwestern.edu")
    }

    func login(email: String) async throws -> User {
        let user = User(email: email, firstName: "", lastName: "")
        
        // Save user to persistence
        var users = databaseManager.loadUsers()
        users.append(user)
        databaseManager.saveUsers(users)
        
        return user
    }

    func logout() async {
        // Clear current user from persistence
        databaseManager.clearModel(User.self, key: "currentUser")
    }

    func currentUser() -> User? {
        let users = databaseManager.loadUsers()
        return users.first
    }
}
