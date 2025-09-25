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
    
    // MARK: - Services
    private let supabaseService = SupabaseService()

    init() {
        // Don't load products immediately - wait for authentication
    }

    func loadProducts() async {
        
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedProducts = try await supabaseService.fetchProducts()
            products = fetchedProducts
            print("✅ Successfully loaded \(products.count) products from Supabase")
            
            // Debug: Print image information for each product
           /* for product in products {
                print("🔍 Product: \(product.displayName)")
                print("   - Primary Image URL: \(product.primaryImageURL ?? "nil")")
                print("   - Images count: \(product.images.count)")
                for (index, image) in product.images.enumerated() {
                    print("   - Image \(index): \(image.imageURL)")
                }
            }*/
        } catch {
            print("❌ Error loading products from Supabase: \(error)")
            errorMessage = "Failed to load products. Please try again."
            
        }
        
        isLoading = false
    }
    

}


