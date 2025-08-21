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
    
    init(id: UUID = UUID(), product: Product, quantity: Int = 1) {
        self.id = id
        self.product = product
        self.quantity = quantity
        self.addedAt = Date()
    }
}


