//
//  User.swift
//  Zip
//

import Foundation
import SwiftData

@Model
final class User {
    @Attribute(.unique) var id: UUID
    var email: String
    var createdAt: Date

    init(id: UUID = UUID(), email: String, createdAt: Date = .now) {
        self.id = id
        self.email = email
        self.createdAt = createdAt
    }
}


