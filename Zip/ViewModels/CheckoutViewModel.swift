//
//  CheckoutViewModel.swift
//  Zip
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
final class CheckoutViewModel: ObservableObject {
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?
    @Published var lastOrder: Order?

    private let stripe: StripeServiceProtocol
    private let context: ModelContext
    let cart: CartViewModel

    init(stripe: StripeServiceProtocol = StripeService(), context: ModelContext, cart: CartViewModel) {
        self.stripe = stripe
        self.context = context
        self.cart = cart
    }

    func confirmPayment() async {
        guard cart.subtotal > 0 else { return }
        isProcessing = true
        defer { isProcessing = false }
        do {
            _ = try await stripe.processPayment(amount: cart.subtotal)
            let order = Order(total: cart.subtotal)
            context.insert(order)
            try context.save()
            lastOrder = order
            cart.clear()
        } catch {
            errorMessage = "Payment failed. Please try again."
        }
    }
}


