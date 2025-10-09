//
//  ShoppingViewModel.swift
//  Zip
//

import Foundation
import SwiftUI

@MainActor
final class ShoppingViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading: Bool = true  // Start as true since products need to be loaded
    @Published var errorMessage: String?
    
    // MARK: - Services
    private let supabaseService = SupabaseService()

    init() {
        // Don't load products immediately - wait for authentication
        print("🛍️ ShoppingViewModel: Initialized with isLoading: \(isLoading)")
    }

    func loadProducts() async {
        print("🛍️ ShoppingViewModel: loadProducts() called")
        print("🛍️ ShoppingViewModel: Current isLoading: \(isLoading), products count: \(products.count)")
        
        isLoading = true
        errorMessage = nil
        
        do {
            print("🛍️ ShoppingViewModel: Starting to fetch products...")
            let fetchedProducts = try await supabaseService.fetchProducts()
            products = fetchedProducts
            print("✅ ShoppingViewModel: Successfully loaded \(products.count) products from Supabase")
            
            // Debug: Print image information for each product
            for product in products {
                print("🔍 Product: \(product.displayName)")
                print("   - Primary Image URL: \(product.primaryImageURL ?? "nil")")
                print("   - Images count: \(product.images.count)")
                for (index, image) in product.images.enumerated() {
                    print("   - Image \(index): \(image.imageURL ?? "nil")")
                }
            }
        } catch {
            print("❌ ShoppingViewModel: Error loading products from Supabase: \(error)")
            errorMessage = "Failed to load products. Please try again."
            
        }
        
        isLoading = false
        print("🛍️ ShoppingViewModel: loadProducts() completed. isLoading: \(isLoading), products count: \(products.count), errorMessage: \(errorMessage ?? "nil")")
    }
    

}


