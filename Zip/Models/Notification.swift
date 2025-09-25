//
//  Notification.swift
//  Zip
//
//  Created by Finn McMillan on 1/20/25.
//

import Foundation

/// Represents a push notification received by the app
struct ZipNotification: Identifiable, Codable {
    let id: String
    let title: String
    let body: String
    let data: [String: String]
    let timestamp: Date
    let type: NotificationType
    let isRead: Bool
    
    init(
        id: String = UUID().uuidString,
        title: String,
        body: String,
        data: [String: String] = [:],
        timestamp: Date = Date(),
        type: NotificationType = .general,
        isRead: Bool = false
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.data = data
        self.timestamp = timestamp
        self.type = type
        self.isRead = isRead
    }
}

/// Types of notifications the app can receive
enum NotificationType: String, CaseIterable, Codable {
    case orderUpdate = "order_update"
    case orderReady = "order_ready"
    case orderDelivered = "order_delivered"
    case orderCancelled = "order_cancelled"
    case paymentUpdate = "payment_update"
    case storeUpdate = "store_update"
    case promotion = "promotion"
    case general = "general"
    
    var displayName: String {
        switch self {
        case .orderUpdate:
            return "Order Update"
        case .orderReady:
            return "Order Ready"
        case .orderDelivered:
            return "Order Delivered"
        case .orderCancelled:
            return "Order Cancelled"
        case .paymentUpdate:
            return "Payment Update"
        case .storeUpdate:
            return "Store Update"
        case .promotion:
            return "Promotion"
        case .general:
            return "General"
        }
    }
    
    var iconName: String {
        switch self {
        case .orderUpdate, .orderReady, .orderDelivered:
            return "shippingbox"
        case .orderCancelled:
            return "xmark.circle"
        case .paymentUpdate:
            return "creditcard"
        case .storeUpdate:
            return "storefront"
        case .promotion:
            return "tag"
        case .general:
            return "bell"
        }
    }
    
    var priority: NotificationPriority {
        switch self {
        case .orderReady, .orderDelivered:
            return .high
        case .orderUpdate, .orderCancelled, .paymentUpdate:
            return .medium
        case .storeUpdate, .promotion, .general:
            return .low
        }
    }
}

/// Priority levels for notifications
enum NotificationPriority: Int, CaseIterable, Codable {
    case low = 0
    case medium = 1
    case high = 2
    
    var displayName: String {
        switch self {
        case .low:
            return "Low"
        case .medium:
            return "Medium"
        case .high:
            return "High"
        }
    }
}

/// FCM token information for device registration
struct FCMToken: Codable {
    let token: String
    let deviceID: String
    let platform: String = "ios"
    let appVersion: String
    let timestamp: Date
    
    init(token: String, deviceID: String) {
        self.token = token
        self.deviceID = deviceID
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        self.timestamp = Date()
    }
}

/// Notification settings for user preferences
struct NotificationSettings: Codable {
    var orderUpdates: Bool = true
    var orderReady: Bool = true
    var orderDelivered: Bool = true
    var orderCancelled: Bool = true
    var paymentUpdates: Bool = true
    var storeUpdates: Bool = false
    var promotions: Bool = false
    var general: Bool = true
    
    var isEnabled: Bool {
        return orderUpdates || orderReady || orderDelivered || orderCancelled || 
               paymentUpdates || storeUpdates || promotions || general
    }
    
    func isEnabled(for type: NotificationType) -> Bool {
        switch type {
        case .orderUpdate:
            return orderUpdates
        case .orderReady:
            return orderReady
        case .orderDelivered:
            return orderDelivered
        case .orderCancelled:
            return orderCancelled
        case .paymentUpdate:
            return paymentUpdates
        case .storeUpdate:
            return storeUpdates
        case .promotion:
            return promotions
        case .general:
            return general
        }
    }
    
    mutating func setEnabled(_ enabled: Bool, for type: NotificationType) {
        switch type {
        case .orderUpdate:
            orderUpdates = enabled
        case .orderReady:
            orderReady = enabled
        case .orderDelivered:
            orderDelivered = enabled
        case .orderCancelled:
            orderCancelled = enabled
        case .paymentUpdate:
            paymentUpdates = enabled
        case .storeUpdate:
            storeUpdates = enabled
        case .promotion:
            promotions = enabled
        case .general:
            general = enabled
        }
    }
}

/// Notification payload structure for FCM
struct NotificationPayload: Codable {
    let title: String
    let body: String
    let type: String
    let data: [String: String]
    let sound: String?
    let badge: Int?
    
    init(
        title: String,
        body: String,
        type: NotificationType,
        data: [String: String] = [:],
        sound: String? = "default",
        badge: Int? = nil
    ) {
        self.title = title
        self.body = body
        self.type = type.rawValue
        self.data = data
        self.sound = sound
        self.badge = badge
    }
}

/// Extension for creating notifications from FCM payload
extension ZipNotification {
    init(from payload: NotificationPayload, id: String = UUID().uuidString) {
        self.id = id
        self.title = payload.title
        self.body = payload.body
        self.data = payload.data
        self.timestamp = Date()
        self.type = NotificationType(rawValue: payload.type) ?? .general
        self.isRead = false
    }
}
