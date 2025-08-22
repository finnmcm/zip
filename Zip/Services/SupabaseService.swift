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
            Product(name: "Cold Brew Coffee", price: Decimal(3.99), imageURL: nil, category: "Drinks", inStock: true),
            Product(name: "Bottled Water", price: Decimal(0.99), imageURL: nil, category: "Drinks", inStock: true),
            Product(name: "Energy Drink", price: Decimal(2.49), imageURL: nil, category: "Drinks", inStock: true),
            Product(name: "Hot Tea", price: Decimal(1.99), imageURL: nil, category: "Drinks", inStock: true),
            Product(name: "Orange Juice", price: Decimal(2.99), imageURL: nil, category: "Drinks", inStock: true),
            
            // Snacks
            Product(name: "Protein Bar", price: Decimal(1.99), imageURL: nil, category: "Snacks", inStock: true),
            Product(name: "Chips", price: Decimal(1.49), imageURL: nil, category: "Snacks", inStock: true),
            Product(name: "Granola", price: Decimal(2.99), imageURL: nil, category: "Snacks", inStock: true),
            Product(name: "Nuts Mix", price: Decimal(3.49), imageURL: nil, category: "Snacks", inStock: true),
            Product(name: "Popcorn", price: Decimal(1.79), imageURL: nil, category: "Snacks", inStock: true),
            
            // Study Supplies
            Product(name: "Notebook", price: Decimal(2.49), imageURL: nil, category: "Study", inStock: true),
            Product(name: "Pens (Pack of 3)", price: Decimal(1.99), imageURL: nil, category: "Study", inStock: true),
            Product(name: "Highlighters", price: Decimal(2.99), imageURL: nil, category: "Study", inStock: true),
            Product(name: "Sticky Notes", price: Decimal(1.49), imageURL: nil, category: "Study", inStock: true),
            Product(name: "Index Cards", price: Decimal(0.99), imageURL: nil, category: "Study", inStock: true),
            
            // Quick Meals
            Product(name: "Sandwich", price: Decimal(4.99), imageURL: nil, category: "Meals", inStock: true),
            Product(name: "Salad", price: Decimal(5.99), imageURL: nil, category: "Meals", inStock: true),
            Product(name: "Soup", price: Decimal(3.99), imageURL: nil, category: "Meals", inStock: true),
            Product(name: "Pizza Slice", price: Decimal(2.99), imageURL: nil, category: "Meals", inStock: true),
            Product(name: "Burrito", price: Decimal(6.99), imageURL: nil, category: "Meals", inStock: true),
            
            // Health & Wellness
            Product(name: "Pain Reliever", price: Decimal(4.99), imageURL: nil, category: "Health", inStock: true),
            Product(name: "Band-Aids", price: Decimal(2.99), imageURL: nil, category: "Health", inStock: true),
            Product(name: "Hand Sanitizer", price: Decimal(1.99), imageURL: nil, category: "Health", inStock: true),
            Product(name: "Tissues", price: Decimal(1.49), imageURL: nil, category: "Health", inStock: true),
            Product(name: "Vitamins", price: Decimal(8.99), imageURL: nil, category: "Health", inStock: true)
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


