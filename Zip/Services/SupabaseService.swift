//
//  SupabaseService.swift
//  Zip
//

import Foundation
import Supabase

protocol SupabaseServiceProtocol {
    func fetchProducts() async throws -> [Product]
    func fetchProduct(id: UUID) async throws -> Product?
    func createUser(_ user: User) async throws -> User
    func updateUser(_ user: User) async throws -> User
    func fetchUser(id: UUID) async throws -> User?
    func createOrder(_ order: Order) async throws -> Order
    func fetchUserOrders(userId: UUID) async throws -> [Order]
    func addToCart(_ cartItem: CartItem) async throws -> CartItem
    func removeFromCart(id: UUID) async throws -> Bool
    func fetchUserCart(userId: UUID) async throws -> [CartItem]
    func clearUserCart(userId: UUID) async throws -> Bool
}

final class SupabaseService: SupabaseServiceProtocol {
    // MARK: - Properties
    private var supabase: SupabaseClient?
    private let configuration = Configuration.shared
    
    // MARK: - Initialization
    init() {
        setupSupabaseClient()
    }
    
    // MARK: - Setup
    private func setupSupabaseClient() {
        guard let url = URL(string: configuration.supabaseURL) else {
            print("❌ Invalid Supabase URL: \(configuration.supabaseURL)")
            return
        }
        
        // Check if we have valid credentials
        guard !configuration.supabaseAnonKey.isEmpty && configuration.supabaseAnonKey != "YOUR_DEV_SUPABASE_ANON_KEY" else {
            print("⚠️ Supabase credentials not configured. Using mock data.")
            return
        }
        
        self.supabase = SupabaseClient(
            supabaseURL: url,
            supabaseKey: configuration.supabaseAnonKey
        )
        
        print("✅ Supabase client initialized successfully")
    }
    
    // MARK: - Client Status
    var isClientConfigured: Bool {
        return supabase != nil
    }
    
    // MARK: - Product Operations
    func fetchProducts() async throws -> [Product] {
        // Try to use real Supabase client if configured
        if let supabase = supabase {
            do {
                let response: [Product] = try await supabase
                    .from("products")
                    .select()
                    .execute()
                    .value
                
                print("✅ Fetched \(response.count) products from Supabase")
                return response
            } catch {
                print("❌ Error fetching products from Supabase: \(error)")
                // Fall back to mock data if Supabase fails
                print("⚠️ Falling back to mock data")
            }
        }
        
        // Return mock data if Supabase is not configured or fails
        print("📱 Using mock product data")
        return [
            // Drinks
            Product(inventoryName: "coffee", displayName: "Coffee", price: Decimal(1.99), imageURL: nil, category: .drinks),
            Product(inventoryName: "water", displayName: "Water", price: Decimal(1.49), imageURL: nil, category: .drinks),
            Product(inventoryName: "soda", displayName: "Soda", price: Decimal(1.79), imageURL: nil, category: .drinks),
            Product(inventoryName: "energy_drink", displayName: "Energy Drink", price: Decimal(2.99), imageURL: nil, category: .drinks),
            Product(inventoryName: "juice", displayName: "Juice", price: Decimal(2.49), imageURL: nil, category: .drinks),
            
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
    }
    
    func fetchProduct(id: UUID) async throws -> Product? {
        // Try to use real Supabase client if configured
        if let supabase = supabase {
            do {
                let response: [Product] = try await supabase
                    .from("products")
                    .select()
                    .eq("id", value: id)
                    .execute()
                    .value
                
                return response.first
            } catch {
                print("❌ Error fetching product from Supabase: \(error)")
                // Fall back to mock data if Supabase fails
            }
        }
        
        // For now, return nil (will be implemented with Supabase)
        return nil
    }
    
    // MARK: - User Operations
    func createUser(_ user: User) async throws -> User {
        // TODO: Implement when Supabase is configured
        throw SupabaseError.notImplemented
    }
    
    func updateUser(_ user: User) async throws -> User {
        // TODO: Implement when Supabase is configured
        throw SupabaseError.notImplemented
    }
    
    func fetchUser(id: UUID) async throws -> User? {
        // TODO: Implement when Supabase is configured
        throw SupabaseError.notImplemented
    }
    
    // MARK: - Order Operations
    func createOrder(_ order: Order) async throws -> Order {
        // TODO: Implement when Supabase is configured
        throw SupabaseError.notImplemented
    }
    
    func fetchUserOrders(userId: UUID) async throws -> [Order] {
        // TODO: Implement when Supabase is configured
        throw SupabaseError.notImplemented
    }
    
    // MARK: - Cart Operations
    func addToCart(_ cartItem: CartItem) async throws -> CartItem {
        // TODO: Implement when Supabase is configured
        throw SupabaseError.notImplemented
    }
    
    func removeFromCart(id: UUID) async throws -> Bool {
        // TODO: Implement when Supabase is configured
        throw SupabaseError.notImplemented
    }
    
    func fetchUserCart(userId: UUID) async throws -> [CartItem] {
        // TODO: Implement when Supabase is configured
        throw SupabaseError.notImplemented
    }
    
    func clearUserCart(userId: UUID) async throws -> Bool {
        // TODO: Implement when Supabase is configured
        throw SupabaseError.notImplemented
    }
}

// MARK: - Supabase Errors
enum SupabaseError: LocalizedError {
    case clientNotConfigured
    case notImplemented
    case networkError(Error)
    case decodingError(Error)
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .clientNotConfigured:
            return "Supabase client is not configured. Please check your configuration."
        case .notImplemented:
            return "This feature is not yet implemented with Supabase."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Data decoding error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server."
        }
    }
}


