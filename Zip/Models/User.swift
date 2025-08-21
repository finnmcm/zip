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
    
    // Relationships - will be handled manually since we're not using SwiftData
    var orders: [Order] = []
    var cartItems: [CartItem] = []
    
    init(id: UUID = UUID(), email: String, firstName: String, lastName: String, phoneNumber: String? = nil, deliveryAddress: String? = nil, isVerified: Bool = false) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.phoneNumber = phoneNumber
        self.deliveryAddress = deliveryAddress
        self.isVerified = isVerified
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}


