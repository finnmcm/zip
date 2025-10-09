//
//  AnalyticsViewModel.swift
//  Zip
//

import Foundation
import SwiftUI

@MainActor
final class AnalyticsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var statistics: [OrderStatistics] = []
    @Published var selectedPeriodType: TimePeriodType = .daily
    @Published var selectedTimeRange: TimeRange = .week
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    private let supabaseService: SupabaseService
    
    // MARK: - Initialization
    init(supabaseService: SupabaseService = .shared) {
        self.supabaseService = supabaseService
    }
    
    // MARK: - Public Methods
    func loadStatistics() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let days = selectedTimeRange.days
            statistics = try await supabaseService.fetchOrderStatistics(
                periodType: selectedPeriodType,
                days: days
            )
            
            print("✅ Analytics: Loaded \(statistics.count) statistics records")
            
        } catch {
            print("❌ Analytics: Error loading statistics: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func refreshStatistics() async {
        await loadStatistics()
    }
    
    // MARK: - Computed Properties
    
    var currentPeriodStats: OrderStatistics? {
        statistics.first
    }
    
    var previousPeriodStats: OrderStatistics? {
        guard statistics.count > 1 else { return nil }
        return statistics[1]
    }
    
    var totalRevenue: Decimal {
        statistics.reduce(0) { $0 + $1.totalRevenue }
    }
    
    var totalOrders: Int {
        statistics.reduce(0) { $0 + $1.totalOrders }
    }
    
    var averageOrderValue: Decimal {
        guard !statistics.isEmpty else { return 0 }
        let totalRev = totalRevenue
        let totalOrd = totalOrders
        guard totalOrd > 0 else { return 0 }
        return totalRev / Decimal(totalOrd)
    }
    
    var totalCustomers: Int {
        // Note: This is not unique across periods, just sum of unique per period
        statistics.reduce(0) { $0 + $1.uniqueCustomers }
    }
    
    var completionRate: Double {
        guard totalOrders > 0 else { return 0 }
        let completed = statistics.reduce(0) { $0 + $1.completedOrders }
        return Double(completed) / Double(totalOrders) * 100
    }
    
    var averageDeliveryTime: Decimal? {
        let validStats = statistics.compactMap { $0.averageDeliveryTimeMinutes }
        guard !validStats.isEmpty else { return nil }
        let sum = validStats.reduce(0, +)
        return sum / Decimal(validStats.count)
    }
    
    var onTimeDeliveryPercentage: Decimal? {
        let validStats = statistics.compactMap { $0.onTimeDeliveryPercentage }
        guard !validStats.isEmpty else { return nil }
        let sum = validStats.reduce(0, +)
        return sum / Decimal(validStats.count)
    }
    
    // Growth calculation
    var revenueGrowth: Double? {
        guard let current = currentPeriodStats,
              let previous = previousPeriodStats else { return nil }
        
        let currentRevenue = NSDecimalNumber(decimal: current.totalRevenue).doubleValue
        let previousRevenue = NSDecimalNumber(decimal: previous.totalRevenue).doubleValue
        
        guard previousRevenue > 0 else { return nil }
        return ((currentRevenue - previousRevenue) / previousRevenue) * 100
    }
    
    var ordersGrowth: Double? {
        guard let current = currentPeriodStats,
              let previous = previousPeriodStats else { return nil }
        
        let currentOrders = Double(current.totalOrders)
        let previousOrders = Double(previous.totalOrders)
        
        guard previousOrders > 0 else { return nil }
        return ((currentOrders - previousOrders) / previousOrders) * 100
    }
    
    // Formatting helpers
    var formattedTotalRevenue: String {
        let number = NSDecimalNumber(decimal: totalRevenue).doubleValue
        return String(format: "$%.2f", number)
    }
    
    var formattedAverageOrderValue: String {
        let number = NSDecimalNumber(decimal: averageOrderValue).doubleValue
        return String(format: "$%.2f", number)
    }
    
    var formattedCompletionRate: String {
        return String(format: "%.1f%%", completionRate)
    }
    
    var formattedAverageDeliveryTime: String {
        guard let time = averageDeliveryTime else { return "N/A" }
        let number = NSDecimalNumber(decimal: time).doubleValue
        return String(format: "%.1f min", number)
    }
    
    var formattedOnTimePercentage: String {
        guard let percentage = onTimeDeliveryPercentage else { return "N/A" }
        let number = NSDecimalNumber(decimal: percentage).doubleValue
        return String(format: "%.1f%%", number)
    }
}

// MARK: - Supporting Types
enum TimeRange: String, CaseIterable {
    case week = "7 Days"
    case twoWeeks = "14 Days"
    case month = "30 Days"
    case quarter = "90 Days"
    
    var days: Int {
        switch self {
        case .week: return 7
        case .twoWeeks: return 14
        case .month: return 30
        case .quarter: return 90
        }
    }
    
    var displayName: String {
        rawValue
    }
}

