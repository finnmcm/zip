//
//  AdminViewModel.swift
//  Zip
//

import Foundation
import SwiftUI

@MainActor
final class AdminViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var numUsers = 0
    @Published var zipperStats: ZipperStatsResult?
    @Published var lowStockItems: [Product] = []
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    private let supabaseService: SupabaseServiceProtocol
    
    // MARK: - Initialization
    init(supabaseService: SupabaseServiceProtocol = SupabaseService.shared) {
        self.supabaseService = supabaseService
    }
    
    // MARK: - Public Methods
    func loadAdminData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch user count, zipper stats, and low stock items concurrently
            async let userCountTask = supabaseService.fetchNumUsers()
            async let zipperStatsTask = supabaseService.fetchZipperStats()
            async let lowStockTask = supabaseService.fetchLowStockItems()
            
            // Wait for all tasks to complete
            let (userCount, stats, lowStock) = try await (userCountTask, zipperStatsTask, lowStockTask)
            
            // Update UI on main thread
            self.numUsers = userCount
            // Sort zippers by orders handled (descending) for ranking
            let sortedStats = ZipperStatsResult(
                zippers: stats.zippers.sorted { $0.ordersHandled > $1.ordersHandled },
                totalRevenue: stats.totalRevenue
            )
            self.zipperStats = sortedStats
            self.lowStockItems = lowStock
            
            print("✅ Successfully loaded admin data: \(userCount) users, \(stats.zippers.count) zippers, \(lowStock.count) low stock items")
            
        } catch {
            print("❌ Error loading admin data: \(error)")
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Computed Properties
    var totalRevenue: Double {
        return zipperStats?.totalRevenue ?? 0.0
    }
    
    var activeZippers: Int {
        return zipperStats?.zippers.count ?? 0
    }
    
    var totalOrdersFulfilled: Int {
        return zipperStats?.zippers.reduce(0) { $0 + $1.ordersHandled } ?? 0
    }
    
    var formattedTotalRevenue: String {
        return String(format: "$%.2f", totalRevenue)
    }
    
    var lowStockCount: Int {
        return lowStockItems.count
    }
}
