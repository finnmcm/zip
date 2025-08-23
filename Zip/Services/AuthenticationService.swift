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
    // In-memory storage for testing
    private var users: [User] = []
    
    func isValidNorthwesternEmail(_ email: String) -> Bool {
        email.lowercased().hasSuffix("@u.northwestern.edu") || email.lowercased().hasSuffix("@northwestern.edu")
    }

    func login(email: String) async throws -> User {
        let user = User(email: email, firstName: "", lastName: "", phoneNumber: "")
        
        // Add to in-memory storage
        users.append(user)
        
        return user
    }

    func logout() async {
        // Clear current user from in-memory storage
        users.removeAll()
    }

    func currentUser() -> User? {
        return users.first
    }
}
