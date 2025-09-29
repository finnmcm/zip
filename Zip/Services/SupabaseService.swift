//
//  SupabaseService.swift
//  Zip
//

import Foundation
import Supabase

// Helper structs for database queries
struct OrderData: Codable {
    let id: String
    let user_id: String
    let status: String
    let raw_amount: Double
    let tip: Double
    let total_amount: Double
    let created_at: String
    let updated_at: String
    let delivery_address: String
    let delivery_instructions: String?
    let is_campus_delivery: Bool
    let payment_intent_id: String?
    let fulfilled_by: String?
}

struct FCMTokenData: Codable {
    let token: String
}
import UIKit

// MARK: - Zipper Statistics Result
struct ZipperStatsResult: Codable {
    let zippers: [ZipperStats]
    let totalRevenue: Double
    
    struct ZipperStats: Codable {
        let id: String
        let user: User
        let ordersHandled: Int
        let revenue: Double
    }
}



protocol SupabaseServiceProtocol {
    func fetchProducts() async throws -> [Product]
    func fetchProduct(id: UUID) async throws -> Product?
    func fetchProductImages() async throws -> [ProductImage]
    func fetchProductImages(for productIds: [UUID]) async throws -> [ProductImage]
    func createOrder(_ order: Order) async throws -> Order
    func fetchUserOrders(userId: String) async throws -> [Order]
    func fetchOrderStatus(orderId: UUID) async throws -> Order?
    func addToCart(_ cartItem: CartItem) async throws -> CartItem
    func removeFromCart(id: UUID) async throws -> Bool
    func fetchUserCart(userId: String) async throws -> [CartItem]
    func clearUserCart(userId: String) async throws -> Bool
    func fetchUser(userId: String) async throws -> User?
    func updateUserStoreCredit(userId: String, newStoreCredit: Decimal) async throws -> User?
    func updateOrderStatusAndInventory(orderId: UUID) async throws -> Bool
    
    // MARK: - Zipper Operations
    func fetchPendingOrders() async throws -> [Order]
    func fetchActiveOrderForZipper(zipperId: String) async throws -> Order?
    func acceptOrder(orderId: UUID, zipperId: String) async throws -> Bool
    func completeOrder(orderId: UUID, photo: UIImage?) async throws -> Bool
    func uploadOrderCompletionPhoto(orderId: UUID, photo: UIImage) async throws -> String?
    
    // MARK: - Statistics Operations
    func fetchNumUsers() async throws -> Int
    func fetchZipperStats() async throws -> ZipperStatsResult
    
    
    // MARK: - Inventory Operations
    func fetchLowStockItems() async throws -> [Product]
    
    // MARK: - Bug Report Operations
    func submitBugReport(userId: String, title: String, description: String) async throws -> Bool
    
    // MARK: - Delivery Image Operations
    func fetchDeliveryImageURL(for orderId: UUID) async throws -> String?
    func fetchDeliveryImageURLs(for orderIds: [UUID]) async throws -> [UUID: String]
    
    // MARK: - FCM Token Operations
    func registerFCMToken(token: String, deviceId: String, platform: String, appVersion: String) async throws -> Bool
    func sendPushNotification(fcmTokens: [String], title: String, body: String, data: [String: String]?, priority: String?, sound: String?, badge: Int?) async throws -> Bool
    func fetchZipperFCMTokens() async throws -> [String]
    func notifyZippersOfNewOrder(_ order: Order) async throws -> Bool
}

final class SupabaseService: SupabaseServiceProtocol {
    // MARK: - Properties
    static let shared = SupabaseService()
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
                print("🔍 SupabaseService: Fetching products from database...")
                let response: [Product] = try await supabase
                    .from("products")
                    .select()
                    .order("created_at", ascending: false)
                    .execute()
                    .value
                    
                
                print("✅ Successfully fetched \(response.count) products from Supabase")
                if response.isEmpty {
                    print("⚠️ No products found in database - this might be expected if no products are added yet")
                }
                
                // Fetch product images and assign them to products
                let productIds = response.map { $0.id }
                let productImages = try await fetchProductImages(for: productIds)
                
                // Create a dictionary to group images by product ID
                let imagesByProductId = Dictionary(grouping: productImages) { $0.productId }
                
                // Assign images to their respective products
                for product in response {
                    product.images = imagesByProductId[product.id] ?? []
                }
                
                print("✅ Successfully assigned \(productImages.count) images to \(response.count) products")
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
                    
                
                guard let product = response.first else {
                    return nil
                }
                
                // Fetch product images for this specific product
                let productImages = try await fetchProductImages(for: [id])
                product.images = productImages
                
