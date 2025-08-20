//
//  SupabaseService.swift
//  Zip
//

import Foundation

protocol SupabaseServiceProtocol {
    func fetchProducts() async throws -> [Product]
}

final class SupabaseService: SupabaseServiceProtocol {
    func fetchProducts() async throws -> [Product] {
        // Stubbed mock data for MVP
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
}


