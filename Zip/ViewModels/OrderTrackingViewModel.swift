//
//  OrderTrackingViewModel.swift
//  Zip
//

import Foundation
import SwiftUI

@MainActor
final class OrderTrackingViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentOrder: Order?
    @Published var updatedOrder: Order?
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
    
    /// Sets the current order to track
    /// - Parameter order: The order to track
    func setOrder(_ order: Order) {
        currentOrder = order
        updatedOrder = order
        startRefreshTimer()
    }
    
    /// Refreshes the order status from the server
    func refreshOrderStatus() async {
        guard let currentOrder = currentOrder else { return }
        await refreshOrderStatus(orderId: currentOrder.id)
    }
    
    /// Refreshes the order status from the server
    /// - Parameter orderId: The ID of the order to refresh
    func refreshOrderStatus(orderId: UUID) async {
        guard supabaseService.isClientConfigured else {
            print("⚠️ Supabase not configured, cannot refresh order status")
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let refreshedOrder = try await supabaseService.fetchOrderStatus(orderId: orderId)
            
            if let refreshedOrder = refreshedOrder {
                // Check if the status has changed
                if let currentOrder = currentOrder, 
                   currentOrder.status != refreshedOrder.status {
                    print("🔄 Order status changed from \(currentOrder.status.rawValue) to \(refreshedOrder.status.rawValue)")
                    
                    // Update the current order
                    currentOrder.status = refreshedOrder.status
                    currentOrder.updatedAt = refreshedOrder.updatedAt
                    
                    // Update estimated delivery time if it changed
                    if let newEstimatedTime = refreshedOrder.estimatedDeliveryTime,
                       currentOrder.estimatedDeliveryTime != newEstimatedTime {
                        currentOrder.estimatedDeliveryTime = newEstimatedTime
                    }
                    
                    // Update actual delivery time if it changed
                    if let newActualTime = refreshedOrder.actualDeliveryTime,
                       currentOrder.actualDeliveryTime != newActualTime {
                        currentOrder.actualDeliveryTime = newActualTime
                    }
                    
                    // Set the updated order to trigger UI updates
                    updatedOrder = currentOrder
                    
                    // Stop the refresh timer if the order is completed
                    if [OrderStatus.delivered, OrderStatus.cancelled, OrderStatus.disputed].contains(refreshedOrder.status) {
                        stopRefreshTimer()
                        print("⏰ Stopping refresh timer - order completed")
                    }
                } else {
                    print("ℹ️ Order status unchanged")
                }
            } else {
                print("⚠️ Could not fetch refreshed order status")
                errorMessage = "Unable to refresh order status"
            }
            
        } catch {
            print("❌ Error refreshing order status: \(error)")
            errorMessage = "Failed to refresh order status: \(error.localizedDescription)"
        }
    }
    
    /// Manually refreshes the order status
    /// - Parameter orderId: The ID of the order to refresh
    func manualRefresh(orderId: UUID) async {
        print("🔄 Manual refresh requested for order: \(orderId)")
        await refreshOrderStatus(orderId: orderId)
    }
    
    // MARK: - Private Methods
    
    private func startRefreshTimer() {
        guard let currentOrder = currentOrder else { return }
        
        // Only start timer for active orders
        guard [OrderStatus.inQueue, OrderStatus.inProgress].contains(currentOrder.status) else {
            print("⏰ Not starting refresh timer - order status: \(currentOrder.status.rawValue)")
            return
        }
        
        print("⏰ Starting refresh timer for order: \(currentOrder.id)")
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self,
                      let currentOrder = self.currentOrder else { return }
                
                print("⏰ Timer triggered, refreshing order: \(currentOrder.id)")
                await self.refreshOrderStatus(orderId: currentOrder.id)
            }
        }
    }
    
    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        print("⏰ Refresh timer stopped")
    }
}

// MARK: - Mock Data for Development
extension OrderTrackingViewModel {
    /// Provides mock data for development when Supabase is not configured
    func loadMockOrder() {
        let mockUser = User(
            id: "mock-user-id",
            email: "mock@u.northwestern.edu",
            firstName: "John",
            lastName: "Doe",
            phoneNumber: "123-456-7890",
            storeCredit: 0.0,
            verified: true,
            fcmToken: nil
        )
        
        let mockOrder = Order(
            user: mockUser,
            items: [
                CartItem(
                    product: Product(
                        inventoryName: "coffee_americano",
                        displayName: "Americano",
                        price: 3.99,
                        quantity: 10,
                                                    category: .drinks
                    ),
                    quantity: 2,
                    userId: UUID()
                )
            ],
            status: .inProgress,
            rawAmount: 7.98,
            tip: 2.00,
            totalAmount: 9.98,
            deliveryAddress: "123 Main St, Evanston, IL",
            estimatedDeliveryTime: Date().addingTimeInterval(1800), // 30 minutes from now
            deliveryInstructions: "Leave at front door"
        )
        
        setOrder(mockOrder)
        print("📱 Mock order loaded for development")
    }
}
