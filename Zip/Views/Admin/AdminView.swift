import Foundation
import SwiftUI

struct AdminView: View {
    @ObservedObject var authViewModel: AuthViewModel
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
                
                // Quick Stats Cards
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatCard(
                        title: "Active Orders",
                        value: "12",
                        icon: "cart.fill",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "Total Revenue",
                        value: "$1,234",
                        icon: "dollarsign.circle.fill",
                        color: .green
                    )
                    
                    StatCard(
                        title: "Products",
                        value: "45",
                        icon: "bag.fill",
                        color: .orange
                    )
                    
                    StatCard(
                        title: "Customers",
                        value: "89",
                        icon: "person.3.fill",
                        color: .purple
                    )
                }
                .padding(.horizontal)
                
                // Recent Activity Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Activity")
                        .font(.headline)
                        .padding(.horizontal)
                    
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
                }
                .padding(.top)
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