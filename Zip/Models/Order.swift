//
//  Order.swift
//  Zip
//

import Foundation
import SwiftUI // Added for Color

final class Order: Identifiable, Codable {
    let id: UUID
    var user: User
    var items: [CartItem]
    var status: OrderStatus
    var rawAmount: Decimal
    var tip: Decimal
    var totalAmount: Decimal
    var createdAt: Date
    var deliveryAddress: String
    var paymentIntentId: String?
    var estimatedDeliveryTime: Date?
    var actualDeliveryTime: Date?
    var deliveryInstructions: String?
    var isCampusDelivery: Bool
    
    // Database metadata
    var updatedAt: Date
    
    var isDelivered: Bool {
        return status == .delivered
    }
    
    var isCancelled: Bool {
        return status == .cancelled
    }
    
    var canBeCancelled: Bool {
        return [.pending, .inQueue, .inProgress].contains(status)
    }
    
    // Relationships - will be handled manually since we're not using SwiftData
    var userOrders: [Order] = []
    
    init(id: UUID = UUID(), user: User, items: [CartItem], status: OrderStatus = .pending, rawAmount: Decimal, tip: Decimal, totalAmount: Decimal, deliveryAddress: String, createdAt: Date = Date(), estimatedDeliveryTime: Date? = nil, actualDeliveryTime: Date? = nil, paymentIntentId: String? = nil, updatedAt: Date = Date(), deliveryInstructions: String? = nil, isCampusDelivery: Bool = false) {
        self.id = id
        self.user = user
        self.items = items
        self.status = status
        self.rawAmount = rawAmount
        self.tip = tip
        self.totalAmount = totalAmount
        self.createdAt = createdAt
        self.deliveryAddress = deliveryAddress
        self.estimatedDeliveryTime = estimatedDeliveryTime
        self.actualDeliveryTime = actualDeliveryTime
        self.paymentIntentId = paymentIntentId
        self.updatedAt = updatedAt
        self.deliveryInstructions = deliveryInstructions
        self.isCampusDelivery = isCampusDelivery
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case id
        case user
        case items
        case status
        case rawAmount = "raw_amount"
        case tip
        case totalAmount = "total_amount"
        case createdAt = "created_at"
        case estimatedDeliveryTime = "estimated_delivery_time"
        case actualDeliveryTime = "actual_delivery_time"
        case deliveryAddress = "delivery_address"
        case paymentIntentId = "payment_intent_id"
        case updatedAt = "updated_at"
        case deliveryInstructions = "delivery_instructions"
        case isCampusDelivery = "is_campus_delivery"
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        user = try container.decode(User.self, forKey: .user)
        items = try container.decode([CartItem].self, forKey: .items)
        status = try container.decode(OrderStatus.self, forKey: .status)
        rawAmount = try container.decode(Decimal.self, forKey: .rawAmount)
        tip = try container.decode(Decimal.self, forKey: .tip)
        totalAmount = try container.decode(Decimal.self, forKey: .totalAmount)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        estimatedDeliveryTime = try container.decodeIfPresent(Date.self, forKey: .estimatedDeliveryTime)
        actualDeliveryTime = try container.decodeIfPresent(Date.self, forKey: .actualDeliveryTime)
        deliveryAddress = try container.decode(String.self, forKey: .deliveryAddress)
        paymentIntentId = try container.decodeIfPresent(String.self, forKey: .paymentIntentId)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        
        // Initialize optional properties, decoding if present or using defaults
        deliveryInstructions = try container.decodeIfPresent(String.self, forKey: .deliveryInstructions)
        isCampusDelivery = try container.decodeIfPresent(Bool.self, forKey: .isCampusDelivery) ?? false
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(user, forKey: .user)
        try container.encode(items, forKey: .items)
        try container.encode(status, forKey: .status)
        try container.encode(rawAmount, forKey: .rawAmount)
        try container.encode(tip, forKey: .tip)
        try container.encode(totalAmount, forKey: .totalAmount)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(estimatedDeliveryTime, forKey: .estimatedDeliveryTime)
        try container.encodeIfPresent(actualDeliveryTime, forKey: .actualDeliveryTime)
        try container.encode(deliveryAddress, forKey: .deliveryAddress)
        try container.encodeIfPresent(paymentIntentId, forKey: .paymentIntentId)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(deliveryInstructions, forKey: .deliveryInstructions)
        try container.encode(isCampusDelivery, forKey: .isCampusDelivery)
    }
}

enum OrderStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case inQueue = "in_queue"
    case inProgress = "in_progress"
    case delivered = "delivered"
    case cancelled = "cancelled"
    case disputed = "disputed"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .inQueue: return "In Queue"
        case .inProgress: return "In Progress"
        case .delivered: return "Delivered"
        case .cancelled: return "Cancelled"
        case .disputed: return "Disputed"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .orange
        case .inQueue: return AppColors.northwesternPurple
        case .inProgress: return AppColors.accent
        case .delivered: return .green
        case .cancelled: return .red
        case .disputed: return .orange
        }
    }
}


