//
//  User.swift
//  Zip
//

import Foundation

final class User: Identifiable, Codable {
    let id: UUID
    var email: String
    var firstName: String
    var lastName: String
    var phoneNumber: String?
    var deliveryAddress: String?
    var isVerified: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // Computed property for full name
    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
    
    // Relationships - will be handled manually since we're not using SwiftData
    var orders: [Order] = []
    var cartItems: [CartItem] = []
    
    init(id: UUID = UUID(), email: String, firstName: String, lastName: String, phoneNumber: String? = nil, deliveryAddress: String? = nil, isVerified: Bool = false, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.phoneNumber = phoneNumber
        self.deliveryAddress = deliveryAddress
        self.isVerified = isVerified
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
        case deliveryAddress = "delivery_address"
        case isVerified = "is_verified"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        deliveryAddress = try container.decodeIfPresent(String.self, forKey: .deliveryAddress)
        isVerified = try container.decode(Bool.self, forKey: .isVerified)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encodeIfPresent(phoneNumber, forKey: .phoneNumber)
        try container.encodeIfPresent(deliveryAddress, forKey: .deliveryAddress)
        try container.encode(isVerified, forKey: .isVerified)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}


