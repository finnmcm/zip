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
    
    // Relationships - will be handled manually since we're not using SwiftData
    var cartItems: [CartItem] = []

    init(id: UUID = UUID(), name: String, price: Decimal, quantity: Int = 0, imageURL: String? = nil, category: String, inStock: Bool? = nil) {
        self.id = id
        self.name = name
        self.price = price
        self.quantity = quantity
        self.imageURL = imageURL
        self.category = category
        // Use provided inStock value or calculate based on quantity
        self.inStock = inStock ?? (quantity > 0)
    }
}


