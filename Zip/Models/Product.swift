//
//  Product.swift
//  Zip
//

import Foundation

enum ProductCategory: String, CaseIterable, Codable {
    case drinks = "Drinks"
    case foodsnacks = "Food/Snacks"
    case chipscandy = "Chips/Candy"
    case misc = "Dorm/Party/School"
    case medical = "Medical"
    
    var displayName: String {
        return self.rawValue
    }
    
    var iconName: String {
        switch self {
        case .drinks: return "cup.and.saucer.fill"
        case .foodsnacks: return "birthday.cake"
        case .chipscandy: return "birthday.cake"
        case .misc: return "book.fill"
        case .medical: return "heart.fill"
        }
    }
}

final class Product: Identifiable, Codable {
    let id: UUID
    var inventoryName: String
    var displayName: String
    var price: Decimal
    var quantity: Int
    var imageURL: String?
    var category: ProductCategory
    
    // Database metadata
    var createdAt: Date
    var updatedAt: Date
    
    // Relationships - will be handled manually since we're not using SwiftData
    // Note: This is not included in Codable to avoid circular references
    var cartItems: [CartItem] = []

    init(id: UUID = UUID(), inventoryName: String, displayName: String, price: Decimal, quantity: Int = 0, imageURL: String? = nil, category: ProductCategory, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.inventoryName = inventoryName
        self.displayName = displayName
        self.price = price
        self.quantity = quantity
        self.imageURL = imageURL
        self.category = category
        // Use provided inStock value or calculate based on quantity
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case id
        case inventoryName = "inventoryName"
        case displayName = "displayName"
        case imageURL = "imageURL"
        case price
        case quantity
        case category
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        inventoryName = try container.decode(String.self, forKey: .inventoryName)
        displayName = try container.decode(String.self, forKey: .displayName)
        price = try container.decode(Decimal.self, forKey: .price)
        quantity = try container.decode(Int.self, forKey: .quantity)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        category = try container.decode(ProductCategory.self, forKey: .category)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(inventoryName, forKey: .inventoryName)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(price, forKey: .price)
        try container.encode(quantity, forKey: .quantity)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encode(category, forKey: .category)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}


