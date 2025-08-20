//
//  AuthViewModel.swift
//  Zip
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentUser: User?

    private(set) var context: ModelContext?

    init() {
        // For MVP, initialize without context, will be set later
        self.currentUser = nil
    }

    var isValidEmail: Bool {
        email.lowercased().hasSuffix("@u.northwestern.edu") || email.lowercased().hasSuffix("@northwestern.edu")
    }

    func login() async {
        guard let context = context else { return }
        guard isValidEmail else {
            errorMessage = "Use your Northwestern email"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // For MVP, just create a local user and mark as logged in
        let user = User(email: email)
        context.insert(user)
        try? context.save()
        currentUser = user
    }

    func logout() async {
        guard let context = context else { return }
        if let user = currentUser {
            context.delete(user)
            try? context.save()
        }
        currentUser = nil
    }
    
    func updateContext(_ newContext: ModelContext) {
        self.context = newContext
        // Refresh current user with new context
        self.currentUser = getCurrentUser()
    }
    
    private func getCurrentUser() -> User? {
        guard let context = context else { return nil }
        let descriptor = FetchDescriptor<User>()
        return (try? context.fetch(descriptor))?.first
    }
}


