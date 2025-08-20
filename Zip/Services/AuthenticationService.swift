//
//  AuthenticationService.swift
//  Zip
//

import Foundation
import SwiftData

protocol AuthenticationServiceProtocol {
    func isValidNorthwesternEmail(_ email: String) -> Bool
    func login(email: String, context: ModelContext) async throws -> User
    func logout(context: ModelContext) async
    func currentUser(context: ModelContext) -> User?
}

final class AuthenticationService: AuthenticationServiceProtocol {
    func isValidNorthwesternEmail(_ email: String) -> Bool {
        email.lowercased().hasSuffix("@u.northwestern.edu") || email.lowercased().hasSuffix("@northwestern.edu")
    }

    func login(email: String, context: ModelContext) async throws -> User {
        let user = User(email: email)
        context.insert(user)
        try context.save()
        return user
    }

    func logout(context: ModelContext) async {
        if let user = currentUser(context: context) {
            context.delete(user)
            try? context.save()
        }
    }

    func currentUser(context: ModelContext) -> User? {
        let descriptor = FetchDescriptor<User>()
        return (try? context.fetch(descriptor))?.first
    }
}
