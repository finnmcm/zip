//
//  CheckoutViewModel.swift
//  Zip
//

import Foundation
import SwiftUI
import UIKit

@MainActor
final class CheckoutViewModel: ObservableObject {
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?
    @Published var lastOrder: Order?
    @Published var tipAmount: Decimal = 2.0
    @Published var isCampusDelivery: Bool = true
    @Published var selectedBuilding: String = ""
    @Published var selectedAddress: String = ""
    @Published var deliveryInstructions: String = ""
    @Published var showErrorBanner: Bool = false
    @Published var paymentError: String?
    @Published var appliedStoreCredit: Decimal = 0.0
    @Published var showStoreCreditOption: Bool = false
    @Published var isApplePayAvailable: Bool = false
    @Published var isOffCampusAddressWithinRadius: Bool = true

    private let stripe: StripeServiceProtocol
    private let supabase: SupabaseServiceProtocol
    let authViewModel: AuthViewModel
    private let orderStatusViewModel: OrderStatusViewModel

    // In-memory storage for testing
    private var orders: [Order] = []
    let cart: CartViewModel

    init(stripe: StripeServiceProtocol = StripeService(), 
         supabase: SupabaseServiceProtocol = SupabaseService(), 
         cart: CartViewModel,
         authViewModel: AuthViewModel,
         orderStatusViewModel: OrderStatusViewModel) {
        self.stripe = stripe
        self.supabase = supabase
        self.cart = cart
        self.authViewModel = authViewModel
        self.orderStatusViewModel = orderStatusViewModel
        
        // Check Apple Pay availability
        self.isApplePayAvailable = stripe.isApplePayAvailable()
    }

