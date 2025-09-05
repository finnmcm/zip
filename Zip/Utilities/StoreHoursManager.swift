//
//  StoreHoursManager.swift
//  Zip
//

import Foundation

class StoreHoursManager {
    static let shared = StoreHoursManager()
    
    private init() {}
    
    // Reference to current user for admin checks
    private weak var currentUser: User?
    
    // Store hours for Northwestern University delivery service
    private let storeHours: [StoreHour] = [
        StoreHour(day: "Monday", openTime: "1:00 PM", closeTime: "12:00 AM"),
        StoreHour(day: "Tuesday", openTime: "5:00 PM", closeTime: "12:00 AM"),
        StoreHour(day: "Wednesday", openTime: "1:00 PM", closeTime: "12:00 AM"),
        StoreHour(day: "Thursday", openTime: "5:00 PM", closeTime: "12:00 AM"),
        StoreHour(day: "Friday", openTime: "1:00 PM", closeTime: "12:00 AM"),
        StoreHour(day: "Saturday", openTime: "10:00 AM", closeTime: "12:00 AM"),
        StoreHour(day: "Sunday", openTime: "10:00 AM", closeTime: "10:00 PM")
    ]
    
    var isStoreOpen: Bool {
        let now = Date()
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: now)
        let currentTime = calendar.dateComponents([.hour, .minute], from: now)
        
        // Convert weekday to our day format (Sunday = 1, Monday = 2, etc.)
        let dayIndex = (currentWeekday + 5) % 7 // Convert to Monday = 0, Sunday = 6
        let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        let today = days[dayIndex]
        
        guard let todayHours = storeHours.first(where: { $0.day == today }) else {
            return false
        }
        
        let openTime = parseTime(todayHours.openTime)
        let closeTime = parseTime(todayHours.closeTime)
        
        let currentMinutes = (currentTime.hour ?? 0) * 60 + (currentTime.minute ?? 0)
        
        // Handle overnight hours (e.g., Friday 8 AM - Saturday 12 AM)
        if closeTime < openTime {
            return currentMinutes >= openTime || currentMinutes < closeTime
        } else {
            return currentMinutes >= openTime && currentMinutes < closeTime
        }
    }
    
    /// Sets the current user for admin role checking
    func setCurrentUser(_ user: User?) {
        currentUser = user
    }
    
    /// Checks if the current user can place orders (either store is open OR user is admin)
    var canPlaceOrders: Bool {
        return isStoreOpen || isCurrentUserAdmin
    }
    
    /// Checks if the current user is an admin
    var isCurrentUserAdmin: Bool {
        return currentUser?.role == .admin
    }
    
    var nextOpeningMessage: String {
        let now = Date()
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: now)
        let dayIndex = (currentWeekday + 5) % 7
        let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        
        // Check next few days for opening
        for i in 1...7 {
            let nextDayIndex = (dayIndex + i) % 7
            let nextDay = days[nextDayIndex]
            
            if let nextDayHours = storeHours.first(where: { $0.day == nextDay }) {
                if i == 1 {
                    return "Opens at \(nextDayHours.openTime) tomorrow"
                } else {
                    return "Opens at \(nextDayHours.openTime) on \(nextDay)"
                }
            }
        }
        
        return "Check back soon for updated hours"
    }
    
    var allStoreHours: [StoreHour] {
        return storeHours
    }
    
    var isNextOpeningToday: Bool {
        let now = Date()
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: now)
        let currentTime = calendar.dateComponents([.hour, .minute], from: now)
        let dayIndex = (currentWeekday + 5) % 7
        let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        let today = days[dayIndex]
        
        // If store is currently open, next opening is today
        if isStoreOpen {
            return true
        }
        
        // Check if there's an opening later today
        guard let todayHours = storeHours.first(where: { $0.day == today }) else {
            return false
        }
        
        let openTime = parseTime(todayHours.openTime)
        let currentMinutes = (currentTime.hour ?? 0) * 60 + (currentTime.minute ?? 0)
        
        // If current time is before opening time today, next opening is today
        return currentMinutes < openTime
    }
    
    private func parseTime(_ timeString: String) -> Int {
        let components = timeString.components(separatedBy: " ")
        let timePart = components[0]
        let period = components[1]
        
        let timeComponents = timePart.components(separatedBy: ":")
        var hour = Int(timeComponents[0]) ?? 0
        let minute = Int(timeComponents[1]) ?? 0
        
        if period == "PM" && hour != 12 {
            hour += 12
        } else if period == "AM" && hour == 12 {
            hour = 0
        }
        
        return hour * 60 + minute
    }
}

// MARK: - Data Models

public struct StoreHour {
    let day: String
    let openTime: String
    let closeTime: String
}
