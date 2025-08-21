//
//  ProfileView.swift
//  Zip
//

import SwiftUI
import Inject

struct ProfileView: View {
    @ObserveInjection var inject
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: AppMetrics.spacingLarge) {
                    // Profile Header
                    VStack(spacing: AppMetrics.spacing) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(AppColors.accent)
                        
                        if let user = authViewModel.currentUser {
                            Text(user.email)
                                .font(.headline)
                                .foregroundStyle(AppColors.textPrimary)
                        }
                        
                        Text("Northwestern Professor")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .padding(.top, AppMetrics.spacingLarge)
                    
                    // Profile Options
                    VStack(spacing: AppMetrics.spacing) {
                        ProfileOptionRow(
                            icon: "bag",
                            title: "Order History",
                            subtitle: "View your past orders"
                        ) {
                            // TODO: Navigate to order history
                        }
                        
                        ProfileOptionRow(
                            icon: "location",
                            title: "Delivery Addresses",
                            subtitle: "Manage your delivery locations"
                        ) {
                            // TODO: Navigate to address management
                        }
                        
                        ProfileOptionRow(
                            icon: "creditcard",
                            title: "Payment Methods",
                            subtitle: "Manage your payment options"
                        ) {
                            // TODO: Navigate to payment methods
                        }
                        
                        ProfileOptionRow(
                            icon: "questionmark.circle",
                            title: "Help & Support",
                            subtitle: "Get help with your orders"
                        ) {
                            // TODO: Navigate to support
                        }
                        
                    }
                    .padding(.horizontal, AppMetrics.spacingLarge)
                    
                    Spacer()
                    
                    // Logout Button
                    Button(action: {
                        Task {
                            await authViewModel.logout()
                        }
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(AppMetrics.cornerRadiusLarge)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppMetrics.cornerRadiusLarge)
                                .stroke(.red.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, AppMetrics.spacingLarge)
                    .padding(.bottom, AppMetrics.spacingLarge)
                }
            }
            .navigationTitle("Profile")
        }
        .enableInjection()
    }
    
    #if DEBUG
    private func checkDatabaseStatus() {
        // Simple status check that just prints a message
        print("📊 Database Status Check Requested")
        print("💡 Use the Reset Database button if you're experiencing issues")
    }
    #endif
}

private struct ProfileOptionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppMetrics.spacing) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(AppColors.accent)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding()
            .background(AppColors.secondaryBackground)
            .cornerRadius(AppMetrics.cornerRadiusLarge)
        }
        .buttonStyle(.plain)
    }
}
