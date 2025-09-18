//
//  ZipperViewModel.swift
//  Zip
//

import Foundation
import SwiftUI
import UIKit

@MainActor
final class ZipperViewModel: ObservableObject {
    @Published var pendingOrders: [Order] = []
    @Published var activeOrder: Order?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // MARK: - Services
    private let supabaseService = SupabaseService()
    private let authViewModel: AuthViewModel
    
    // MARK: - Computed Properties
    var hasActiveOrder: Bool {
        return activeOrder != nil
    }
    
    var currentUser: User? {
        return authViewModel.currentUser
    }
    
    var zipperId: String? {
        return currentUser?.id
    }
    
    // MARK: - Initialization
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        // Start monitoring for active orders when view model is created
        Task {
            await loadActiveOrder()
        }
    }
    
    // MARK: - Public Methods
    
    func loadPendingOrders() async {
        guard !hasActiveOrder else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let orders = try await supabaseService.fetchPendingOrders()
            pendingOrders = orders
            print("✅ Successfully loaded \(orders.count) pending orders")
        } catch {
            print("❌ Error loading pending orders: \(error)")
            errorMessage = "Failed to load pending orders. Please try again."
        }
        
        isLoading = false
    }
    
    func loadActiveOrder() async {
        guard let zipperId = zipperId else {
            print("❌ No zipper ID available")
            return
        }
        
        do {
            let order = try await supabaseService.fetchActiveOrderForZipper(zipperId: zipperId)
            activeOrder = order
            
            if order != nil {
                print("✅ Successfully loaded active order for zipper")
                // Clear pending orders when we have an active order
                pendingOrders = []
            } else {
                print("ℹ️ No active order found for zipper")
                // Load pending orders when we don't have an active order
                await loadPendingOrders()
            }
        } catch {
            print("❌ Error loading active order: \(error)")
            errorMessage = "Failed to load active order. Please try again."
        }
    }
    
    func acceptOrder(_ order: Order) async {
        guard let zipperId = zipperId else {
            errorMessage = "Unable to identify zipper. Please log in again."
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            let success = try await supabaseService.acceptOrder(orderId: order.id, zipperId: zipperId)
            
            if success {
                // Update local state
                activeOrder = order
                pendingOrders.removeAll { $0.id == order.id }
                successMessage = "Order accepted successfully!"
                print("✅ Successfully accepted order: \(order.id)")
            } else {
                errorMessage = "Failed to accept order. It may have been taken by another zipper."
            }
        } catch {
            print("❌ Error accepting order: \(error)")
            errorMessage = "Failed to accept order. Please try again."
        }
        
        isLoading = false
    }
    
    func completeOrder() async {
        guard let activeOrder = activeOrder else {
            errorMessage = "No active order to complete."
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            let success = try await supabaseService.completeOrder(orderId: activeOrder.id)
            
            if success {
                // Clear active order and reload pending orders
                self.activeOrder = nil
                successMessage = "Order completed successfully!"
                print("✅ Successfully completed order: \(activeOrder.id)")
                
                // Load pending orders after completing current order
                await loadPendingOrders()
            } else {
                errorMessage = "Failed to complete order. Please try again."
            }
        } catch {
            print("❌ Error completing order: \(error)")
            errorMessage = "Failed to complete order. Please try again."
        }
        
        isLoading = false
    }

    func completeOrder(with photo: UIImage) async {
        guard let activeOrder = activeOrder else {
            errorMessage = "No active order to complete."
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            // For now, just complete the order without uploading the photo
            // The photo is captured and can be used for future implementation
            let success = try await supabaseService.completeOrder(orderId: activeOrder.id)
            if success {
                self.activeOrder = nil
                successMessage = "Order completed successfully! Photo captured."
                print("✅ Successfully completed order with photo: \(activeOrder.id)")
                await loadPendingOrders()
            } else {
                errorMessage = "Failed to complete order. Please try again."
            }
        } catch {
            print("❌ Error completing order: \(error)")
            errorMessage = "Failed to complete order. Please try again."
        }
        
        isLoading = false
    }
    
    func refreshData() async {
        await loadActiveOrder()
    }
    
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
    
    // MARK: - Helper Methods
    
    func formatOrderTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
    
    func formatOrderDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .none
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    func formatOrderTotal(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
}