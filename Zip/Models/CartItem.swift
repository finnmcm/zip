//
//  CartItem.swift
//  Zip
//

import Foundation

final class CartItem: Identifiable, Codable {
    let id: UUID
    var product: Product
    var quantity: Int
    var addedAt: Date
    var userId: UUID
    
    // Database metadata
    var createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(), product: Product, quantity: Int = 1, userId: UUID, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.product = product
        self.quantity = quantity
        self.addedAt = Date()
        self.userId = userId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case id
        case product
        case quantity
        case addedAt = "added_at"
        case userId = "user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        product = try container.decode(Product.self, forKey: .product)
        quantity = try container.decode(Int.self, forKey: .quantity)
        addedAt = try container.decode(Date.self, forKey: .addedAt)
        userId = try container.decode(UUID.self, forKey: .userId)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(product, forKey: .product)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(addedAt, forKey: .addedAt)
        try container.encode(userId, forKey: .userId)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}


