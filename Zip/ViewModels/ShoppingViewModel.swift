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

    init() {
        // Load products immediately from local database
        loadProductsFromLocal()
    }

    func loadProducts() async {
        // This method is kept for compatibility but now loads from local storage
        loadProductsFromLocal()
    }
    
    private func loadProductsFromLocal() {
        isLoading = true
        defer { isLoading = false }
        
        // Load products from local DatabaseManager
        let localProducts = DatabaseManager.shared.loadProducts()
        
        if localProducts.isEmpty {
            // If no products exist, create sample data
            DatabaseManager.shared.resetDatabase()
            products = DatabaseManager.shared.loadProducts()
        } else {
            products = localProducts
        }
        
        print("📱 Loaded \(products.count) products from local database")
    }
}


