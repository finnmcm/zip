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
        guard supabaseService.isClientConfigured else {
            // Fall back to sample data if Supabase is not configured
            loadProductsFromLocal()
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedProducts = try await supabaseService.fetchProducts()
            products = fetchedProducts
            print("✅ Successfully loaded \(products.count) products from Supabase")
        } catch {
            print("❌ Error loading products from Supabase: \(error)")
            errorMessage = "Failed to load products. Please try again."
            
            // Fall back to sample data on error
            loadProductsFromLocal()
        }
        
        isLoading = false
    }
    
    private func loadProductsFromLocal() {
        print("📱 Loading sample products (Supabase not available)")
        
        // Create sample products with Northwestern student focus
        let sampleProducts = [
            // Drinks
            Product(inventoryName: "cold_brew_coffee", displayName: "Cold Brew Coffee", price: Decimal(3.99), imageURL: nil, category: .drinks),
            Product(inventoryName: "bottled_water", displayName: "Bottled Water", price: Decimal(0.99), imageURL: nil, category: .drinks),
            Product(inventoryName: "energy_drink", displayName: "Energy Drink", price: Decimal(2.49), imageURL: nil, category: .drinks),
            Product(inventoryName: "hot_tea", displayName: "Hot Tea", price: Decimal(1.99), imageURL: nil, category: .drinks),
            Product(inventoryName: "orange_juice", displayName: "Orange Juice", price: Decimal(2.99), imageURL: nil, category: .drinks),
            
            // Snacks
            Product(inventoryName: "protein_bar", displayName: "Protein Bar", price: Decimal(1.99), imageURL: nil, category: .chipscandy),
            Product(inventoryName: "chips", displayName: "Chips", price: Decimal(1.49), imageURL: nil, category: .chipscandy),
            Product(inventoryName: "granola", displayName: "Granola", price: Decimal(2.99), imageURL: nil, category: .chipscandy),
            Product(inventoryName: "nuts_mix", displayName: "Nuts Mix", price: Decimal(3.49), imageURL: nil, category: .chipscandy),
            Product(inventoryName: "popcorn", displayName: "Popcorn", price: Decimal(1.79), imageURL: nil, category: .chipscandy),
            
            // Study Supplies
            Product(inventoryName: "notebook", displayName: "Notebook", price: Decimal(2.49), imageURL: nil, category: .misc),
            Product(inventoryName: "pens_pack", displayName: "Pens (Pack of 3)", price: Decimal(1.99), imageURL: nil, category: .misc),
            Product(inventoryName: "highlighters", displayName: "Highlighters", price: Decimal(2.99), imageURL: nil, category: .misc),
            Product(inventoryName: "sticky_notes", displayName: "Sticky Notes", price: Decimal(1.49), imageURL: nil, category: .misc),
            Product(inventoryName: "index_cards", displayName: "Index Cards", price: Decimal(0.99), imageURL: nil, category: .misc),
            
            // Quick Meals
            Product(inventoryName: "sandwich", displayName: "Sandwich", price: Decimal(4.99), imageURL: nil, category: .foodsnacks),
            Product(inventoryName: "salad", displayName: "Salad", price: Decimal(5.99), imageURL: nil, category: .foodsnacks),
            Product(inventoryName: "soup", displayName: "Soup", price: Decimal(3.99), imageURL: nil, category: .foodsnacks),
            Product(inventoryName: "pizza_slice", displayName: "Pizza Slice", price: Decimal(2.99), imageURL: nil, category: .foodsnacks),
            Product(inventoryName: "burrito", displayName: "Burrito", price: Decimal(6.99), imageURL: nil, category: .foodsnacks),
            
            // Health & Wellness
            Product(inventoryName: "pain_reliever", displayName: "Pain Reliever", price: Decimal(4.99), imageURL: nil, category: .medical),
            Product(inventoryName: "band_aids", displayName: "Band-Aids", price: Decimal(2.99), imageURL: nil, category: .medical),
            Product(inventoryName: "hand_sanitizer", displayName: "Hand Sanitizer", price: Decimal(1.99), imageURL: nil, category: .medical),
            Product(inventoryName: "tissues", displayName: "Tissues", price: Decimal(1.49), imageURL: nil, category: .medical),
            Product(inventoryName: "vitamins", displayName: "Vitamins", price: Decimal(8.99), imageURL: nil, category: .medical)
        ]
        
        products = sampleProducts
        print("📱 Loaded \(products.count) sample products")
    }
}


