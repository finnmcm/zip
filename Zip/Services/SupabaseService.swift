//
//  SupabaseService.swift
//  Zip
//

import Foundation
import Supabase

protocol SupabaseServiceProtocol {
    func fetchProducts() async throws -> [Product]
    func fetchProduct(id: UUID) async throws -> Product?
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
                    .order("created_at", ascending: false)
                    .execute()
                    .value
                
                print("✅ Successfully fetched \(response.count) products from Supabase")
                return response
            } catch {
                print("❌ Error fetching products from Supabase: \(error)")
                throw SupabaseError.networkError(error)
            }
        }
        
        // If Supabase client is not configured, throw an error
        throw SupabaseError.clientNotConfigured
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
    case databaseError(String)
    
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
        case .databaseError(let message):
            return "Database error: \(message)"
        }
    }
}


