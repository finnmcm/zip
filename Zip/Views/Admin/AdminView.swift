import Foundation
import SwiftUI

struct AdminView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @StateObject private var adminViewModel = AdminViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Admin Dashboard")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Manage your Zip operations")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Error State
                if let errorMessage = adminViewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text("Error loading data")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task {
                                await adminViewModel.loadAdminData()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
                // Loading State
                else if adminViewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading admin data...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    // Quick Stats Cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(
                            title: "Orders",
                            value: "\(adminViewModel.totalOrdersFulfilled)",
                            icon: "cart.fill",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "Total Revenue",
                            value: adminViewModel.formattedTotalRevenue,
                            icon: "dollarsign.circle.fill",
                            color: .green
                        )
                        
                        StatCard(
                            title: "Active Zippers",
                            value: "\(adminViewModel.activeZippers)",
                            icon: "bicycle",
                            color: .orange
                        )
                        
                        StatCard(
                            title: "Customers",
                            value: "\(adminViewModel.numUsers)",
                            icon: "person.3.fill",
                            color: .purple
                        )
                    }
                    .padding(.horizontal)
                }
                
                // Tab View Section
                VStack(alignment: .leading, spacing: 12) {
                    // Custom Tab Picker
                    HStack(spacing: 0) {
                        TabButton(title: "Activity", isSelected: selectedTab == 0) {
                            selectedTab = 0
                        }
                        
                        TabButton(title: "Low-Stock", isSelected: selectedTab == 1) {
                            selectedTab = 1
                        }
                        
                        TabButton(title: "Zippers", isSelected: selectedTab == 2) {
                            selectedTab = 2
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
                    .padding(.horizontal)
                    
                    TabView(selection: $selectedTab) {
                        // Recent Activity Tab
                        VStack(spacing: 8) {
                            ActivityRow(
                                icon: "cart.fill",
                                title: "New Order #1234",
                                subtitle: "2 minutes ago",
                                color: .blue
                            )
                            
                            ActivityRow(
                                icon: "checkmark.circle.fill",
                                title: "Order #1233 Completed",
                                subtitle: "5 minutes ago",
                                color: .green
                            )
                            
                            ActivityRow(
                                icon: "exclamationmark.triangle.fill",
                                title: "Low Stock Alert",
                                subtitle: "Coffee - 3 items left",
                                color: .orange
                            )
                        }
                        .padding(.horizontal)
                        .tag(0)
                        
                        // Low-Stock Items Tab
                        VStack(spacing: 8) {
                            Text("Low-Stock Items content will go here")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                        .tag(1)
                        
                        // Zipper Statistics Tab
                        VStack(spacing: 8) {
                            Text("Zipper Statistics content will go here")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                        .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: 200)
                }
                .padding(.top)
            }
        }
        .onAppear {
            Task {
                await adminViewModel.loadAdminData()
            }
        }
    }
}

// Stat Card Component
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// Activity Row Component
struct ActivityRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// Tab Button Component
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .medium)
                .foregroundColor(isSelected ? .primary : .secondary)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color(.systemBackground) : Color.clear)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}