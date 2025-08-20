//
//  CartItem.swift
//  Zip
//

import Foundation
import SwiftData

@Model
final class CartItem {
    @Attribute(.unique) var id: UUID
    var productId: UUID
    var productName: String
    var unitPrice: Decimal
    var quantity: Int

    init(id: UUID = UUID(), productId: UUID, productName: String, unitPrice: Decimal, quantity: Int) {
        self.id = id
        self.productId = productId
        self.productName = productName
        self.unitPrice = unitPrice
        self.quantity = max(1, quantity)
    }
}