    func confirmApplePayPayment() async {
        guard cart.subtotal > 0 else { return }
        guard let currentUser = authViewModel.currentUser else {
            errorMessage = "Please log in to complete your order."
            return
        }
        
        // Check if user is verified
        guard currentUser.verified else {
            errorMessage = "Please verify your email address before placing an order. Check your email for a verification link."
            return
        }
        
        // Validate stock levels before processing payment
        let stockValidation = await validateCartStock()
        if !stockValidation.isValid {
            errorMessage = stockValidation.errorMessage
            showErrorBanner = true
            paymentError = stockValidation.errorMessage
            return
        }
        
        isProcessing = true
        defer { isProcessing = false }

        // Create the order first
        let total = cart.subtotal + tipAmount // Include delivery fee
        let finalTotal = max(0, total - appliedStoreCredit)
        
        print("🍎 confirmApplePayPayment called")
        print("🍎 cart.subtotal: $\(cart.subtotal)")
        print("🍎 tipAmount: $\(tipAmount)")
        print("🍎 total: $\(total)")
        print("🍎 appliedStoreCredit: $\(appliedStoreCredit)")
        print("🍎 finalTotal: $\(finalTotal)")
        
        let order = Order(
            user: currentUser,
            items: cart.items,
            status: .pending,
            rawAmount: cart.subtotal,
            tip: tipAmount,
            totalAmount: finalTotal,
            deliveryAddress: isCampusDelivery ? selectedBuilding : selectedAddress,
            createdAt: Date(),
            deliveryInstructions: deliveryInstructions,
            isCampusDelivery: isCampusDelivery,
            firstName: currentUser.firstName,
            lastName: currentUser.lastName
        )
        print("🍎 order: \(order)")
        
        do {
            // Create order in Supabase backend
            let createdOrder = try await supabase.createOrder(order)
            lastOrder = createdOrder
            
            // Handle payment based on store credit application
            if appliedStoreCredit >= total {
                // Store credit covers entire amount - no payment needed
                print("💳 Store credit covers entire order amount")
                print("💳 Applied store credit: $\(appliedStoreCredit)")
                print("💳 Total order amount: $\(total)")
                print("💳 Order ID: \(createdOrder.id)")
                
                createdOrder.status = .inQueue
                orders.append(createdOrder)
                cart.clear()
                errorMessage = nil
                paymentError = nil
                showErrorBanner = false
                
                lastOrder = createdOrder
                
                // Update the OrderStatusViewModel with the new active order
                orderStatusViewModel.activeOrder = createdOrder
                
                // Update user's store credit in Supabase
                print("💳 Updating user store credit...")
                await updateUserStoreCredit(amount: appliedStoreCredit)
                
                // Manually call the Supabase database function to update order status and inventory
                print("💳 Calling updateOrderStatusAndInventory for order: \(createdOrder.id)")
                await updateOrderStatusAndInventory(orderId: createdOrder.id)
                print("💳 Finished calling updateOrderStatusAndInventory")
                
                // Provide haptic feedback for successful order
                let impactFeedback = UINotificationFeedbackGenerator()
                impactFeedback.notificationOccurred(.success)
                return
            }
            
            // Process Apple Pay payment for remaining amount (after store credit)
            let description = "Zip Order #\(createdOrder.id.uuidString.prefix(8))"
            let result = await stripe.processApplePayPayment(
                amount: finalTotal, // Amount after store credit discount
                tip: 0, // Tip already included in finalTotal
                description: description, 
                orderId: createdOrder.id
            )
            
            if result.success {
                // Payment successful - order is already created in Supabase
                // Update order status to inQueue for immediate banner display
                createdOrder.status = .inQueue
                orders.append(createdOrder)
                cart.clear()
                errorMessage = nil
                paymentError = nil
                showErrorBanner = false
                
                lastOrder = createdOrder
                
                // Update the OrderStatusViewModel with the new active order
                orderStatusViewModel.activeOrder = createdOrder
                
                // Update user's store credit if any was applied
                if appliedStoreCredit > 0 {
                    print("💳 Updating user store credit after partial payment...")
                    await updateUserStoreCredit(amount: appliedStoreCredit)
                }
                
                // Provide haptic feedback for successful payment
                let impactFeedback = UINotificationFeedbackGenerator()
                impactFeedback.notificationOccurred(.success)
            } else {
                // Payment failed - we should update the order status to cancelled
                paymentError = result.errorMessage ?? "Apple Pay payment failed. Please try again."
                showErrorBanner = true
                errorMessage = nil
                
                // Provide haptic feedback for payment failure
                let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                impactFeedback.impactOccurred()
                
                // Auto-dismiss error banner after 5 seconds
                Task {
                    try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                    await MainActor.run {
                        if showErrorBanner {
                            dismissErrorBanner()
                        }
                    }
                }
            }
        } catch {
            paymentError = "Failed to create order. Please try again."
            showErrorBanner = true
            errorMessage = nil
            
            // Provide haptic feedback for order creation failure
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
            
            // Auto-dismiss error banner after 5 seconds
            Task {
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                await MainActor.run {
                    if showErrorBanner {
                        dismissErrorBanner()
                    }
                }
            }
            
            print("❌ Error creating order: \(error)")
        }
    }

