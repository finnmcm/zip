//
//  Constants.swift
//  Zip
//

import SwiftUI

enum AppColors {
    static let northwesternPurple = Color(hex: "#79E0D3")
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let textPrimary = Color(hex: "#068f7c")
    static let textSecondary = Color.secondary
    static let accent = northwesternPurple
    static let error = Color.red
    static let success = Color.green
    static let info = Color.blue
}

enum AppMetrics {
    static let cornerRadiusSmall: CGFloat = 10
    static let cornerRadiusLarge: CGFloat = 18
    static let spacingSmall: CGFloat = 8
    static let spacing: CGFloat = 12
    static let spacingLarge: CGFloat = 20
}

enum AppImages {
    static let logo = "logo"
    static let logoInverted = "logo_inverted"
}

// MARK: - Database Table Names
enum DatabaseTables {
    static let products = "products"
    static let users = "users"
    static let orders = "orders"
    static let cartItems = "cart_items"
    static let orderItems = "order_items"
}

// MARK: - Error Messages
enum ErrorMessages {
    static let networkError = "Network error occurred. Please check your connection."
    static let authenticationError = "Authentication failed. Please try logging in again."
    static let serverError = "Server error occurred. Please try again later."
    static let unknownError = "An unknown error occurred. Please try again."
    static let invalidData = "Invalid data received from server."
}


