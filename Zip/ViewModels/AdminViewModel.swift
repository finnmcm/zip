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
            // Fetch both user count and zipper stats concurrently
            async let userCountTask = supabaseService.fetchNumUsers()
            async let zipperStatsTask = supabaseService.fetchZipperStats()
            
            // Wait for both tasks to complete
            let (userCount, stats) = try await (userCountTask, zipperStatsTask)
            
            // Update UI on main thread
            self.numUsers = userCount
            self.zipperStats = stats
            
            print("✅ Successfully loaded admin data: \(userCount) users, \(stats.zippers.count) zippers")
            
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
}