    func confirmPayment() async {
        guard cart.subtotal > 0 else { return }
        guard let currentUser = authViewModel.currentUser else {
            errorMessage = "Please log in to complete your order."
            return
        }
        
        // Check if user is verified
        guard currentUser.verified else {
            errorMessage = "Please verify your email address before placing an order. Check your email for a verification link."
            return
        }
        
        // Validate stock levels before processing payment
        let stockValidation = await validateCartStock()
        if !stockValidation.isValid {
            errorMessage = stockValidation.errorMessage
            showErrorBanner = true
            paymentError = stockValidation.errorMessage
            return
        }
        
        isProcessing = true
        defer { isProcessing = false }

        // Create the order first
        let total = cart.subtotal + tipAmount // Include delivery fee
        let finalTotal = max(0, total - appliedStoreCredit)
        
        print("🔍 confirmPayment called")
        print("🔍 cart.subtotal: $\(cart.subtotal)")
        print("🔍 delivery fee: $0.99")
        print("🔍 tipAmount: $\(tipAmount)")
        print("🔍 total: $\(total)")
        print("🔍 appliedStoreCredit: $\(appliedStoreCredit)")
        print("🔍 finalTotal: $\(finalTotal)")
        print("🔍 currentUser.storeCredit: $\(currentUser.storeCredit)")
        print("🔍 appliedStoreCredit >= total: \(appliedStoreCredit >= total)")
        
        let order = Order(
            user: currentUser,
            items: cart.items,
            status: .pending,
            rawAmount: cart.subtotal,
            tip: tipAmount,
            totalAmount: finalTotal,
            deliveryAddress: isCampusDelivery ? selectedBuilding : selectedAddress,
            createdAt: Date(),
            deliveryInstructions: deliveryInstructions,
            isCampusDelivery: isCampusDelivery,
            firstName: currentUser.firstName,
            lastName: currentUser.lastName
        )
        
        do {
            // Create order in Supabase backend
            let createdOrder = try await supabase.createOrder(order)
            lastOrder = createdOrder
            
            // Handle payment based on store credit application
            if appliedStoreCredit >= total {
                // Store credit covers entire amount - no payment needed
                print("💳 Store credit covers entire order amount")
                print("💳 Applied store credit: $\(appliedStoreCredit)")
                print("💳 Total order amount: $\(total)")
                print("💳 Order ID: \(createdOrder.id)")
                
                createdOrder.status = .inQueue
                orders.append(createdOrder)
                cart.clear()
                errorMessage = nil
                paymentError = nil
                showErrorBanner = false
                
                lastOrder = createdOrder
                
                // Update the OrderStatusViewModel with the new active order
                orderStatusViewModel.activeOrder = createdOrder
                
                // Update user's store credit in Supabase
                print("💳 Updating user store credit...")
                await updateUserStoreCredit(amount: appliedStoreCredit)
                
                // Manually call the Supabase database function to update order status and inventory
                print("💳 Calling updateOrderStatusAndInventory for order: \(createdOrder.id)")
                await updateOrderStatusAndInventory(orderId: createdOrder.id)
                print("💳 Finished calling updateOrderStatusAndInventory")
                
                // Note: Zippers are notified automatically via Stripe webhook when payment succeeds
                
                // Provide haptic feedback for successful order
                let impactFeedback = UINotificationFeedbackGenerator()
                impactFeedback.notificationOccurred(.success)
                return
            }
            
            // Process payment for remaining amount (after store credit)
            let description = "Zip Order #\(createdOrder.id.uuidString.prefix(8))"
            let result = await stripe.processPayment(
                amount: finalTotal, // Amount after store credit discount
                tip: 0, // Tip already included in finalTotal
                description: description, 
                orderId: createdOrder.id
            )
            
            if result.success {
                // Payment successful - order is already created in Supabase
                // Update order status to inQueue for immediate banner display
                createdOrder.status = .inQueue
                orders.append(createdOrder)
                cart.clear()
                errorMessage = nil
                paymentError = nil
                showErrorBanner = false
                
                lastOrder = createdOrder
                
                // Update the OrderStatusViewModel with the new active order
                orderStatusViewModel.activeOrder = createdOrder
                
                // Update user's store credit if any was applied
                if appliedStoreCredit > 0 {
                    print("💳 Updating user store credit after partial payment...")
                    await updateUserStoreCredit(amount: appliedStoreCredit)
                }
                
                // Note: Zippers are notified automatically via Stripe webhook when payment succeeds
                
                // Provide haptic feedback for successful payment
                let impactFeedback = UINotificationFeedbackGenerator()
                impactFeedback.notificationOccurred(.success)
            } else {
                // Payment failed - we should update the order status to cancelled
                paymentError = result.errorMessage ?? "Payment failed. Please try again."
                showErrorBanner = true
                errorMessage = nil
                
                // Provide haptic feedback for payment failure
                let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                impactFeedback.impactOccurred()
                
                // Auto-dismiss error banner after 5 seconds
                Task {
                    try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                    await MainActor.run {
                        if showErrorBanner {
                            dismissErrorBanner()
                        }
                    }
                }
                
                // TODO: Update order status to cancelled in Supabase
            }
        } catch {
            paymentError = "Failed to create order. Please try again."
            showErrorBanner = true
            errorMessage = nil
            
            // Provide haptic feedback for order creation failure
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
            
            // Auto-dismiss error banner after 5 seconds
            Task {
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                await MainActor.run {
                    if showErrorBanner {
                        dismissErrorBanner()
                    }
                }
            }
            
            print("❌ Error creating order: \(error)")
        }
    }
    
    func dismissErrorBanner() {
        showErrorBanner = false
        paymentError = nil
    }
    
    // MARK: - Stock Validation
    
