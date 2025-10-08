//
//  ProfileView.swift
//  Zip
//

import SwiftUI
import Inject

struct ProfileView: View {
    @ObserveInjection var inject
    @ObservedObject var authViewModel: AuthViewModel
    @StateObject private var fcmService = FCMService.shared
    private let supabaseService = SupabaseService.shared
    
    // Delete account confirmation states
    @State private var showingDeleteConfirmation = false
    @State private var showingFinalConfirmation = false
    @State private var deleteConfirmationText = ""
    
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
                            VStack(spacing: AppMetrics.spacingSmall) {
                                Text(user.fullName)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(AppColors.textPrimary)
                                
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundStyle(AppColors.textSecondary)
                                
                                Text(user.phoneNumber)
                                    .font(.caption)
                                    .foregroundStyle(AppColors.textSecondary)
                                
                                HStack {
                                    Image(systemName: "creditcard.fill")
                                        .foregroundStyle(AppColors.accent)
                                    Text("Zip Credit: $\(String(format: "%.2f", NSDecimalNumber(decimal: user.storeCredit).doubleValue))")
                                        .font(.caption)
                                        .foregroundStyle(AppColors.textSecondary)
                                }
                            }
                        } else {
                            Text("Not Signed In")
                                .font(.headline)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                    .padding(.top, AppMetrics.spacingLarge)
                    
                    // Profile Options
                    VStack(spacing: AppMetrics.spacing) {                       
                        NavigationLink(destination: StoreHoursView()) {
                            ProfileOptionRow(
                                icon: "calendar",
                                title: "Store Hours",
                                subtitle: "Check when we're accepting orders"
                            )
                        }
                        

                        NavigationLink(destination: ReportBugView()) {
                            ProfileOptionRow(
                                icon: "ladybug",
                                title: "Report a Bug",
                                subtitle: "Help us improve Zip"
                            )
                        }
                        
                        // Delete Account Button
                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            ProfileOptionRow(
                                icon: "trash",
                                title: "Delete Account",
                                subtitle: "Permanently remove your account and data",
                                isDestructive: true
                            )
                        }
                        .buttonStyle(.plain)
                        
                    }
                    .padding(.horizontal, AppMetrics.spacingLarge)
                    
                    Spacer()
                    
                    // Logout Button
                    if authViewModel.isAuthenticated {
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
            }
            .navigationTitle("Profile")
        }
        .alert("Delete Account", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Continue", role: .destructive) {
                showingFinalConfirmation = true
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone and will permanently remove all your data including order history, cart items, and account information.")
        }
        .alert("Final Confirmation", isPresented: $showingFinalConfirmation) {
            TextField("Type 'DELETE' to confirm", text: $deleteConfirmationText)
            Button("Cancel", role: .cancel) {
                deleteConfirmationText = ""
            }
            Button("Delete Account", role: .destructive) {
                Task {
                    await authViewModel.deleteAccount()
                }
                deleteConfirmationText = ""
            }
            .disabled(deleteConfirmationText != "DELETE")
        } message: {
            VStack(alignment: .leading, spacing: 8) {
                Text("This will permanently delete:")
                Text("• Your account and profile")
                Text("• All order history")
                Text("• Push notification tokens")
                Text("• All associated data")
                
                Text("\nType 'DELETE' in the text field to confirm this action.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
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
    let isDestructive: Bool
    
    init(icon: String, title: String, subtitle: String, isDestructive: Bool = false) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.isDestructive = isDestructive
    }
    
    var body: some View {
            HStack(spacing: AppMetrics.spacing) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isDestructive ? .red : AppColors.accent)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(isDestructive ? .red : AppColors.textPrimary)
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
}
