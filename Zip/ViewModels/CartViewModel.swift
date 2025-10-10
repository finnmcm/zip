//
//  CartViewModel.swift
//  Zip
//

import Foundation
import SwiftUI

@MainActor
final class CartViewModel: ObservableObject {
    @Published var items: [CartItem] = [] {
        didSet {
            print("🛒 CartViewModel: items array changed - count: \(items.count)")
            print("🛒 CartViewModel: items: \(items.map { "\($0.product.displayName) x\($0.quantity)" })")
        }
    }
    @Published var isUpdating: Bool = false
    @Published var errorMessage: String?
    
    // Banner notification properties
    @Published var showBanner: Bool = false
    @Published var bannerMessage: String = ""
    @Published var bannerType: BannerType = .success
    @Published var isExiting: Bool = false // New property to track exit animation state
    
    enum BannerType {
        case success
        case error
        case info
    }

    init() {
        print("🛒 CartViewModel: Initializing...")
        print("🛒 CartViewModel: Initialized with \(items.count) items")
    }

    func refresh() {
        print("🛒 CartViewModel: Refreshing cart...")
        print("🛒 CartViewModel: Refresh complete - items count: \(items.count)")
    }

    func add(product: Product, quantity: Int = 1) {
        print("🛒 CartViewModel: Adding product '\(product.displayName)' with quantity \(quantity)")
        print("🛒 CartViewModel: Current items count before add: \(items.count)")
        print("🛒 CartViewModel: Product stock available: \(product.quantity)")
        
        if let existingItem = items.first(where: { $0.product.id == product.id }) {
            print("🛒 CartViewModel: Found existing item, current quantity: \(existingItem.quantity)")
            
            // Check if adding the requested quantity would exceed available stock
            let newQuantity = existingItem.quantity + quantity
            if newQuantity > product.quantity {
                print("❌ CartViewModel: Cannot add \(quantity) more - would exceed stock. Current: \(existingItem.quantity), Available: \(product.quantity)")
                let availableToAdd = product.quantity - existingItem.quantity
                if availableToAdd > 0 {
                    showBannerNotification(message: "Only \(availableToAdd) more in stock", type: .error)
                } else {
                    showBannerNotification(message: "No more \(product.displayName) in stock", type: .error)
                }
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.error)
                return
            }
            
            print("🛒 CartViewModel: Incrementing quantity from \(existingItem.quantity) to \(newQuantity)")
            existingItem.quantity = newQuantity
            // Force UI update by reassigning the array
            items = Array(items)
            // Provide haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            showBannerNotification(message: "\(product.displayName) quantity updated!", type: .success)
        } else {
            // Check if requested quantity exceeds available stock for new item
            if quantity > product.quantity {
                print("❌ CartViewModel: Cannot add \(quantity) - exceeds stock. Available: \(product.quantity)")
                if product.quantity > 0 {
                    showBannerNotification(message: "Only \(product.quantity) in stock", type: .error)
                } else {
                    showBannerNotification(message: "\(product.displayName) out of stock", type: .error)
                }
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.error)
                return
            }
            
            print("🛒 CartViewModel: Creating new cart item for '\(product.displayName)'")
            let newItem = CartItem(product: product, quantity: quantity, userId: UUID()) // Using placeholder UUID for now
            items.append(newItem)
            print("🛒 CartViewModel: New item added, total items count: \(items.count)")
            // Provide haptic feedback for new item
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            showBannerNotification(message: "\(product.displayName) added to cart!", type: .success)
        }
        
        print("🛒 CartViewModel: Add operation complete - final items count: \(items.count)")
    }

    func decrement(item: CartItem) {
        print("🛒 CartViewModel: Decrementing item '\(item.product.displayName)'")
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { 
            print("❌ CartViewModel: Could not find item to decrement")
            return 
        }
        
        if items[idx].quantity <= 1 {
            print("🛒 CartViewModel: Quantity would become 0, removing item")
            // Remove item if quantity would become 0 or less
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            remove(item: item)
        } else {
            print("🛒 CartViewModel: Decrementing quantity from \(items[idx].quantity) to \(items[idx].quantity - 1)")
            items[idx].quantity -= 1
            // Force UI update by reassigning the array
            items = Array(items)
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }

    func increment(item: CartItem) {
        print("🛒 CartViewModel: Incrementing item '\(item.product.displayName)'")
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { 
            print("❌ CartViewModel: Could not find item to increment")
            return 
        }
        
        let currentQuantity = items[idx].quantity
        let availableStock = item.product.quantity
        
        print("🛒 CartViewModel: Current quantity: \(currentQuantity), Available stock: \(availableStock)")
        
        // Check if incrementing would exceed available stock
        if currentQuantity >= availableStock {
            print("❌ CartViewModel: Cannot increment - at stock limit. Current: \(currentQuantity), Available: \(availableStock)")
            showBannerNotification(message: "Maximum stock reached for \(item.product.displayName)", type: .error)
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.error)
            return
        }
        
        print("🛒 CartViewModel: Incrementing quantity from \(currentQuantity) to \(currentQuantity + 1)")
        items[idx].quantity += 1
        // Force UI update by reassigning the array
        items = Array(items)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }

    func remove(item: CartItem) {
        print("🛒 CartViewModel: Removing item '\(item.product.displayName)'")
        print("🛒 CartViewModel: Items count before removal: \(items.count)")
        items.removeAll { $0.id == item.id }
        print("🛒 CartViewModel: Items count after removal: \(items.count)")
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        showBannerNotification(message: "\(item.product.displayName) removed from cart", type: .info)
    }

    func clear() {
        print("🛒 CartViewModel: Clearing all items")
        items.removeAll()
        showBannerNotification(message: "Cart cleared", type: .info)
    }
    
    // MARK: - Banner Notifications
    
    func showBannerNotification(message: String, type: BannerType = .success) {
        bannerMessage = message
        bannerType = type
        showBanner = true
        
        // Auto-hide after 0.5 seconds
        Task {
            try? await Task.sleep(nanoseconds: 1000_000_000) // 0.5 seconds
            await MainActor.run {
                hideBanner()
            }
        }
    }
    
    func hideBanner() {
        // First trigger the exit animation
        isExiting = true
        
        // Wait for the exit animation to complete before actually hiding
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds to match animation duration
            await MainActor.run {
                showBanner = false
                isExiting = false
            }
        }
    }

    var subtotal: Decimal {
        let total = items.reduce(0) { $0 + ($1.product.price * Decimal($1.quantity)) }
        print("🛒 CartViewModel: Calculating subtotal: $\(total)")
        return total
    }
}


