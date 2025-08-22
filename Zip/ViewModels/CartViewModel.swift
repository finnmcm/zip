//
//  CartViewModel.swift
//  Zip
//

import Foundation
import SwiftUI

@MainActor
final class CartViewModel: ObservableObject {
    @Published var items: [CartItem] = []
    @Published var isUpdating: Bool = false
    @Published var errorMessage: String?

    private let databaseManager = DatabaseManager.shared

    init() {
        refresh()
    }

    func refresh() {
        items = databaseManager.loadCartItems()
    }

    func add(product: Product, quantity: Int = 1) {
        if let existingItem = items.first(where: { $0.product.id == product.id }) {
            existingItem.quantity += quantity
            // Provide haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        } else {
            let newItem = CartItem(product: product, quantity: quantity, userId: UUID()) // Using placeholder UUID for now
            items.append(newItem)
            // Provide haptic feedback for new item
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
        saveCart()
    }

    func decrement(item: CartItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        
        if items[idx].quantity <= 1 {
            // Remove item if quantity would become 0 or less
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            remove(item: item)
        } else {
            items[idx].quantity -= 1
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            saveCart()
        }
    }

    func increment(item: CartItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].quantity += 1
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        saveCart()
    }

    func remove(item: CartItem) {
        items.removeAll { $0.id == item.id }
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        saveCart()
    }

    func clear() {
        items.removeAll()
        saveCart()
    }
    
    private func saveCart() {
        databaseManager.saveCartItems(items)
    }

    var subtotal: Decimal {
        items.reduce(0) { $0 + ($1.product.price * Decimal($1.quantity)) }
    }
}


