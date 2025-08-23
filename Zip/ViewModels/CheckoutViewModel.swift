//
//  CheckoutViewModel.swift
//  Zip
//

import Foundation
import SwiftUI

@MainActor
final class CheckoutViewModel: ObservableObject {
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?
    @Published var lastOrder: Order?

    private let stripe: StripeServiceProtocol
    // In-memory storage for testing
    private var orders: [Order] = []
    let cart: CartViewModel

    init(stripe: StripeServiceProtocol = StripeService(), cart: CartViewModel) {
        self.stripe = stripe
        self.cart = cart
    }

    func confirmPayment() async {
        guard cart.subtotal > 0 else { return }
        isProcessing = true
        defer { isProcessing = false }
        do {
            _ = try await stripe.processPayment(amount: cart.subtotal)
            
            // Create order with current user (assuming we have one)
            let user = User(email: "user@example.com", firstName: "User", lastName: "Name", phoneNumber: "") // This should come from AuthViewModel
            let order = Order(
                user: user,
                items: cart.items,
                status: .confirmed,
                rawAmount: cart.subtotal,
                deliveryFee: 0.99,
                tip: 0.0,
                totalAmount: cart.subtotal,
                tax: cart.subtotal * 0.08,
                deliveryAddress: "Northwestern Campus"
            )
            
            // Add to in-memory storage
            orders.append(order)
            
            lastOrder = order
            cart.clear()
        } catch {
            errorMessage = "Payment failed. Please try again."
        }
    }
}


