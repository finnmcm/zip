//
//  Product.swift
//  Zip
//

import Foundation
import SwiftData

@Model
final class Product {
    @Attribute(.unique) var id: UUID
    var name: String
    var price: Decimal
    var imageURL: String?
    var category: String
    var inStock: Bool

    init(id: UUID = UUID(), name: String, price: Decimal, imageURL: String? = nil, category: String, inStock: Bool = true) {
        self.id = id
        self.name = name
        self.price = price
        self.imageURL = imageURL
        self.category = category
        self.inStock = inStock
    }
}


