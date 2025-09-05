//
//  StoreClosedBanner.swift
//  Zip
//

import SwiftUI

struct StoreClosedBanner: View {
    @State private var isVisible = false
    let currentUser: User?
    
    init(currentUser: User? = nil) {
        self.currentUser = currentUser
    }
    
    private var bannerTitle: String {
        if currentUser?.role == .admin {
            return "Store Closed (Admin Override Available)"
        } else {
            return "Store Closed"
        }
    }
    
    private var bannerMessage: String {
        if currentUser?.role == .admin {
            return "You can still place orders as an admin"
        } else {
            return nextOpeningMessage
        }
    }
    
    private var nextOpeningMessage: String {
        let storeManager = StoreHoursManager.shared
        
        if storeManager.isNextOpeningToday {
            // If next opening is today, show more specific message
            let now = Date()
            let calendar = Calendar.current
            let currentWeekday = calendar.component(.weekday, from: now)
            let dayIndex = (currentWeekday + 5) % 7
            let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
            let today = days[dayIndex]
            
            if let todayHours = storeManager.allStoreHours.first(where: { $0.day == today }) {
                return "Opens at \(todayHours.openTime) today"
            }
        }
        
        // Fall back to the existing logic for future days
        return storeManager.nextOpeningMessage
    }
    
    var body: some View {
        if !StoreHoursManager.shared.isStoreOpen {
            HStack(spacing: AppMetrics.spacing) {
                Image(systemName: currentUser?.role == .admin ? "person.crop.circle.fill" : "clock.fill")
                    .foregroundColor(.white)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(bannerTitle)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(bannerMessage)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                NavigationLink(destination: StoreHoursView()) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.title3)
                }
            }
            .padding(.horizontal, AppMetrics.spacingLarge)
            .padding(.vertical, AppMetrics.spacing)
            .background(AppColors.warning)
            .cornerRadius(AppMetrics.cornerRadiusLarge)
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            .padding(.horizontal, AppMetrics.spacingLarge)
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .opacity(isVisible ? 1.0 : 0.0)
            .offset(y: isVisible ? 0 : -20)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isVisible)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isVisible = true
                }
            }
        }
    }
}


#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()
        
        VStack {
            StoreClosedBanner()
            Spacer()
        }
    }
}
