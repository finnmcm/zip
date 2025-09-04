//
//  StoreHoursView.swift
//  Zip
//

import SwiftUI
import Inject

struct StoreHoursView: View {
    @ObserveInjection var inject
    
    // Get store hours from the shared manager
    private var storeHours: [StoreHour] {
        StoreHoursManager.shared.allStoreHours
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppMetrics.spacingLarge) {
                        Text("Note: Zip is still in development. These hours are subject to change!")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppMetrics.spacingLarge)
                        VStack(spacing: AppMetrics.spacing) {
                            Image(systemName: isStoreOpen ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(isStoreOpen ? AppColors.success : AppColors.error)
                            
                            VStack(spacing: AppMetrics.spacingSmall) {
                                Text(isStoreOpen ? "We're Open!" : "We're Closed")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundStyle(AppColors.textPrimary)
                                
                                Text(statusMessage)
                                    .font(.subheadline)
                                    .foregroundStyle(AppColors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, AppMetrics.spacingLarge)
                        
                        // Store Hours List
                        VStack(spacing: AppMetrics.spacing) {
                            Text("Store Hours")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppColors.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(spacing: AppMetrics.spacingSmall) {
                                ForEach(storeHours, id: \.day) { storeHour in
                                    StoreHourRow(
                                        storeHour: storeHour,
                                        isToday: isToday(storeHour.day)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, AppMetrics.spacingLarge)
                        
                        /*
                        // Additional Information
                        VStack(spacing: AppMetrics.spacing) {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundStyle(AppColors.info)
                                Text("Important Notes")
                                    .font(.headline)
                                    .foregroundStyle(AppColors.textPrimary)
                                Spacer()
                            }
                            
                            VStack(alignment: .leading, spacing: AppMetrics.spacingSmall) {
                                InfoRow(
                                    icon: "clock",
                                    text: "Orders placed after closing time will be delivered the next business day"
                                )
                                
                                InfoRow(
                                    icon: "map",
                                    text: "Delivery available to Northwestern University campus and surrounding areas"
                                )
                                
                                InfoRow(
                                    icon: "exclamationmark.triangle",
                                    text: "Hours may vary during holidays and exam periods"
                                )
                            }
                        }
                        .padding(.horizontal, AppMetrics.spacingLarge)
                        .padding(.vertical, AppMetrics.spacing)
                        .background(AppColors.secondaryBackground)
                        .cornerRadius(AppMetrics.cornerRadiusLarge)
                        .padding(.horizontal, AppMetrics.spacingLarge)*/
                        
                        Spacer(minLength: AppMetrics.spacingLarge)
                    }
                }
            }
            .navigationTitle("Store Hours")
            .navigationBarTitleDisplayMode(.large)
        }
        .enableInjection()
    }
    
    // MARK: - Computed Properties
    
    private var isStoreOpen: Bool {
        StoreHoursManager.shared.isStoreOpen
    }
    
    private var statusMessage: String {
        if isStoreOpen {
            let now = Date()
            let calendar = Calendar.current
            let currentWeekday = calendar.component(.weekday, from: now)
            let dayIndex = (currentWeekday + 5) % 7
            let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
            let today = days[dayIndex]
            
            if let todayHours = storeHours.first(where: { $0.day == today }) {
                return "Open until \(todayHours.closeTime) today"
            }
        } else {
            return StoreHoursManager.shared.nextOpeningMessage
        }
        
        return "Check back soon for updated hours"
    }
    
    // MARK: - Helper Methods
    
    private func isToday(_ day: String) -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: now)
        let dayIndex = (currentWeekday + 5) % 7
        let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        return days[dayIndex] == day
    }
    
}

// MARK: - Supporting Views

private struct StoreHourRow: View {
    let storeHour: StoreHour
    let isToday: Bool
    
    var body: some View {
        HStack {
            Text(storeHour.day)
                .font(.body)
                .fontWeight(isToday ? .semibold : .regular)
                .foregroundStyle(isToday ? AppColors.accent : AppColors.textPrimary)
            
            Spacer()
            
            Text("\(storeHour.openTime) - \(storeHour.closeTime)")
                .font(.body)
                .foregroundStyle(AppColors.textSecondary)
            
            if isToday {
                Text("Today")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.accent)
                    .padding(.horizontal, AppMetrics.spacingSmall)
                    .padding(.vertical, 2)
                    .background(AppColors.accent.opacity(0.1))
                    .cornerRadius(AppMetrics.cornerRadiusSmall)
            }
        }
        .padding()
        .background(isToday ? AppColors.accent.opacity(0.05) : AppColors.secondaryBackground)
        .cornerRadius(AppMetrics.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppMetrics.cornerRadius)
                .stroke(isToday ? AppColors.accent.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

private struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: AppMetrics.spacing) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(AppColors.info)
                .frame(width: 16)
            
            Text(text)
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}


#Preview {
    StoreHoursView()
}
