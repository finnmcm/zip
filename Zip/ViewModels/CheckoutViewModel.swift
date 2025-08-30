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
    @Published var tipAmount: Decimal = 0.0
    @Published var isCampusDelivery: Bool = true
    @Published var selectedBuilding: String = ""
    @Published var selectedAddress: String = ""
    @Published var deliveryInstructions: String = ""
    @Published var showErrorBanner: Bool = false
    @Published var paymentError: String?

    private let stripe: StripeServiceProtocol
    private let supabase: SupabaseServiceProtocol
    private let authViewModel: AuthViewModel
    // In-memory storage for testing
    private var orders: [Order] = []
    let cart: CartViewModel

    init(stripe: StripeServiceProtocol = StripeService(), 
         supabase: SupabaseServiceProtocol = SupabaseService(), 
         cart: CartViewModel,
         authViewModel: AuthViewModel) {
        self.stripe = stripe
        self.supabase = supabase
        self.cart = cart
        self.authViewModel = authViewModel
    }

    func confirmPayment() async {
        guard cart.subtotal > 0 else { return }
        guard let currentUser = authViewModel.currentUser else {
            errorMessage = "Please log in to complete your order."
            return
        }
        
        isProcessing = true
        defer { isProcessing = false }

        // Create the order first
        let total = cart.subtotal + tipAmount
        let order = Order(
            user: currentUser,
            items: cart.items,
            status: .pending,
            rawAmount: cart.subtotal,
            tip: tipAmount,
            totalAmount: total,
            deliveryAddress: isCampusDelivery ? selectedBuilding : selectedAddress,
            createdAt: Date(),
            deliveryInstructions: deliveryInstructions,
            isCampusDelivery: isCampusDelivery
        )
        
        do {
            // Create order in Supabase backend
            let createdOrder = try await supabase.createOrder(order)
            lastOrder = createdOrder
            
            // Now process the payment
            let description = "Zip Order #\(createdOrder.id.uuidString.prefix(8))"
            let result = await stripe.processPayment(
                amount: cart.subtotal, 
                tip: tipAmount, 
                description: description, 
                orderId: createdOrder.id
            )
            
            if result.success {
                // Payment successful - order is already created in Supabase
                orders.append(createdOrder)
                cart.clear()
                errorMessage = nil
                paymentError = nil
                showErrorBanner = false
                
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
}