                print("✅ Successfully fetched product \(product.displayName) with \(productImages.count) images")
                return product
            } catch {
                print("❌ Error fetching product from Supabase: \(error)")
                // Fall back to mock data if Supabase fails
            }
        }
        
        // For now, return nil (will be implemented with Supabase)
        return nil
    }
    
    func fetchProductImages() async throws -> [ProductImage] {
        // Try to use real Supabase client if configured
        if let supabase = supabase {
            do {
                let response: [ProductImage] = try await supabase
                    .from("product_images")
                    .select()
                    .order("created_at", ascending: true)
                    .execute()
                    .value
                
                print("✅ Successfully fetched \(response.count) product images from Supabase")
                return response
            } catch {
                print("❌ Error fetching product images from Supabase: \(error)")
                throw SupabaseError.networkError(error)
            }
        }
        
        // If Supabase client is not configured, throw an error
        throw SupabaseError.clientNotConfigured
    }
    
    func fetchProductImages(for productIds: [UUID]) async throws -> [ProductImage] {
        // Try to use real Supabase client if configured
        if let supabase = supabase {
            do {
                let response: [ProductImage] = try await supabase
                    .from("product_images")
                    .select()
                    .in("product_id", values: productIds.map { $0.uuidString })
                    .order("created_at", ascending: true)
                    .execute()
                    .value
                    
                
                print("✅ Successfully fetched \(response.count) product images for \(productIds.count) products from Supabase")
                return response
            } catch {
                print("❌ Error fetching product images from Supabase: \(error)")
                throw SupabaseError.networkError(error)
            }
        }
        
        // If Supabase client is not configured, throw an error
        throw SupabaseError.clientNotConfigured
    }
    
    func fetchLowStockItems() async throws -> [Product] {
        // Try to use real Supabase client if configured
        if let supabase = supabase {
            do {
                let response: [Product] = try await supabase
                    .from("products")
                    .select()
                    .lte("quantity", value: 2)
                    .order("quantity", ascending: true)
                    .execute()
                    .value
                    
                
                print("✅ Successfully fetched \(response.count) low stock items from Supabase")
                
                // Fetch product images and assign them to products
                let productIds = response.map { $0.id }
                let productImages = try await fetchProductImages(for: productIds)
                
                // Create a dictionary to group images by product ID
                let imagesByProductId = Dictionary(grouping: productImages) { $0.productId }
                
                // Assign images to their respective products
                for product in response {
                    product.images = imagesByProductId[product.id] ?? []
                }
                
                print("✅ Successfully assigned \(productImages.count) images to \(response.count) low stock products")
                return response
            } catch {
                print("❌ Error fetching low stock items from Supabase: \(error)")
                throw SupabaseError.networkError(error)
            }
        }
        
        // If Supabase client is not configured, throw an error
        throw SupabaseError.clientNotConfigured
    }
    
    // MARK: - Order Operations
    
    // Database models for Supabase operations
    // Minimal struct for completeOrder function
    private struct OrderCompletionData: Codable {
        let id: String
        let fulfilled_by: String?
        let total_amount: Double
    }
    
    // Minimal struct for acceptOrder function
    private struct OrderAcceptData: Codable {
        let id: String
    }
    
    // Minimal struct for notification function
    private struct OrderNotificationData: Codable {
        let user_id: String
        let total_amount: Double
    }
    
    // Struct for zipper statistics update
    private struct ZipperData: Codable {
        let id: String
        let orders_handled: Int
        let revenue: Double
    }
    
    // Simple struct for just zipper ID
    private struct ZipperIdData: Codable {
        let id: String
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
    
    private struct ProductData: Codable {
        let id: String
        let inventoryName: String
        let displayName: String
        let price: Double
        let quantity: Int
        let imageURL: String?
        let category: String
        let created_at: String
        let updated_at: String
    }
    
    private struct BugReportData: Codable {
        let id: String
        let user_id: String
        let title: String
        let description: String
        let created_at: String
    }
    
    func createOrder(_ order: Order) async throws -> Order {
        print("🔔 DEBUG: createOrder function called with order ID: \(order.id)")
        // Check if Supabase client is configured
        guard let supabase = supabase else {
            print("❌ DEBUG: Supabase client not configured in createOrder")
            throw SupabaseError.clientNotConfigured
        }
        print("🔔 DEBUG: Supabase client is configured, proceeding with order creation")
        
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
                updated_at: ISO8601DateFormatter().string(from: order.updatedAt), delivery_address: order.deliveryAddress,
                delivery_instructions: order.deliveryInstructions,
                is_campus_delivery: order.isCampusDelivery,
                payment_intent_id: order.paymentIntentId,
                fulfilled_by: order.fulfilledBy?.uuidString
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
    
    func fetchUserOrders(userId: String) async throws -> [Order] {
        // Check for cancellation early
        try Task.checkCancellation()
        
        // Check if Supabase client is configured
        guard let supabase = supabase else {
            throw SupabaseError.clientNotConfigured
        }
        
        do {
            // Fetch orders for the user
            let ordersResponse: [OrderData] = try await supabase
                .from("orders")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value
                
            
            var orders: [Order] = []
            
            // Check for cancellation after fetching orders
            try Task.checkCancellation()
            
            // Process each order and fetch its items
            for orderData in ordersResponse {
                // Check for cancellation
                try Task.checkCancellation()
                
                // Fetch order items for this order
                let orderItemsResponse: [OrderItemData] = try await supabase
                    .from("order_items")
                    .select()
                    .eq("order_id", value: orderData.id)
                    .execute()
                    .value
                    
                
                // Convert order items to CartItems
                var cartItems: [CartItem] = []
                for itemData in orderItemsResponse {
                    // Fetch the product for this item
                    let productResponse: [ProductData] = try await supabase
                        .from("products")
                        .select()
                        .eq("id", value: itemData.product_id)
                        .execute()
                        .value
                        
                    
                    if let productData = productResponse.first {
                        // Parse product category
                        guard let category = ProductCategory(rawValue: productData.category) else {
                            print("⚠️ Unknown product category: \(productData.category)")
                            continue
                        }
                        
                        // Parse dates
                        let dateFormatter = ISO8601DateFormatter()
                        let productCreatedAt = dateFormatter.date(from: productData.created_at) ?? Date()
                        let productUpdatedAt = dateFormatter.date(from: productData.updated_at) ?? Date()
                        
                        // Create Product object
                        let product = Product(
                            id: UUID(uuidString: productData.id) ?? UUID(),
                            inventoryName: productData.inventoryName,
                            displayName: productData.displayName,
                            price: Decimal(productData.price),
                            quantity: productData.quantity,
                            imageURL: productData.imageURL,
                            images: [], // Images will be populated separately if needed
                            category: category,
                            createdAt: productCreatedAt,
                            updatedAt: productUpdatedAt
                        )
                        
                        // Create CartItem
                        let cartItem = CartItem(
                            product: product,
                            quantity: itemData.quantity,
                            userId: UUID(uuidString: userId) ?? UUID()
                        )
                        cartItems.append(cartItem)
                    }
                }
                
                // Check for cancellation before creating order
                try Task.checkCancellation()
                
                // Parse dates
                let dateFormatter = ISO8601DateFormatter()
                let createdAt = dateFormatter.date(from: orderData.created_at) ?? Date()
                let updatedAt = dateFormatter.date(from: orderData.updated_at) ?? Date()
                
                // Create User object (we'll need to fetch this from users table)
                // For now, create a minimal user object with the ID we have
                let user = User(
                    id: orderData.user_id,
                    email: "", // Will be populated when we fetch user details
                    firstName: "", // Will be populated when we fetch user details
                    lastName: "", // Will be populated when we fetch user details
                    phoneNumber: "", // Will be populated when we fetch user details
                    storeCredit: 0.0,
                    verified: false, // Will be populated when we fetch user details
                    fcmToken: nil,
                    createdAt: createdAt,
                    updatedAt: updatedAt
                )
                
                // Parse OrderStatus
                guard let status = OrderStatus(rawValue: orderData.status) else {
                    print("⚠️ Unknown order status: \(orderData.status)")
                    continue
                }
                
                // Only add orders that are NOT pending to the user's history
                if status == .pending {
                    print("⏭️ Skipping pending order: \(orderData.id)")
                    continue
                }
                
                // Create Order object
                let order = Order(
                    id: UUID(uuidString: orderData.id) ?? UUID(),
                    user: user,
                    items: cartItems,
                    status: status,
                    rawAmount: Decimal(orderData.raw_amount),
                    tip: Decimal(orderData.tip),
                    totalAmount: Decimal(orderData.total_amount),
                    deliveryAddress: orderData.delivery_address,
                    createdAt: createdAt,
                    estimatedDeliveryTime: nil, // Will be added when we have this field
                    actualDeliveryTime: nil, // Will be added when we have this field
                    paymentIntentId: orderData.payment_intent_id,
                    updatedAt: updatedAt,
                    deliveryInstructions: orderData.delivery_instructions,
                    isCampusDelivery: orderData.is_campus_delivery,
                    fulfilledBy: orderData.fulfilled_by != nil ? UUID(uuidString: orderData.fulfilled_by!) : nil
                )
                
                orders.append(order)
            }
            
            print("✅ Successfully fetched \(orders.count) orders for user: \(userId)")
            return orders
            
        } catch {
            print("❌ Error fetching user orders from Supabase: \(error)")
            throw SupabaseError.networkError(error)
        }
    }
    
    func fetchOrderStatus(orderId: UUID) async throws -> Order? {
        // Check if Supabase client is configured
        guard let supabase = supabase else {
            throw SupabaseError.clientNotConfigured
        }
        
        do {
            // Fetch the order data
            let orderData: OrderData? = try await supabase
                .from("orders")
                .select()
                .eq("id", value: orderId.uuidString.lowercased())
                .single()
                .execute()
                .value
                
            
            if let orderData = orderData {
                // Fetch order items for this order
                let orderItemsResponse: [OrderItemData] = try await supabase
                    .from("order_items")
                    .select()
                    .eq("order_id", value: orderData.id)
                    .execute()
                    .value
                    
                
                // Convert order items to CartItems
                var cartItems: [CartItem] = []
                for itemData in orderItemsResponse {
                    // Fetch the product for this item
                    let productResponse: [ProductData] = try await supabase
                        .from("products")
                        .select()
                        .eq("id", value: itemData.product_id)
                        .execute()
                        .value
                        
                    
                    if let productData = productResponse.first {
                        // Parse product category
                        guard let category = ProductCategory(rawValue: productData.category) else {
                            print("⚠️ Unknown product category: \(productData.category)")
                            continue
                        }
                        
                        // Parse dates
                        let dateFormatter = ISO8601DateFormatter()
                        let productCreatedAt = dateFormatter.date(from: productData.created_at) ?? Date()
                        let productUpdatedAt = dateFormatter.date(from: productData.updated_at) ?? Date()
                        
                        // Create Product object
                        let product = Product(
                            id: UUID(uuidString: productData.id) ?? UUID(),
                            inventoryName: productData.inventoryName,
                            displayName: productData.displayName,
                            price: Decimal(productData.price),
                            quantity: productData.quantity,
                            imageURL: productData.imageURL,
                            images: [], // Images will be populated separately if needed
                            category: category,
                            createdAt: productCreatedAt,
                            updatedAt: productUpdatedAt
                        )
                        
                        // Create CartItem
                        let cartItem = CartItem(
                            product: product,
                            quantity: itemData.quantity,
                            userId: UUID(uuidString: orderData.user_id) ?? UUID() // Assuming user_id is the user who created the order
                        )
                        cartItems.append(cartItem)
                    }
                }
                
                // Parse dates
                let dateFormatter = ISO8601DateFormatter()
                let createdAt = dateFormatter.date(from: orderData.created_at) ?? Date()
                let updatedAt = dateFormatter.date(from: orderData.updated_at) ?? Date()
                
                // Create User object (we'll need to fetch this from users table)
                // For now, create a minimal user object with the ID we have
                let user = User(
                    id: orderData.user_id,
                    email: "", // Will be populated when we fetch user details
                    firstName: "", // Will be populated when we fetch user details
                    lastName: "", // Will be populated when we fetch user details
                    phoneNumber: "", // Will be populated when we fetch user details
                    storeCredit: 0.0,
                    verified: false, // Will be populated when we fetch user details
                    fcmToken: nil,
                    createdAt: createdAt,
                    updatedAt: updatedAt
                )
                
                // Parse OrderStatus
                guard let status = OrderStatus(rawValue: orderData.status) else {
                    print("⚠️ Unknown order status: \(orderData.status)")
                    return nil
                }
                
                // Create Order object
                return Order(
                    id: UUID(uuidString: orderData.id) ?? UUID(),
                    user: user,
                    items: cartItems,
                    status: status,
                    rawAmount: Decimal(orderData.raw_amount),
                    tip: Decimal(orderData.tip),
                    totalAmount: Decimal(orderData.total_amount),
                    deliveryAddress: orderData.delivery_address,
                    createdAt: createdAt,
                    estimatedDeliveryTime: nil, // Will be added when we have this field
                    actualDeliveryTime: nil, // Will be added when we have this field
                    paymentIntentId: orderData.payment_intent_id,
                    updatedAt: updatedAt,
                    deliveryInstructions: orderData.delivery_instructions,
                    isCampusDelivery: orderData.is_campus_delivery,
                    fulfilledBy: orderData.fulfilled_by != nil ? UUID(uuidString: orderData.fulfilled_by!) : nil
                )
            }
            return nil
        } catch {
            print("❌ Error fetching order status from Supabase: \(error)")
            throw SupabaseError.networkError(error)
        }
    }
    
    // MARK: - User Operations
    func fetchUser(userId: String) async throws -> User? {
        guard let supabase = supabase else {
            throw SupabaseError.clientNotConfigured
        }
        
        do {
            let response: [User] = try await supabase
                .from("users")
                .select()
                .eq("id", value: userId)
                .execute()
                .value
                
            
            return response.first
        } catch {
            print("❌ Error fetching user from Supabase: \(error)")
            throw SupabaseError.networkError(error)
        }
    }
    
    func updateUserStoreCredit(userId: String, newStoreCredit: Decimal) async throws -> User? {
        guard let supabase = supabase else {
            throw SupabaseError.clientNotConfigured
        }
        
        do {
            let response: [User] = try await supabase
                .from("users")
                .update(["store_credit": newStoreCredit])
                .eq("id", value: userId)
                .select()
                .execute()
                .value
                
            
            return response.first
        } catch {
            print("❌ Error updating user store credit in Supabase: \(error)")
            throw SupabaseError.networkError(error)
        }
    }
    
    func fetchNumUsers() async throws -> Int {
        guard let supabase = supabase else {
            throw SupabaseError.clientNotConfigured
        }
        
        do {
            // Use count() to get the total number of users
            let response = try await supabase
                .from("users")
                .select("id", head: true, count: .exact)
                .execute()
            
            let count = response.count ?? 0
            print("✅ Successfully fetched user count: \(count)")
            return count
        } catch {
            print("❌ Error fetching user count from Supabase: \(error)")
            throw SupabaseError.networkError(error)
        }
    }
    
    func fetchZipperStats() async throws -> ZipperStatsResult {
        guard let supabase = supabase else {
            throw SupabaseError.clientNotConfigured
        }
        
        do {
            // First, fetch all zippers
            let zippersResponse: [ZipperData] = try await supabase
                .from("zippers")
                .select("id, orders_handled, revenue")
                .execute()
                .value
                
            
            var zipperStats: [ZipperStatsResult.ZipperStats] = []
            var totalRevenue: Double = 0.0
            
            // For each zipper, fetch their user information
            for zipperData in zippersResponse {
                // Fetch user information for this zipper
                let userResponse: [User] = try await supabase
                    .from("users")
                    .select()
                    .eq("id", value: zipperData.id)
                    .execute()
                    .value
                
                if let user = userResponse.first {
                    // Create ZipperStats object
                    let zipperStat = ZipperStatsResult.ZipperStats(
                        id: zipperData.id,
                        user: user,
                        ordersHandled: zipperData.orders_handled,
                        revenue: zipperData.revenue
                    )
                    
                    zipperStats.append(zipperStat)
                    totalRevenue += zipperData.revenue
                }
            }
            
            let result = ZipperStatsResult(
                zippers: zipperStats,
                totalRevenue: totalRevenue
            )
            
            print("✅ Successfully fetched zipper stats: \(zipperStats.count) zippers, total revenue: $\(String(format: "%.2f", totalRevenue))")
            return result
            
        } catch {
            print("❌ Error fetching zipper stats from Supabase: \(error)")
            throw SupabaseError.networkError(error)
        }
    }
    
    
    /// Manually calls the Supabase database function 'update_order_status_and_inventory_by_order_id'
    /// This function is called when a user completes their order fully through store credit
    /// - Parameter orderId: The UUID of the order to update
    /// - Returns: True if the function was called successfully, false otherwise
    func updateOrderStatusAndInventory(orderId: UUID) async throws -> Bool {
        print("🔍 SupabaseService.updateOrderStatusAndInventory called with orderId: \(orderId)")
        
        guard let supabase = supabase else {
            print("❌ Supabase client not configured")
            throw SupabaseError.clientNotConfigured
        }
        
        print("🔍 Supabase client is configured, proceeding with RPC call")
        
        do {
            // Call the Supabase database function using rpc
            // This function doesn't return a value, so we just execute it
            print("🔍 Calling RPC function update_order_status_and_inventory_by_order_id...")
            print("🔍 Parameters: p_new_status=in_queue, p_order_id=\(orderId.uuidString.lowercased()), p_payment_intent_id=''")
            
            _ = try await supabase
                .rpc("update_order_status_and_inventory_by_order_id", params: ["p_new_status": "in_queue", "p_order_id": orderId.uuidString.lowercased(), "p_payment_intent_id": ""])
                .execute()
            
            print("✅ Successfully called update_order_status_and_inventory_by_order_id for order: \(orderId)")
            
            // Note: Notifications for order status changes are handled in acceptOrder/completeOrder functions
            // This function is only called when orders are created via store credit payment
            
            return true
            
        } catch {
            print("❌ Error calling update_order_status_and_inventory_by_order_id: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            throw SupabaseError.networkError(error)
        }
    }
    
    // New function to send order status notifications
    func sendOrderStatusNotification(orderId: UUID, status: String) async throws {
        print("🔔 Sending order status notification for order \(orderId) with status \(status)")
        
        // Get FCM tokens for the order's user
        guard let supabase = supabase else {
            print("❌ Supabase client not configured")
            return
        }
        
        // Get order details to find user
        let orderResponse: [OrderNotificationData] = try await supabase
            .from("orders")
            .select("user_id, total_amount")
            .eq("id", value: orderId.uuidString.lowercased())
            .execute()
            .value
        
        guard let orderData = orderResponse.first else {
            print("❌ Order not found: \(orderId)")
            return
        }
        
        guard let userId = UUID(uuidString: orderData.user_id) else {
            print("❌ Invalid user ID format: \(orderData.user_id)")
            return
        }
        
        let totalAmount = orderData.total_amount
        
        // Get FCM tokens for the user
        let tokensResponse: [FCMTokenData] = try await supabase
            .from("fcm_tokens")
            .select("token")
            .eq("user_id", value: userId.uuidString.lowercased())
            .execute()
            .value
        
        let fcmTokens = tokensResponse.map { $0.token }
        
        if fcmTokens.isEmpty {
            print("⚠️ No FCM tokens found for user \(userId)")
            return
        }
        
        // Prepare notification content
        let (title, body) = getOrderNotificationContent(orderId: orderId, status: status)
        
        // Prepare data payload
        let data = [
            "order_id": orderId.uuidString,
            "status": status,
            "type": "order_status_update",
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "order_total": String(describing: totalAmount)
        ]
        
        // Send the notification
        try await sendPushNotification(
            fcmTokens: fcmTokens,
            title: title,
            body: body,
            data: data,
            priority: "high",
            sound: "default",
            badge: 1
        )
    }
    
    private func getOrderNotificationContent(orderId: UUID, status: String) -> (title: String, body: String) {
        let orderNumber = String(orderId.uuidString.prefix(8))
        
        switch status {
        case "in_queue", "in_progress":
            return (
                title: "🍕 Your Order is Being Prepared",
                body: "Your Zip order #\(orderNumber) is now being prepared! We'll notify you when it's ready for pickup."
            )
        case "delivered":
            return (
                title: "✅ Order Delivered!",
                body: "Your Zip order #\(orderNumber) has been delivered! Enjoy your order and thank you for choosing Zip!"
            )
        default:
            return (
                title: "📦 Order Update",
                body: "Your Zip order #\(orderNumber) status has been updated to \(status)."
            )
        }
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
    
    func fetchUserCart(userId: String) async throws -> [CartItem] {
        // TODO: Implement when Supabase is configured
        throw SupabaseError.notImplemented
    }
    
    func clearUserCart(userId: String) async throws -> Bool {
        // TODO: Implement when Supabase is configured
        throw SupabaseError.notImplemented
    }
    
    // MARK: - Zipper Operations
    
    func fetchPendingOrders() async throws -> [Order] {
        guard let supabase = supabase else {
            throw SupabaseError.clientNotConfigured
        }
        
        do {
            // Fetch orders with status 'in_queue' (pending for zippers)
            let ordersResponse: [OrderData] = try await supabase
                .from("orders")
                .select()
                .eq("status", value: "in_queue")
                .order("created_at", ascending: true)
                .execute()
                .value
                
            
            var orders: [Order] = []
            
            // Process each order and fetch its items
            for orderData in ordersResponse {
                print("🔍 Processing order from database: \(orderData.id) with status: \(orderData.status)")
                
                // Fetch order items for this order
                let orderItemsResponse: [OrderItemData] = try await supabase
                    .from("order_items")
                    .select()
                    .eq("order_id", value: orderData.id)
                    .execute()
                    .value
                    
                
                // Convert order items to CartItems
                var cartItems: [CartItem] = []
                for itemData in orderItemsResponse {
                    // Fetch the product for this item
                    let productResponse: [ProductData] = try await supabase
                        .from("products")
                        .select()
                        .eq("id", value: itemData.product_id)
                        .execute()
                        .value
                        
                    
                    if let productData = productResponse.first {
                        // Parse product category
                        guard let category = ProductCategory(rawValue: productData.category) else {
                            print("⚠️ Unknown product category: \(productData.category)")
                            continue
                        }
                        
                        // Parse dates
                        let dateFormatter = ISO8601DateFormatter()
                        let productCreatedAt = dateFormatter.date(from: productData.created_at) ?? Date()
                        let productUpdatedAt = dateFormatter.date(from: productData.updated_at) ?? Date()
                        
                        // Create Product object
                        let product = Product(
                            id: UUID(uuidString: productData.id) ?? UUID(),
                            inventoryName: productData.inventoryName,
                            displayName: productData.displayName,
                            price: Decimal(productData.price),
                            quantity: productData.quantity,
                            imageURL: productData.imageURL,
                            images: [],
                            category: category,
                            createdAt: productCreatedAt,
                            updatedAt: productUpdatedAt
                        )
                        
                        // Create CartItem
                        let cartItem = CartItem(
                            product: product,
                            quantity: itemData.quantity,
                            userId: UUID(uuidString: orderData.user_id) ?? UUID()
                        )
                        cartItems.append(cartItem)
                    }
                }
                
                // Parse dates
                let dateFormatter = ISO8601DateFormatter()
                let createdAt = dateFormatter.date(from: orderData.created_at) ?? Date()
                let updatedAt = dateFormatter.date(from: orderData.updated_at) ?? Date()
                
                // Create User object
                let user = User(
                    id: orderData.user_id,
                    email: "",
                    firstName: "",
                    lastName: "",
                    phoneNumber: "",
                    storeCredit: 0.0,
                    verified: false,
                    fcmToken: nil,
                    createdAt: createdAt,
                    updatedAt: updatedAt
                )
                
                // Create Order object
                let order = Order(
                    id: UUID(uuidString: orderData.id) ?? UUID(),
                    user: user,
                    items: cartItems,
                    status: .inQueue,
                    rawAmount: Decimal(orderData.raw_amount),
                    tip: Decimal(orderData.tip),
                    totalAmount: Decimal(orderData.total_amount),
                    deliveryAddress: orderData.delivery_address,
                    createdAt: createdAt,
                    estimatedDeliveryTime: nil,
                    actualDeliveryTime: nil,
                    paymentIntentId: orderData.payment_intent_id,
                    updatedAt: updatedAt,
                    deliveryInstructions: orderData.delivery_instructions,
                    isCampusDelivery: orderData.is_campus_delivery,
                    fulfilledBy: orderData.fulfilled_by != nil ? UUID(uuidString: orderData.fulfilled_by!) : nil
                )
                
                print("🔍 Created Order object with ID: \(order.id.uuidString) (original DB ID: \(orderData.id))")
                orders.append(order)
            }
            
            print("✅ Successfully fetched \(orders.count) pending orders")
            return orders
            
        } catch {
            print("❌ Error fetching pending orders from Supabase: \(error)")
            throw SupabaseError.networkError(error)
        }
    }
    
    func fetchActiveOrderForZipper(zipperId: String) async throws -> Order? {
        guard let supabase = supabase else {
            throw SupabaseError.clientNotConfigured
        }
        
        do {
            // Fetch orders where fulfilled_by matches zipperId and status is 'in_progress'
            let ordersResponse: [OrderData] = try await supabase
                .from("orders")
                .select()
                .eq("fulfilled_by", value: zipperId)
                .eq("status", value: "in_progress")
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value
                
            
            guard let orderData = ordersResponse.first else {
                return nil
            }
            
            // Fetch order items for this order
            let orderItemsResponse: [OrderItemData] = try await supabase
                .from("order_items")
                .select()
                .eq("order_id", value: orderData.id)
                .execute()
                .value
                
            
            // Convert order items to CartItems
            var cartItems: [CartItem] = []
            for itemData in orderItemsResponse {
                // Fetch the product for this item
                let productResponse: [ProductData] = try await supabase
                    .from("products")
                    .select()
                    .eq("id", value: itemData.product_id)
                    .execute()
                    .value
                    
                
                if let productData = productResponse.first {
                    // Parse product category
                    guard let category = ProductCategory(rawValue: productData.category) else {
                        print("⚠️ Unknown product category: \(productData.category)")
                        continue
                    }
                    
                    // Parse dates
                    let dateFormatter = ISO8601DateFormatter()
                    let productCreatedAt = dateFormatter.date(from: productData.created_at) ?? Date()
                    let productUpdatedAt = dateFormatter.date(from: productData.updated_at) ?? Date()
                    
                    // Create Product object
                    let product = Product(
                        id: UUID(uuidString: productData.id) ?? UUID(),
                        inventoryName: productData.inventoryName,
                        displayName: productData.displayName,
                        price: Decimal(productData.price),
                        quantity: productData.quantity,
                        imageURL: productData.imageURL,
                        images: [],
                        category: category,
                        createdAt: productCreatedAt,
                        updatedAt: productUpdatedAt
                    )
                    
                    // Create CartItem
                    let cartItem = CartItem(
                        product: product,
                        quantity: itemData.quantity,
                        userId: UUID(uuidString: orderData.user_id) ?? UUID()
                    )
                    cartItems.append(cartItem)
                }
            }
            
            // Parse dates
            let dateFormatter = ISO8601DateFormatter()
            let createdAt = dateFormatter.date(from: orderData.created_at) ?? Date()
            let updatedAt = dateFormatter.date(from: orderData.updated_at) ?? Date()
            
            // Create User object
            let user = User(
                id: orderData.user_id,
                email: "",
                firstName: "",
                lastName: "",
                phoneNumber: "",
                storeCredit: 0.0,
                verified: false,
                createdAt: createdAt,
                updatedAt: updatedAt
            )
            
            // Create Order object
            let order = Order(
                id: UUID(uuidString: orderData.id) ?? UUID(),
                user: user,
                items: cartItems,
                status: .inProgress,
                rawAmount: Decimal(orderData.raw_amount),
                tip: Decimal(orderData.tip),
                totalAmount: Decimal(orderData.total_amount),
                deliveryAddress: orderData.delivery_address,
                createdAt: createdAt,
                estimatedDeliveryTime: nil,
                actualDeliveryTime: nil,
                paymentIntentId: orderData.payment_intent_id,
                updatedAt: updatedAt,
                deliveryInstructions: orderData.delivery_instructions,
                isCampusDelivery: orderData.is_campus_delivery,
                fulfilledBy: orderData.fulfilled_by != nil ? UUID(uuidString: orderData.fulfilled_by!) : nil
            )
            
            print("✅ Successfully fetched active order for zipper: \(zipperId)")
            return order
            
        } catch {
            print("❌ Error fetching active order for zipper from Supabase: \(error)")
            throw SupabaseError.networkError(error)
        }
    }
    
    func acceptOrder(orderId: UUID, zipperId: String) async throws -> Bool {
        guard let supabase = supabase else {
            throw SupabaseError.clientNotConfigured
        }
        
        do {
            let orderIdString = orderId.uuidString.lowercased()
            print("🔍 Attempting to accept order with ID: \(orderIdString)")
            print("🔍 Zipper ID: \(zipperId)")
            
            // Update the order to assign it to the zipper and change status to in_progress
            let response = try await supabase
            .from("orders")
            .update([
                "fulfilled_by": zipperId,
                "status": "in_progress",
                "updated_at": ISO8601DateFormatter().string(from: Date())
            ])
            .eq("id", value: orderIdString)
            .eq("status", value: "in_queue") // Double-check status hasn't changed
            .execute()
            
            print("🔍 Update response status: \(response.response.statusCode)")
            
            // Check if the update was successful (status code 200 or 204)
            guard response.response.statusCode >= 200 && response.response.statusCode < 300 else {
                print("❌ Update failed with status code: \(response.response.statusCode)")
                return false
            }
            
            // Verify the order was actually updated by doing a simple count query
            let countResponse = try await supabase
                .from("orders")
                .select("id", head: true, count: .exact)
                .eq("id", value: orderIdString)
                .eq("status", value: "in_progress")
                .execute()
            
            guard let count = countResponse.count, count > 0 else {
                print("❌ Order was not successfully updated to in_progress status")
                return false
            }
            
            print("✅ Successfully accepted order \(orderIdString) for zipper \(zipperId)")
            
            // Send notification to customer about order being prepared
            do {
                try await sendOrderStatusNotification(orderId: orderId, status: "in_progress")
                print("✅ Notification sent successfully for order acceptance")
            } catch {
                print("⚠️ Failed to send notification for order acceptance: \(error)")
                // Don't fail the order acceptance if notification fails
            }
            
            return true
            
        } catch {
            print("❌ Error accepting order in Supabase: \(error)")
            throw SupabaseError.networkError(error)
        }
    }
    
    func completeOrder(orderId: UUID, photo: UIImage? = nil) async throws -> Bool {
        guard let supabase = supabase else {
            throw SupabaseError.clientNotConfigured
        }
        
        do {
            // First, fetch the order details to get zipper ID and total amount
            print("🔍 Fetching order details for ID: \(orderId.uuidString.lowercased())")
            let orderResponse: [OrderCompletionData] = try await supabase
                .from("orders")
                .select("id, fulfilled_by, total_amount")
                .eq("id", value: orderId.uuidString.lowercased())
                .eq("status", value: "in_progress")
                .execute()
                .value
                
            
            print("🔍 Found \(orderResponse.count) orders matching criteria")
            
            guard let orderData = orderResponse.first else {
                print("❌ No order found with ID \(orderId) in progress status")
                print("🔍 This could mean:")
                print("   - Order ID doesn't exist")
                print("   - Order status is not 'in_progress'")
                print("   - Order was already completed")
                return false
            }
            
            print("🔍 Found order: ID=\(orderData.id), fulfilled_by=\(orderData.fulfilled_by ?? "nil"), total_amount=\(orderData.total_amount)")
            
            // Extract zipper ID and total amount
            guard let zipperIdString = orderData.fulfilled_by,
                  let zipperId = UUID(uuidString: zipperIdString) else {
                print("❌ Missing required order data (fulfilled_by)")
                return false
            }
            
            let totalAmount = orderData.total_amount
            
            // Update the order status to delivered
            print("🔍 Updating order \(orderId.uuidString.lowercased()) from in_progress to delivered")
            let orderUpdateResponse: [OrderCompletionData] = try await supabase
                .from("orders")
                .update([
                    "status": "delivered",
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ])
                .eq("id", value: orderId.uuidString.lowercased())
                .eq("status", value: "in_progress")
                .select("id, fulfilled_by, total_amount") // Add select to get the updated row back
                .execute()
                .value
                
            
            print("🔍 Order update response count: \(orderUpdateResponse.count)")
            
            // Check if order update was successful
            if orderUpdateResponse.isEmpty {
                print("❌ No order found with ID \(orderId.uuidString.lowercased()) in progress status")
                return false
            }
            
            print("✅ Successfully updated order status to delivered")
            
            // Update zipper statistics
            print("🔍 Updating zipper statistics for zipper \(zipperId)")
            do {
                // First, fetch current zipper data to get current values
                let zipperResponse: [ZipperData] = try await supabase
                    .from("zippers")
                    .select("orders_handled, revenue")
                    .eq("id", value: zipperId.uuidString.lowercased())
                    .execute()
                    .value
                    
                
                if let zipperData = zipperResponse.first {
                    let newOrdersHandled = zipperData.orders_handled + 1
                    let newRevenue = zipperData.revenue + totalAmount
                    
                    print("🔍 Current: orders_handled=\(zipperData.orders_handled), revenue=\(zipperData.revenue)")
                    print("🔍 New: orders_handled=\(newOrdersHandled), revenue=\(newRevenue)")
                    
                    let zipperUpdateResponse = try await supabase
                        .from("zippers")
                        .update([
                            "orders_handled": Double(newOrdersHandled),
                            "revenue": newRevenue
                        ])
                        .eq("id", value: zipperId.uuidString.lowercased())
                        .select()
                        .execute()
                    
                    print("🔍 Zipper update response: \(zipperUpdateResponse)")
                    print("✅ Successfully updated zipper statistics for zipper \(zipperId)")
                } else {
                    print("⚠️ Zipper not found, skipping statistics update")
                }
            } catch {
                print("⚠️ Failed to update zipper statistics: \(error)")
                // Don't fail the entire operation if zipper stats update fails
            }
            
            // Upload photo if provided
            if let photo = photo {
                print("🔍 Uploading completion photo for order \(orderId)")
                do {
                    let photoURL = try await uploadOrderCompletionPhoto(orderId: orderId, photo: photo)
                    print("✅ Successfully uploaded completion photo: \(photoURL ?? "unknown")")
                } catch {
                    print("⚠️ Failed to upload completion photo: \(error)")
                    // Don't fail the entire operation if photo upload fails
                }
            }
            
            print("✅ Successfully completed order \(orderId)")
            
            // Send notification to customer about order being delivered
            do {
                try await sendOrderStatusNotification(orderId: orderId, status: "delivered")
                print("✅ Notification sent successfully for order completion")
            } catch {
                print("⚠️ Failed to send notification for order completion: \(error)")
                // Don't fail the order completion if notification fails
            }
            
            return true
            
        } catch {
            print("❌ Error completing order in Supabase: \(error)")
            throw SupabaseError.networkError(error)
        }
    }
    
    // MARK: - Bug Report Operations
    
    func submitBugReport(userId: String, title: String, description: String) async throws -> Bool {
        guard let supabase = supabase else {
            throw SupabaseError.clientNotConfigured
        }
        
        do {
            // Create bug report data for Supabase
            let bugReportData = BugReportData(
                id: UUID().uuidString,
                user_id: userId,
                title: title,
                description: description,
                created_at: ISO8601DateFormatter().string(from: Date())
            )
            
            // Insert the bug report into the bug_reports table
            try await supabase
                .from("bug_reports")
                .insert(bugReportData)
                .execute()
            
            print("✅ Successfully submitted bug report with ID: \(bugReportData.id)")
            return true
            
        } catch {
            print("❌ Error submitting bug report to Supabase: \(error)")
            throw SupabaseError.networkError(error)
        }
    }
    
    // MARK: - Image Upload Operations
    
    func uploadOrderCompletionPhoto(orderId: UUID, photo: UIImage) async throws -> String? {
        guard let supabase = supabase else {
            throw SupabaseError.clientNotConfigured
        }
        
        do {
            // Convert UIImage to Data (JPEG format)
            guard let imageData = photo.jpegData(compressionQuality: 0.8) else {
                print("❌ Failed to convert UIImage to JPEG data")
                throw SupabaseError.invalidResponse
            }
            
            // Create a unique filename for the photo
            let fileName = "\(orderId.uuidString)_\(Date().timeIntervalSince1970).jpg"
            try await supabase.storage.from("deliveries").upload(fileName, data: imageData)

            return orderId.uuidString
            
        } catch {
            print("❌ Error uploading photo to Supabase: \(error)")
            throw SupabaseError.networkError(error)
        }
    }
    
    // MARK: - Delivery Image Operations
    
    func fetchDeliveryImageURL(for orderId: UUID) async throws -> String? {
        guard let supabase = supabase else {
            print("⚠️ Supabase client not configured")
            throw SupabaseError.clientNotConfigured
        }
        
        do {
            // First, list files in the deliveries bucket to find the image with this order ID
            let orderIdString = orderId.uuidString
            let files = try await supabase.storage.from("deliveries").list()
            
            // Find a file that starts with the order ID (since the actual filename includes timestamp)
            if let matchingFile = files.first(where: { $0.name.hasPrefix(orderIdString) }) {
                // Use Supabase SDK's createSignedURL method for proper authentication
                let signedURL = try await supabase.storage.from("deliveries").createSignedURL(path: matchingFile.name, expiresIn: 3600)
                let urlString = signedURL.absoluteString
                
                print("✅ Successfully constructed delivery image URL for order \(orderId): \(matchingFile.name)")
                print("🔍 URL: \(urlString)")
                return urlString
            } else {
                print("⚠️ No delivery image found for order \(orderId)")
                return nil
            }
            
        } catch {
            print("⚠️ Error fetching delivery image for order \(orderId): \(error)")
            // Return nil instead of throwing - not all orders have delivery images
            return nil
        }
    }
    
    func fetchDeliveryImageURLs(for orderIds: [UUID]) async throws -> [UUID: String] {
        guard let supabase = supabase else {
            print("⚠️ Supabase client not configured")
            throw SupabaseError.clientNotConfigured
        }
        
        var imageURLs: [UUID: String] = [:]
        
        do {
            // List all files in the deliveries bucket once
            let files = try await supabase.storage.from("deliveries").list()
            
            // Match each order ID to its corresponding file
            for orderId in orderIds {
                let orderIdString = orderId.uuidString
                if let matchingFile = files.first(where: { $0.name.hasPrefix(orderIdString) }) {
                    // Use Supabase SDK's createSignedURL method for proper authentication
                    let signedURL = try await supabase.storage.from("deliveries").createSignedURL(path: matchingFile.name, expiresIn: 3600)
                    let urlString = signedURL.absoluteString
                    imageURLs[orderId] = urlString
                } else {
                    print("⚠️ No delivery image found for order \(orderId)")
                }
            }
        } catch {
            print("⚠️ Error listing delivery images: \(error)")
        }
        
        print("✅ Successfully fetched \(imageURLs.count) delivery image URLs out of \(orderIds.count) orders")
        return imageURLs
    }
    
    // MARK: - FCM Token Operations
    
    func registerFCMToken(token: String, deviceId: String, platform: String, appVersion: String) async throws -> Bool {
        guard let supabase = supabase else {
            print("❌ FCM: Supabase client not configured")
            throw SupabaseError.clientNotConfigured
        }
        
        print("🔄 FCM: Calling upsert_user_fcm_token with params:")
        print("  - p_token: \(token.prefix(20))...")
        print("  - p_device_id: \(deviceId)")
        print("  - p_platform: \(platform)")
        print("  - p_app_version: \(appVersion)")
        
        do {
            // Call the Supabase function to register the FCM token
            let response = try await supabase
                .rpc("upsert_user_fcm_token", params: [
                    "p_token": token,
                    "p_device_id": deviceId,
                    "p_platform": platform,
                    "p_app_version": appVersion
                ])
                .execute()
            
            print("📄 FCM: Raw response: \(response)")
            
            // Parse the response to check if it was successful
            let data = response.data
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = json["success"] as? Bool {
                if success {
                    print("✅ FCM: Token registered successfully with Supabase")
                    print("📄 FCM: Response details: \(json)")
                    return true
                } else {
                    print("❌ FCM: Database function returned success: false")
                    print("📄 FCM: Error from database: \(json["error"] ?? "Unknown error")")
                    return false
                }
            } else {
                print("⚠️ FCM: Could not parse response, assuming success")
                print("📄 FCM: Raw response data: \(String(data: data, encoding: .utf8) ?? "No data")")
                return true
            }
        
        } catch {
            print("❌ FCM: Failed to register token with Supabase: \(error)")
            print("❌ FCM: Error type: \(type(of: error))")
            print("❌ FCM: Error details: \(error.localizedDescription)")
            throw SupabaseError.networkError(error)
        }
    }
    
    
    
    func sendPushNotification(fcmTokens: [String], title: String, body: String, data: [String: String]?, priority: String?, sound: String?, badge: Int?) async throws -> Bool {
        guard let supabase = supabase else {
            print("❌ FCM: Supabase client not configured")
            throw SupabaseError.clientNotConfigured
        }
        
        print("📤 FCM: Sending push notification via zip-push edge function")
        print("  - Title: \(title)")
        print("  - Body: \(body)")
        print("  - Tokens: \(fcmTokens.count) device(s)")
        print("  - Priority: \(priority ?? "high")")
        print("  - Sound: \(sound ?? "default")")
        print("  - Badge: \(badge ?? 1)")
        
        do {
            // Prepare the payload for the zip-push edge function
            var payload: [String: Any] = [
                "fcm_tokens": fcmTokens,
                "title": title,
                "body": body
            ]
            
            // Add optional parameters if provided
            if let data = data {
                payload["data"] = data
            }
            if let priority = priority {
                payload["priority"] = priority
            }
            if let sound = sound {
                payload["sound"] = sound
            }
            if let badge = badge {
                payload["badge"] = badge
            }
            
            print("📤 FCM: Calling zip-push edge function with payload: \(payload)")
            
            // Create a struct that conforms to Encodable for the payload
            struct PushNotificationPayload: Encodable {
                let fcm_tokens: [String]
                let title: String
                let body: String
                let data: [String: String]?
                let priority: String?
                let sound: String?
                let badge: Int?
                
                init(fcmTokens: [String], title: String, body: String, data: [String: String]?, priority: String?, sound: String?, badge: Int?) {
                    self.fcm_tokens = fcmTokens
                    self.title = title
                    self.body = body
                    self.data = data
                    self.priority = priority
                    self.sound = sound
                    self.badge = badge
                }
            }
            
            let pushPayload = PushNotificationPayload(
                fcmTokens: fcmTokens,
                title: title,
                body: body,
                data: data,
                priority: priority,
                sound: sound,
                badge: badge
            )
            
            // Call the zip-push edge function
            let response: Any = try await supabase.functions
                .invoke("push", options: FunctionInvokeOptions(body: pushPayload))
            
            print("📄 FCM: Edge function response: \(response)")
            
            // Parse the response
            if let json = response as? [String: Any] {
                print("📄 FCM: Response is a dictionary with keys: \(json.keys)")
                
                // Check for success field
                if let success = json["success"] as? Bool {
                    if success {
                        print("✅ FCM: Push notification sent successfully")
                        if let message = json["message"] as? String {
                            print("📄 FCM: Message: \(message)")
                        }
                        if let summary = json["summary"] as? [String: Any] {
                            print("📄 FCM: Summary: \(summary)")
                            if let successful = summary["successful"] as? Int,
                               let failed = summary["failed"] as? Int {
                                print("📄 FCM: Results: \(successful) successful, \(failed) failed")
                            }
                        }
                        if let results = json["results"] as? [[String: Any]] {
                            print("📄 FCM: Detailed results for \(results.count) device(s)")
                            for (index, result) in results.enumerated() {
                                if let token = result["token"] as? String,
                                   let success = result["success"] as? Bool {
                                    print("📄 FCM: Device \(index + 1): \(token) - \(success ? "✅" : "❌")")
                                }
                            }
                        }
                        return true
                    } else {
                        print("❌ FCM: Edge function returned success: false")
                        if let error = json["error"] as? String {
                            print("📄 FCM: Error: \(error)")
                        }
                        return false
                    }
                } else {
                    // If no success field, check if it's a successful response based on other indicators
                    print("⚠️ FCM: No 'success' field found in response")
                    print("📄 FCM: Available fields: \(json.keys)")
                    
                    // If we get a 200 response without a success field, assume it was successful
                    if json.isEmpty {
                        print("⚠️ FCM: Empty response - assuming success")
                        return true
                    } else {
                        print("✅ FCM: Got response data - assuming success")
                        return true
                    }
                }
            } else if let stringResponse = response as? String {
                print("📄 FCM: Response is a string: \(stringResponse)")
                // If we get a string response and a 200 status, assume success
                return true
            } else {
                print("⚠️ FCM: Could not parse edge function response")
                print("📄 FCM: Raw response: \(response)")
                
                // If we got a 200 status but can't parse the response, assume success
                print("✅ FCM: Got 200 status - assuming success despite parsing issues")
                return true
            }
            
        } catch {
            print("❌ FCM: Failed to send push notification: \(error)")
            print("❌ FCM: Error details: \(error.localizedDescription)")
            throw SupabaseError.networkError(error)
        }
    }
    
    func fetchZipperFCMTokens() async throws -> [String] {
        guard let supabase = supabase else {
            print("❌ FCM: Supabase client not configured")
            throw SupabaseError.clientNotConfigured
        }
        
        print("🔍 FCM: Fetching FCM tokens for all zippers...")
        print("🔍 DEBUG: fetchZipperFCMTokens function called")
        
        do {
            // First, get all zipper IDs from the zippers table
            let zippersResponse: [ZipperIdData] = try await supabase
                .from("zippers")
                .select("id")
                .execute()
                .value
            
            print("🔍 FCM: Found \(zippersResponse.count) zippers")
            
            if zippersResponse.isEmpty {
                print("⚠️ FCM: No zippers found in zippers table")
                return []
            }
            
            // Extract zipper IDs
            let zipperIds = zippersResponse.map { $0.id }
            print("🔍 FCM: Zipper IDs: \(zipperIds)")
            
            // Get FCM tokens for all zippers
            let tokensResponse: [FCMTokenData] = try await supabase
                .from("fcm_tokens")
                .select("token")
                .in("user_id", values: zipperIds)
                .gte("updated_at", value: ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()))
                .execute()
                .value
            
            let fcmTokens = tokensResponse.map { $0.token }
            print("✅ FCM: Found \(fcmTokens.count) active FCM tokens for zippers")
            
            return fcmTokens
            
        } catch {
            print("❌ FCM: Failed to fetch zipper FCM tokens: \(error)")
            throw SupabaseError.networkError(error)
        }
    }
    
    func notifyZippersOfNewOrder(_ order: Order) async throws -> Bool {
        print("🔔 NOTIFY: Starting to send new order notification to zippers for order: \(order.id)")
        
        do {
            let zipperTokens = try await fetchZipperFCMTokens()
            if !zipperTokens.isEmpty {
                let orderNumber = String(order.id.uuidString.prefix(8))
                let totalAmount = NSDecimalNumber(decimal: order.totalAmount).doubleValue
                
                let title = "📦 New Order Available"
                let body = "New Zip order #\(orderNumber) is currently waiting for pickup. Grab it if you can!"
                
                let data = [
                    "order_id": order.id.uuidString,
                    "type": "new_order",
                    "order_total": String(totalAmount),
                    "delivery_address": order.deliveryAddress,
                    "timestamp": ISO8601DateFormatter().string(from: Date())
                ]
                
                try await sendPushNotification(
                    fcmTokens: zipperTokens,
                    title: title,
                    body: body,
                    data: data,
                    priority: "high",
                    sound: "default",
                    badge: 1
                )
                
                print("✅ NOTIFY: Successfully sent new order notification to \(zipperTokens.count) zippers")
                return true
            } else {
                print("⚠️ NOTIFY: No active zipper FCM tokens found, skipping notification")
                return false
            }
        } catch {
            print("❌ NOTIFY: Failed to send new order notification to zippers: \(error)")
            throw error
        }
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


