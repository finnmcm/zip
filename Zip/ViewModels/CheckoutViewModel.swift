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
    @Published var tipAmount: Decimal = 0.0

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

        let description = "Zip Order"
        let result = await stripe.processPayment(amount: cart.subtotal, tip: tipAmount, description: description, orderId: nil)
        if result.success {
            // Create order with current user (placeholder until real auth wiring)
            let user = User(id: "123", email: "user@example.com", firstName: "User", lastName: "Name", phoneNumber: "")
            let total = cart.subtotal + tipAmount
            let order = Order(
                user: user,
                items: cart.items,
                status: .confirmed,
                rawAmount: cart.subtotal,
                tip: tipAmount,
                totalAmount: total,
                deliveryAddress: "Northwestern Campus"
            )
            orders.append(order)
            lastOrder = order
            cart.clear()
            errorMessage = nil
        } else {
            errorMessage = result.errorMessage ?? "Payment failed. Please try again."
        }
    }
}


