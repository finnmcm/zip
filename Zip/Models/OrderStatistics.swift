//
//  OrderStatistics.swift
//  Zip
//

import Foundation

final class OrderStatistics: Identifiable, Codable {
    let id: UUID
    let periodType: TimePeriodType
    let periodStart: Date
    let periodEnd: Date
    
    // Order metrics
    let totalOrders: Int
    let completedOrders: Int
    let cancelledOrders: Int
    let disputedOrders: Int
    
    // Revenue metrics
    let totalRevenue: Decimal
    let totalTips: Decimal
    let averageOrderValue: Decimal
    let averageTipAmount: Decimal
    
    // User metrics
    let uniqueCustomers: Int
    let newCustomers: Int
    let returningCustomers: Int
    
    // Product metrics
    let totalItemsSold: Int
    let averageItemsPerOrder: Decimal
    let mostPopularProductId: UUID?
    let mostPopularProductQuantity: Int?
    
    // Performance metrics
    let averagePreparationTimeMinutes: Decimal?
    let averageDeliveryTimeMinutes: Decimal?
    let onTimeDeliveryPercentage: Decimal?
    
    // Delivery metrics
    let campusDeliveryCount: Int
    let offCampusDeliveryCount: Int
    
    // Metadata
    let createdAt: Date
    let updatedAt: Date
    
    init(
        id: UUID = UUID(),
        periodType: TimePeriodType,
        periodStart: Date,
        periodEnd: Date,
        totalOrders: Int,
        completedOrders: Int,
        cancelledOrders: Int,
        disputedOrders: Int,
        totalRevenue: Decimal,
        totalTips: Decimal,
        averageOrderValue: Decimal,
        averageTipAmount: Decimal,
        uniqueCustomers: Int,
        newCustomers: Int,
        returningCustomers: Int,
        totalItemsSold: Int,
        averageItemsPerOrder: Decimal,
        mostPopularProductId: UUID?,
        mostPopularProductQuantity: Int?,
        averagePreparationTimeMinutes: Decimal?,
        averageDeliveryTimeMinutes: Decimal?,
        onTimeDeliveryPercentage: Decimal?,
        campusDeliveryCount: Int,
        offCampusDeliveryCount: Int,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.periodType = periodType
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.totalOrders = totalOrders
        self.completedOrders = completedOrders
        self.cancelledOrders = cancelledOrders
        self.disputedOrders = disputedOrders
        self.totalRevenue = totalRevenue
        self.totalTips = totalTips
        self.averageOrderValue = averageOrderValue
        self.averageTipAmount = averageTipAmount
        self.uniqueCustomers = uniqueCustomers
        self.newCustomers = newCustomers
        self.returningCustomers = returningCustomers
        self.totalItemsSold = totalItemsSold
        self.averageItemsPerOrder = averageItemsPerOrder
        self.mostPopularProductId = mostPopularProductId
        self.mostPopularProductQuantity = mostPopularProductQuantity
        self.averagePreparationTimeMinutes = averagePreparationTimeMinutes
        self.averageDeliveryTimeMinutes = averageDeliveryTimeMinutes
        self.onTimeDeliveryPercentage = onTimeDeliveryPercentage
        self.campusDeliveryCount = campusDeliveryCount
        self.offCampusDeliveryCount = offCampusDeliveryCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case periodType = "period_type"
        case periodStart = "period_start"
        case periodEnd = "period_end"
        case totalOrders = "total_orders"
        case completedOrders = "completed_orders"
        case cancelledOrders = "cancelled_orders"
        case disputedOrders = "disputed_orders"
        case totalRevenue = "total_revenue"
        case totalTips = "total_tips"
        case averageOrderValue = "average_order_value"
        case averageTipAmount = "average_tip_amount"
        case uniqueCustomers = "unique_customers"
        case newCustomers = "new_customers"
        case returningCustomers = "returning_customers"
        case totalItemsSold = "total_items_sold"
        case averageItemsPerOrder = "average_items_per_order"
        case mostPopularProductId = "most_popular_product_id"
        case mostPopularProductQuantity = "most_popular_product_quantity"
        case averagePreparationTimeMinutes = "average_preparation_time_minutes"
        case averageDeliveryTimeMinutes = "average_delivery_time_minutes"
        case onTimeDeliveryPercentage = "on_time_delivery_percentage"
        case campusDeliveryCount = "campus_delivery_count"
        case offCampusDeliveryCount = "off_campus_delivery_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Computed properties
    var completionRate: Double {
        guard totalOrders > 0 else { return 0 }
        return Double(completedOrders) / Double(totalOrders) * 100
    }
    
    var cancellationRate: Double {
        guard totalOrders > 0 else { return 0 }
        return Double(cancelledOrders) / Double(totalOrders) * 100
    }
    
    var campusDeliveryPercentage: Double {
        let total = campusDeliveryCount + offCampusDeliveryCount
        guard total > 0 else { return 0 }
        return Double(campusDeliveryCount) / Double(total) * 100
    }
    
    var formattedPeriodStart: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: periodStart)
    }
}

enum TimePeriodType: String, Codable, CaseIterable {
    case hourly = "hourly"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"
    
    var displayName: String {
        rawValue.capitalized
    }
}

