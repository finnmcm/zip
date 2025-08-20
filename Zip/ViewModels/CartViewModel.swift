//
//  CartViewModel.swift
//  Zip
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
final class CartViewModel: ObservableObject {
    @Published var items: [CartItem] = []
    @Published var isUpdating: Bool = false
    @Published var errorMessage: String?

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
        refresh()
    }

    func refresh() {
        let descriptor = FetchDescriptor<CartItem>()
        items = (try? context.fetch(descriptor)) ?? []
    }

    func add(product: Product, quantity: Int = 1) {
        if let index = items.firstIndex(where: { $0.productId == product.id }) {
            items[index].quantity += quantity
        } else {
            let newItem = CartItem(productId: product.id, productName: product.name, unitPrice: product.price, quantity: quantity)
            context.insert(newItem)
            items.append(newItem)
        }
        try? context.save()
    }

    func decrement(item: CartItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].quantity = max(1, items[idx].quantity - 1)
        try? context.save()
    }

    func increment(item: CartItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].quantity += 1
        try? context.save()
    }

    func remove(item: CartItem) {
        items.removeAll { $0.id == item.id }
        context.delete(item)
        try? context.save()
    }

    func clear() {
        for item in items { context.delete(item) }
        items.removeAll()
        try? context.save()
    }

    var subtotal: Decimal {
        items.reduce(0) { $0 + ($1.unitPrice * Decimal($1.quantity)) }
    }
}


