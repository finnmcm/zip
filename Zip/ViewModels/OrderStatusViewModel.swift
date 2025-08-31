//
//  OrderStatusViewModel.swift
//  Zip
//

import Foundation
import SwiftUI

@MainActor
final class OrderStatusViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var activeOrder: Order?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Services
    private let supabaseService = SupabaseService()
    
    // MARK: - Properties
    private var refreshTimer: Timer?
    private let refreshInterval: TimeInterval = 30 // Refresh every 30 seconds
    
    // MARK: - Initialization
    init() {
        startRefreshTimer()
    }
    
    deinit {
        // Clean up timer synchronously since deinit can't be async
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    // MARK: - Public Methods
    
    /// Loads the active order for the current user
    /// - Parameter userId: The ID of the current user
    func loadActiveOrder(userId: String) async {
        guard supabaseService.isClientConfigured else {
            // If Supabase is not configured, we can't fetch real orders
            // This would be replaced with actual implementation when Supabase is ready
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let orders = try await supabaseService.fetchUserOrders(userId: userId)
            
            // Find the most recent active order (in_queue or in_progress)
            activeOrder = orders.first { order in
                [OrderStatus.inQueue, OrderStatus.inProgress].contains(order.status)
            }
            
            if let activeOrder = activeOrder {
                print("✅ Active order found: \(activeOrder.id) - Status: \(activeOrder.status.rawValue)")
            } else {
                print("ℹ️ No active orders found for user")
            }
            
        } catch {
            print("❌ Error loading active order: \(error)")
            errorMessage = "Failed to load order status"
        }
    }
    
    /// Manually refreshes the order status
    /// - Parameter userId: The ID of the current user
    func refreshOrderStatus(userId: String) async {
        await loadActiveOrder(userId: userId)
    }
    
    /// Callback for when orders need to be refreshed
    var onOrdersRefresh: ((String) async -> Void)?
    
    /// Refreshes orders using the callback (if provided)
    /// - Parameter userId: The ID of the current user
    func refreshOrders(userId: String) async {
        print("🔄 OrderStatusViewModel: refreshOrders called for userId: \(userId)")
        if let onOrdersRefresh = onOrdersRefresh {
            print("🔗 OrderStatusViewModel: Using callback to refresh orders")
            await onOrdersRefresh(userId)
        } else {
            print("⚠️ OrderStatusViewModel: No callback available, falling back to original method")
            // Fall back to the original method
            await refreshOrderStatus(userId: userId)
        }
    }
    
    /// Dismisses the current banner
    func dismissBanner() {
        activeOrder = nil
    }
    
    /// Handles banner tap - navigates to order details
    func handleBannerTap() {
        // This would typically navigate to order details or tracking view
        // For now, we'll just print a message
        if let orderId = activeOrder?.id {
            print("🎯 Banner tapped for order: \(orderId)")
        } else {
            print("🎯 Banner tapped for order: unknown")
        }
    }
    
    /// Loads the active order from pre-fetched orders instead of fetching from server
    /// - Parameter orders: Array of orders to search through for the active order
    func loadActiveOrderFromOrders(_ orders: [Order]) {
        print("🎯 OrderStatusViewModel: Loading active order from \(orders.count) pre-fetched orders")
        // Find the most recent active order (in_queue or in_progress)
        activeOrder = orders.first { order in
            [OrderStatus.inQueue, OrderStatus.inProgress].contains(order.status)
        }
        
        if let activeOrder = activeOrder {
            print("✅ OrderStatusViewModel: Active order found from pre-fetched orders: \(activeOrder.id) - Status: \(activeOrder.status.rawValue)")
        } else {
            print("ℹ️ OrderStatusViewModel: No active orders found in pre-fetched orders")
        }
    }
    
    // MARK: - Private Methods
    
    private func startRefreshTimer() {
        print("⏰ OrderStatusViewModel: Starting refresh timer with \(refreshInterval) second interval")
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                // Only refresh if we have an active order
                if let activeOrder = self.activeOrder {
                    print("⏰ OrderStatusViewModel: Timer triggered, refreshing orders for active order: \(activeOrder.id)")
                    await self.refreshOrders(userId: activeOrder.user.id)
                } else {
                    print("⏰ OrderStatusViewModel: Timer triggered but no active order to refresh")
                }
            }
        }
    }
    
    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}

// MARK: - Mock Data for Development
extension OrderStatusViewModel {
    /// Provides mock data for development when Supabase is not configured
    func loadMockActiveOrder() {
        let mockUser = User(
            id: "mock-user-id",
            email: "mock@u.northwestern.edu",
            firstName: "John",
            lastName: "Doe",
            phoneNumber: "123-456-7890"
        )
        
        let mockOrder = Order(
            user: mockUser,
            items: [],
            status: .inProgress,
            rawAmount: 15.99,
            tip: 2.00,
            totalAmount: 17.99,
            deliveryAddress: "123 Main St",
            estimatedDeliveryTime: Date().addingTimeInterval(1800) // 30 minutes from now
        )
        
        activeOrder = mockOrder
        print("📱 Mock active order loaded for development")
    }
}