    /// Validates that all items in the cart are still in stock with sufficient quantities
    /// - Returns: A tuple with a boolean indicating if stock is valid and an optional error message
    private func validateCartStock() async -> (isValid: Bool, errorMessage: String?) {
        print("🔍 Validating cart stock levels...")
        
        for cartItem in cart.items {
            do {
                // Fetch the latest product data from the database
                guard let currentProduct = try await supabase.fetchProduct(id: cartItem.product.id) else {
                    print("❌ Product not found: \(cartItem.product.displayName)")
                    return (false, "\(cartItem.product.displayName) is no longer available")
                }
                
                // Check if the cart quantity exceeds available stock
                if cartItem.quantity > currentProduct.quantity {
                    print("❌ Insufficient stock for \(cartItem.product.displayName): requested \(cartItem.quantity), available \(currentProduct.quantity)")
                    
                    if currentProduct.quantity == 0 {
                        return (false, "\(cartItem.product.displayName) is out of stock")
                    } else {
                        return (false, "Only \(currentProduct.quantity) of \(cartItem.product.displayName) in stock (you have \(cartItem.quantity) in cart)")
                    }
                }
                
                print("✅ Stock validated for \(cartItem.product.displayName): \(cartItem.quantity) requested, \(currentProduct.quantity) available")
                
            } catch {
                print("❌ Error fetching product \(cartItem.product.displayName): \(error)")
                return (false, "Unable to verify stock availability. Please try again.")
            }
        }
        
        print("✅ All cart items validated successfully")
        return (true, nil)
    }
    
    // MARK: - Store Credit Methods
    
    /// Applies store credit to the current order
    /// - Parameter amount: Amount of store credit to apply
    func applyStoreCredit(_ amount: Decimal) {
        let maxApplicable = min(amount, cart.subtotal + tipAmount)
        appliedStoreCredit = maxApplicable
        print("💳 Applied store credit: $\(maxApplicable)")
    }
    
    /// Removes applied store credit
    func removeStoreCredit() {
        appliedStoreCredit = 0.0
        print("💳 Removed store credit")
    }
    
    /// Gets the final amount after store credit is applied
    var finalAmount: Decimal {
        let total = cart.subtotal + tipAmount // Include delivery fee
        return max(0, total - appliedStoreCredit)
    }
    
    /// Checks if user has sufficient store credit
    var hasSufficientStoreCredit: Bool {
        guard let currentUser = authViewModel.currentUser else { return false }
        return currentUser.storeCredit >= cart.subtotal + tipAmount
    }
    
    /// Gets the maximum store credit that can be applied
    var maxStoreCreditApplicable: Decimal {
        guard let currentUser = authViewModel.currentUser else { return 0.0 }
        return min(currentUser.storeCredit, cart.subtotal + tipAmount)
    }
    
    /// Updates the user's store credit after applying it to an order
    /// - Parameter amount: Amount of store credit that was applied
    private func updateUserStoreCredit(amount: Decimal) async {
        guard let currentUser = authViewModel.currentUser else { return }
        
        do {
            let newStoreCredit = currentUser.storeCredit - amount
            if let updatedUser = try await supabase.updateUserStoreCredit(userId: currentUser.id, newStoreCredit: newStoreCredit) {
                // Update the current user in AuthViewModel
                authViewModel.currentUser = updatedUser
                print("💳 Updated user store credit: $\(newStoreCredit)")
            }
        } catch {
            print("❌ Error updating user store credit: \(error)")
        }
    }
    
    /// Manually calls the Supabase database function to update order status and inventory
    /// - Parameter orderId: The UUID of the order to update
    private func updateOrderStatusAndInventory(orderId: UUID) async {
        print("🔍 updateOrderStatusAndInventory called with orderId: \(orderId)")
        do {
            print("🔍 Calling supabase.updateOrderStatusAndInventory...")
            let success = try await supabase.updateOrderStatusAndInventory(orderId: orderId)
            print("🔍 supabase.updateOrderStatusAndInventory returned: \(success)")
            if success {
                print("✅ Successfully updated order status and inventory for order: \(orderId)")
            } else {
                print("⚠️ Order status and inventory update returned false for order: \(orderId)")
            }
        } catch {
            print("❌ Error updating order status and inventory: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
        }
    }
}


