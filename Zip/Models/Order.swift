//
//  Order.swift
//  Zip
//

import Foundation

final class Order: Identifiable, Codable {
    let id: UUID
    var user: User
    var items: [CartItem]
    var status: OrderStatus
    var totalAmount: Decimal
    var deliveryFee: Decimal
    var tax: Decimal
    var createdAt: Date
    var estimatedDeliveryTime: Date?
    var actualDeliveryTime: Date?
    var deliveryAddress: String
    var paymentIntentId: String?
    
    // Relationships - will be handled manually since we're not using SwiftData
    var userOrders: [Order] = []
    
    init(id: UUID = UUID(), user: User, items: [CartItem], status: OrderStatus = .pending, totalAmount: Decimal, deliveryFee: Decimal, tax: Decimal, deliveryAddress: String) {
        self.id = id
        self.user = user
        self.items = items
        self.status = status
        self.totalAmount = totalAmount
        self.deliveryFee = deliveryFee
        self.tax = tax
        self.createdAt = Date()
        self.deliveryAddress = deliveryAddress
    }
}

enum OrderStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case confirmed = "confirmed"
    case preparing = "preparing"
    case outForDelivery = "out_for_delivery"
    case delivered = "delivered"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .confirmed: return "Confirmed"
        case .preparing: return "Preparing"
        case .outForDelivery: return "Out for Delivery"
        case .delivered: return "Delivered"
        case .cancelled: return "Cancelled"
        }
    }
}


