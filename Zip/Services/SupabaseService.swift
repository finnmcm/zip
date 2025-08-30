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
    
    // Database models for Supabase operations
    private struct OrderData: Codable {
        let id: String
        let user_id: String
        let status: String
        let raw_amount: Double
        let tip: Double
        let total_amount: Double
        let created_at: String
        let delivery_address: String
        let delivery_instructions: String?
        let is_campus_delivery: Bool
        let updated_at: String
        let payment_intent_id: String?
    }
    
    private struct OrderItemData: Codable {
        let id: String
        let order_id: String
        let product_id: String
        let quantity: Int
        let unit_price: Double
        let total_price: Double
        let created_at: String
        let updated_at: String
    }
    
    func createOrder(_ order: Order) async throws -> Order {
        // Check if Supabase client is configured
        guard let supabase = supabase else {
            throw SupabaseError.clientNotConfigured
        }
        
        do {
            // Create order data for Supabase
            let orderData = OrderData(
                id: order.id.uuidString,
                user_id: order.user.id,
                status: order.status.rawValue,
                raw_amount: NSDecimalNumber(decimal: order.rawAmount).doubleValue,
                tip: NSDecimalNumber(decimal: order.tip).doubleValue,
                total_amount: NSDecimalNumber(decimal: order.totalAmount).doubleValue,
                created_at: ISO8601DateFormatter().string(from: order.createdAt),
                delivery_address: order.deliveryAddress,
                delivery_instructions: order.deliveryInstructions,
                is_campus_delivery: order.isCampusDelivery,
                updated_at: ISO8601DateFormatter().string(from: order.updatedAt),
                payment_intent_id: order.paymentIntentId
            )
            
            // Insert the order into the orders table
            try await supabase
                .from("orders")
                .insert(orderData)
                .execute()
            
            print("✅ Successfully created order with ID: \(order.id)")
            
            // Now create order items for each cart item
            for cartItem in order.items {
                let orderItemData = OrderItemData(
                    id: UUID().uuidString,
                    order_id: order.id.uuidString,
                    product_id: cartItem.product.id.uuidString,
                    quantity: cartItem.quantity,
                    unit_price: NSDecimalNumber(decimal: cartItem.product.price).doubleValue,
                    total_price: NSDecimalNumber(decimal: cartItem.product.price * Decimal(cartItem.quantity)).doubleValue,
                    created_at: ISO8601DateFormatter().string(from: Date()),
                    updated_at: ISO8601DateFormatter().string(from: Date())
                )
                
                try await supabase
                    .from("order_items")
                    .insert(orderItemData)
                    .execute()
            }
            
            print("✅ Successfully created order items for order: \(order.id)")
            
            // Return the created order
            return order
            
        } catch {
            print("❌ Error creating order in Supabase: \(error)")
            throw SupabaseError.networkError(error)
        }
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


