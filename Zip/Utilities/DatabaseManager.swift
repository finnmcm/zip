import Foundation

class DatabaseManager {
    static let shared = DatabaseManager()
    
    private let userDefaults = UserDefaults.standard
    
    // Keys for UserDefaults
    private enum Keys {
        static let products = "products"
        static let cartItems = "cartItems"
        static let users = "users"
        static let orders = "orders"
        static let hasLoadedSampleData = "hasLoadedSampleData"
    }
    
    private init() {
        // Automatically load sample data on first launch
        loadSampleDataIfNeeded()
    }
    
    /// Automatically loads sample data if this is the first time the app is launched
    private func loadSampleDataIfNeeded() {
        let hasLoaded = userDefaults.bool(forKey: Keys.hasLoadedSampleData)
        if !hasLoaded {
            print("🚀 First launch detected - loading sample data...")
            createSampleData()
            userDefaults.set(true, forKey: Keys.hasLoadedSampleData)
        }
    }
    
    /// Resets the entire database - use this when you have schema changes
    /// WARNING: This will delete all data
    func resetDatabase() {
        print("🔄 Starting database reset...")
        
        // Clear all data from UserDefaults
        userDefaults.removeObject(forKey: Keys.products)
        userDefaults.removeObject(forKey: Keys.cartItems)
        userDefaults.removeObject(forKey: Keys.users)
        userDefaults.removeObject(forKey: Keys.orders)
        userDefaults.removeObject(forKey: Keys.hasLoadedSampleData)
        
        print("✅ Database reset successfully")
        
        // Create sample data for testing
        createSampleData()
        userDefaults.set(true, forKey: Keys.hasLoadedSampleData)
    }
    
    /// Clears all data for a specific model type
    func clearModel<T: Codable>(_ modelType: T.Type, key: String) {
        userDefaults.removeObject(forKey: key)
        print("✅ Cleared \(String(describing: modelType)) successfully")
    }
    
    /// Creates sample data for testing
    private func createSampleData() {
        // Create sample products with Northwestern student focus
        let products = [
            // Beverages
            Product(name: "Coffee", price: 2.99, quantity: 50, category: "Beverages"),
            Product(name: "Energy Drink", price: 3.49, quantity: 25, category: "Beverages"),
            Product(name: "Water Bottle", price: 1.49, quantity: 100, category: "Beverages"),
            Product(name: "Hot Chocolate", price: 2.49, quantity: 30, category: "Beverages"),
            Product(name: "Iced Tea", price: 2.99, quantity: 40, category: "Beverages"),
            
            // Snacks
            Product(name: "Energy Bar", price: 1.99, quantity: 30, category: "Snacks"),
            Product(name: "Chips", price: 0.99, quantity: 25, category: "Snacks"),
            Product(name: "Granola Bar", price: 1.49, quantity: 35, category: "Snacks"),
            Product(name: "Nuts", price: 2.99, quantity: 20, category: "Snacks"),
            Product(name: "Popcorn", price: 1.29, quantity: 30, category: "Snacks"),
            
            // Food
            Product(name: "Sandwich", price: 4.99, quantity: 15, category: "Food"),
            Product(name: "Pizza Slice", price: 3.49, quantity: 20, category: "Food"),
            Product(name: "Burger", price: 6.99, quantity: 10, category: "Food"),
            Product(name: "Salad", price: 5.49, quantity: 12, category: "Food"),
            Product(name: "Soup", price: 3.99, quantity: 18, category: "Food"),
            
            // Study Essentials
            Product(name: "Notebook", price: 2.99, quantity: 25, category: "Study"),
            Product(name: "Pen", price: 0.99, quantity: 50, category: "Study"),
            Product(name: "Highlighters", price: 1.99, quantity: 30, category: "Study"),
            Product(name: "Sticky Notes", price: 1.49, quantity: 40, category: "Study"),
            Product(name: "USB Cable", price: 4.99, quantity: 15, category: "Study"),
            
            // Convenience
            Product(name: "Toothbrush", price: 2.49, quantity: 20, category: "Convenience"),
            Product(name: "Deodorant", price: 3.99, quantity: 15, category: "Convenience"),
            Product(name: "Phone Charger", price: 8.99, quantity: 10, category: "Convenience"),
            Product(name: "Umbrella", price: 12.99, quantity: 8, category: "Convenience"),
            Product(name: "Hand Sanitizer", price: 1.99, quantity: 35, category: "Convenience")
        ]
        
        saveProducts(products)
        print("✅ Sample data created successfully with \(products.count) products")
    }
    
    // MARK: - Product Management
    
    func saveProducts(_ products: [Product]) {
        if let encoded = try? JSONEncoder().encode(products) {
            userDefaults.set(encoded, forKey: Keys.products)
        }
    }
    
    func loadProducts() -> [Product] {
        guard let data = userDefaults.data(forKey: Keys.products),
              let products = try? JSONDecoder().decode([Product].self, from: data) else {
            return []
        }
        return products
    }
    
    // MARK: - Cart Management
    
    func saveCartItems(_ items: [CartItem]) {
        if let encoded = try? JSONEncoder().encode(items) {
            userDefaults.set(encoded, forKey: Keys.cartItems)
        }
    }
    
    func loadCartItems() -> [CartItem] {
        guard let data = userDefaults.data(forKey: Keys.cartItems),
              let items = try? JSONDecoder().decode([CartItem].self, from: data) else {
            return []
        }
        return items
    }
    
    // MARK: - User Management
    
    func saveUsers(_ users: [User]) {
        if let encoded = try? JSONEncoder().encode(users) {
            userDefaults.set(encoded, forKey: Keys.users)
        }
    }
    
    func loadUsers() -> [User] {
        guard let data = userDefaults.data(forKey: Keys.users),
              let users = try? JSONDecoder().decode([User].self, from: data) else {
            return []
        }
        return users
    }
    
    // MARK: - Order Management
    
    func saveOrders(_ orders: [Order]) {
        if let encoded = try? JSONEncoder().encode(orders) {
            userDefaults.set(encoded, forKey: Keys.orders)
        }
    }
    
    func loadOrders() -> [Order] {
        guard let data = userDefaults.data(forKey: Keys.orders),
              let orders = try? JSONDecoder().decode([Order].self, from: data) else {
            return []
        }
        return orders
    }
}
