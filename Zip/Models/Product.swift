//
//  Product.swift
//  Zip
//

import Foundation

final class Product: Identifiable, Codable {
    let id: UUID
    var name: String
    var price: Decimal
    var quantity: Int
    var imageURL: String?
    var category: String
    var inStock: Bool
    
    // Database metadata
    var createdAt: Date
    var updatedAt: Date
    
    // Relationships - will be handled manually since we're not using SwiftData
    var cartItems: [CartItem] = []

    init(id: UUID = UUID(), name: String, price: Decimal, quantity: Int = 0, imageURL: String? = nil, category: String, inStock: Bool? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.price = price
        self.quantity = quantity
        self.imageURL = imageURL
        self.category = category
        // Use provided inStock value or calculate based on quantity
        self.inStock = inStock ?? (quantity > 0)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case price
        case quantity
        case imageURL = "image_url"
        case category
        case inStock = "in_stock"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        price = try container.decode(Decimal.self, forKey: .price)
        quantity = try container.decode(Int.self, forKey: .quantity)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        category = try container.decode(String.self, forKey: .category)
        inStock = try container.decode(Bool.self, forKey: .inStock)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(price, forKey: .price)
        try container.encode(quantity, forKey: .quantity)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encode(category, forKey: .category)
        try container.encode(inStock, forKey: .inStock)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}


