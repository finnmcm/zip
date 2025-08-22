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
    var rawAmount: Decimal
    var deliveryFee: Decimal
    var tip: Decimal
    var total_amount: Decimal
    var tax: Decimal
    var createdAt: Date
    var deliveryAddress: String
    var paymentIntentId: String?
    var estimatedDeliveryTime: Date?
    var actualDeliveryTime: Date?
    
    // Database metadata
    var updatedAt: Date
    
    // Computed properties
    var totalAmount: Decimal {
        return rawAmount + deliveryFee + tip + tax
    }
    
    var isDelivered: Bool {
        return status == .delivered
    }
    
    var isCancelled: Bool {
        return status == .cancelled
    }
    
    var canBeCancelled: Bool {
        return [.pending, .confirmed, .preparing].contains(status)
    }
    
    // Relationships - will be handled manually since we're not using SwiftData
    var userOrders: [Order] = []
    
    init(id: UUID = UUID(), user: User, items: [CartItem], status: OrderStatus = .pending, rawAmount: Decimal, deliveryFee: Decimal, tip: Decimal, totalAmount: Decimal, tax: Decimal, deliveryAddress: String, createdAt: Date = Date(), estimatedDeliveryTime: Date? = nil, actualDeliveryTime: Date? = nil, paymentIntentId: String? = nil, updatedAt: Date = Date()) {
        self.id = id
        self.user = user
        self.items = items
        self.status = status
        self.rawAmount = rawAmount
        self.deliveryFee = deliveryFee
        self.tip = tip
        self.total_amount = totalAmount
        self.tax = tax
        self.createdAt = createdAt
        self.deliveryAddress = deliveryAddress
        self.estimatedDeliveryTime = estimatedDeliveryTime
        self.actualDeliveryTime = actualDeliveryTime
        self.paymentIntentId = paymentIntentId
        self.updatedAt = updatedAt
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case id
        case user
        case items
        case status
        case rawAmount = "raw_amount"
        case deliveryFee = "delivery_fee"
        case tip
        case totalAmount = "total_amount"
        case tax
        case createdAt = "created_at"
        case estimatedDeliveryTime = "estimated_delivery_time"
        case actualDeliveryTime = "actual_delivery_time"
        case deliveryAddress = "delivery_address"
        case paymentIntentId = "payment_intent_id"
        case updatedAt = "updated_at"
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        user = try container.decode(User.self, forKey: .user)
        items = try container.decode([CartItem].self, forKey: .items)
        status = try container.decode(OrderStatus.self, forKey: .status)
        rawAmount = try container.decode(Decimal.self, forKey: .rawAmount)
        deliveryFee = try container.decode(Decimal.self, forKey: .deliveryFee)
        tip = try container.decode(Decimal.self, forKey: .tip)
        total_amount = try container.decode(Decimal.self, forKey: .totalAmount)
        tax = try container.decode(Decimal.self, forKey: .tax)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        estimatedDeliveryTime = try container.decodeIfPresent(Date.self, forKey: .estimatedDeliveryTime)
        actualDeliveryTime = try container.decodeIfPresent(Date.self, forKey: .actualDeliveryTime)
        deliveryAddress = try container.decode(String.self, forKey: .deliveryAddress)
        paymentIntentId = try container.decodeIfPresent(String.self, forKey: .paymentIntentId)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(user, forKey: .user)
        try container.encode(items, forKey: .items)
        try container.encode(status, forKey: .status)
        try container.encode(rawAmount, forKey: .rawAmount)
        try container.encode(deliveryFee, forKey: .deliveryFee)
        try container.encode(tip, forKey: .tip)
        try container.encode(total_amount, forKey: .totalAmount)
        try container.encode(tax, forKey: .tax)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(estimatedDeliveryTime, forKey: .estimatedDeliveryTime)
        try container.encodeIfPresent(actualDeliveryTime, forKey: .actualDeliveryTime)
        try container.encode(deliveryAddress, forKey: .deliveryAddress)
        try container.encodeIfPresent(paymentIntentId, forKey: .paymentIntentId)
        try container.encode(updatedAt, forKey: .updatedAt)
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


