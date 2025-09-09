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
                            icon: "scooter",
                            color: .orange
                        )
                        
                        StatCard(
                            title: "Low Stock",
                            value: "\(adminViewModel.lowStockCount)",
                            icon: "exclamationmark.triangle.fill",
                            color: adminViewModel.lowStockCount > 0 ? .red : .green
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
                        ScrollView {
                            VStack(spacing: 8) {
                                if adminViewModel.lowStockItems.isEmpty {
                                    VStack(spacing: 12) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.largeTitle)
                                            .foregroundColor(.green)
                                        Text("All items in stock!")
                                            .font(.headline)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                } else {
                                    ForEach(adminViewModel.lowStockItems) { product in
                                        LowStockItemRow(product: product)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .tag(1)
                        
                        // Zipper Statistics Tab
                        VStack(alignment: .leading, spacing: 8) {
                            // Header
                            HStack {
                                Text("Zipper Performance Rankings")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                if let zipperStats = adminViewModel.zipperStats {
                                    Text("\(zipperStats.zippers.count) zippers")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal)
                            
                            ScrollView {
                                VStack(spacing: 8) {
                                    if let zipperStats = adminViewModel.zipperStats, !zipperStats.zippers.isEmpty {
                                        ForEach(Array(zipperStats.zippers.enumerated()), id: \.element.id) { index, zipper in
                                            ZipperStatsRow(
                                                zipper: zipper,
                                                rank: index + 1,
                                                isTopPerformer: index < 3
                                            )
                                        }
                                    } else {
                                        VStack(spacing: 12) {
                                            Image(systemName: "scooter")
                                                .font(.largeTitle)
                                                .foregroundColor(.secondary)
                                            Text("No zipper data available")
                                                .font(.headline)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding()
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: 300)
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

// Low Stock Item Row Component
struct LowStockItemRow: View {
    let product: Product
    
    var body: some View {
        HStack(spacing: 12) {
            // Product Image
            AsyncImage(url: URL(string: product.imageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.secondary)
                    )
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Product Info
            VStack(alignment: .leading, spacing: 4) {
                Text(product.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(product.category.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Quantity Info
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(product.quantity)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(quantityColor)
                
                Text("left")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var quantityColor: Color {
        switch product.quantity {
        case 0:
            return .red
        case 1:
            return .orange
        case 2:
            return .yellow
        default:
            return .primary
        }
    }
}

// Zipper Statistics Row Component
struct ZipperStatsRow: View {
    let zipper: ZipperStatsResult.ZipperStats
    let rank: Int
    let isTopPerformer: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank Badge
            ZStack {
                Circle()
                    .fill(rankColor)
                    .frame(width: 32, height: 32)
                
                if rank <= 3 {
                    Image(systemName: rankIcon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(rank)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            // Zipper Info
            VStack(alignment: .leading, spacing: 4) {
                Text(zipper.user.fullName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(zipper.user.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Statistics
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 16) {
                    // Orders Handled
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(zipper.ordersHandled)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("orders")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Revenue Generated
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "$%.2f", zipper.revenue))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        
                        Text("revenue")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isTopPerformer ? Color(.systemGray6).opacity(0.8) : Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isTopPerformer ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }
    
    private var rankColor: Color {
        switch rank {
        case 1:
            return .yellow // Gold
        case 2:
            return Color(.systemGray2) // Silver
        case 3:
            return Color.orange // Bronze
        default:
            return Color(.systemGray4)
        }
    }
    
    private var rankIcon: String {
        switch rank {
        case 1:
            return "crown.fill"
        case 2:
            return "medal.fill"
        case 3:
            return "award.fill"
        default:
            return "person.fill"
        }
    }
}