//
//  User.swift
//  Zip
//

import Foundation

// MARK: - User Role Enum
enum UserRole: String, Codable, CaseIterable {
    case customer = "customer"
    case zipper = "zipper"
    case admin = "admin"
}

final class User: Identifiable, Codable, Equatable {
    let id: String
    var email: String
    var firstName: String
    var lastName: String
    var phoneNumber: String
    var storeCredit: Decimal
    var role: UserRole
    var createdAt: Date
    var updatedAt: Date
    
    // Computed property for full name
    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
    
    // Relationships - will be handled manually since we're not using SwiftData
    var orders: [Order] = []
    
    init(id: String, email: String, firstName: String, lastName: String, phoneNumber: String, storeCredit: Decimal = 0.0, role: UserRole = .customer, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.phoneNumber = phoneNumber
        self.storeCredit = storeCredit
        self.role = role
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case firstName = "first_name"
        case lastName = "last_name"
        case phoneNumber = "phone_number"
        case storeCredit = "store_credit"
        case role
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        phoneNumber = try container.decode(String.self, forKey: .phoneNumber)
        storeCredit = try container.decode(Decimal.self, forKey: .storeCredit)
        role = try container.decode(UserRole.self, forKey: .role)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encode(phoneNumber, forKey: .phoneNumber)
        try container.encode(storeCredit, forKey: .storeCredit)
        try container.encode(role, forKey: .role)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
    
    // MARK: - Equatable Implementation
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - User for Authentication
struct AuthUser: Codable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    let phoneNumber: String
    let storeCredit: Decimal
    let role: UserRole
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case firstName = "first_name"
        case lastName = "last_name"
        case phoneNumber = "phone_number"
        case storeCredit = "store_credit"
        case role
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    func toUser() -> User {
        return User(
            id: id,
            email: email,
            firstName: firstName,
            lastName: lastName,
            phoneNumber: phoneNumber,
            storeCredit: storeCredit,
            role: role,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}


