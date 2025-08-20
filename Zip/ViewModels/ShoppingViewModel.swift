//
//  ShoppingViewModel.swift
//  Zip
//

import Foundation
import SwiftUI

@MainActor
final class ShoppingViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let service: SupabaseServiceProtocol

    init(service: SupabaseServiceProtocol = SupabaseService()) {
        self.service = service
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await service.fetchProducts()
        } catch {
            errorMessage = "Failed to load products"
        }
    }
}


