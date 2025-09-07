//
//  SupabaseService.swift
//  Zip
//

import Foundation
import Supabase



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
    func completeOrder(orderId: UUID) async throws -> Bool
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
        let fulfilled_by: String?
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
                    storeCredit: 0.0, // Will be populated when we fetch user details
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
                    storeCredit: 0.0, // Will be populated when we fetch user details
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
            return true
            
        } catch {
            print("❌ Error calling update_order_status_and_inventory_by_order_id: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            throw SupabaseError.networkError(error)
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
            .select() // Add select to get the updated row back
            .execute()
            
            print("🔍 Update response count: \(response.count)")
            
            // Check if any rows were affected
            if response.count == nil {
                print("❌ No order found with ID \(orderIdString) in queue status")
                return false
            }
            
            print("✅ Successfully accepted order \(orderIdString) for zipper \(zipperId)")
            return true
            
        } catch {
            print("❌ Error accepting order in Supabase: \(error)")
            throw SupabaseError.networkError(error)
        }
    }
    
    func completeOrder(orderId: UUID) async throws -> Bool {
        guard let supabase = supabase else {
            throw SupabaseError.clientNotConfigured
        }
        
        do {
            // First, fetch the order details to get zipper ID and total amount
            let orderResponse = try await supabase
                .from("orders")
                .select("fulfilled_by, total_amount")
                .eq("id", value: orderId.uuidString.lowercased())
                .eq("status", value: "in_progress")
                .execute()
            
            guard let orderData = orderResponse.data.first,
                  let orderDict = orderData as? [String: Any] else {
                print("❌ No order found with ID \(orderId) in progress status")
                return false
            }
            
            // Extract zipper ID and total amount
            guard let zipperIdString = orderDict["fulfilled_by"] as? String,
                  let zipperId = UUID(uuidString: zipperIdString),
                  let totalAmount = orderDict["total_amount"] as? NSNumber else {
                print("❌ Missing required order data (fulfilled_by or total_amount)")
                return false
            }
            
            // Update the order status to delivered
            let orderUpdateResponse = try await supabase
                .from("orders")
                .update([
                    "status": "delivered",
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ])
                .eq("id", value: orderId.uuidString.lowercased())
                .eq("status", value: "in_progress")
                .execute()
            
            // Check if order update was successful
            if orderUpdateResponse.count == 0 {
                print("❌ Failed to update order status")
                return false
            }
            
            // Update zipper statistics
            let zipperUpdateResponse = try await supabase
                .from("zippers")
                .update([
                    "orders_handled": "orders_handled + 1",
                    "revenue": "revenue + \(totalAmount.decimalValue)"
                ])
                .eq("id", value: zipperId.uuidString.lowercased())
                .execute()
            
            // Check if zipper update was successful
            if zipperUpdateResponse.count == 0 {
                print("⚠️ Order completed but failed to update zipper statistics for zipper \(zipperId)")
                // Don't fail the entire operation if zipper stats update fails
            } else {
                print("✅ Successfully updated zipper statistics for zipper \(zipperId)")
            }
            
            print("✅ Successfully completed order \(orderId)")
            return true
            
        } catch {
            print("❌ Error completing order in Supabase: \(error)")
            throw SupabaseError.networkError(error)
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


