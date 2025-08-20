//
//  Order.swift
//  Zip
//

import Foundation
import SwiftData

@Model
final class Order {
    @Attribute(.unique) var id: UUID
    var total: Decimal
    var createdAt: Date
    var status: String

    init(id: UUID = UUID(), total: Decimal, createdAt: Date = .now, status: String = "confirmed") {
        self.id = id
        self.total = total
        self.createdAt = createdAt
        self.status = status
    }
}


