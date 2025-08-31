//
//  OrderHistoryView.swift
//  Zip
//
//  Created by AI Assistant on 2024
//

import SwiftUI

struct OrderHistoryView: View {
    @State private var orders: [Order] = []
    @State private var isLoading = false
    @State private var selectedOrder: Order?
    @State private var showingOrderDetail = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                if orders.isEmpty && !isLoading {
                    emptyStateView
                } else {
                    orderListView
                }
            }
            .navigationTitle("Order History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        loadOrders()
                    }
                    .foregroundColor(AppColors.accent)
                }
            }
            .sheet(isPresented: $showingOrderDetail) {
                if let order = selectedOrder {
                    OrderDetailView(order: order)
                }
            }
            .onAppear {
                loadOrders()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: AppMetrics.spacingLarge) {
            Image(systemName: "bag.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(AppColors.textSecondary)
            
            Text("No Orders Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Your order history will appear here once you place your first order.")
                .font(.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppMetrics.spacingLarge)
            
            Button("Start Shopping") {
                // Navigate to shopping view
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.accent)
        }
        .padding()
    }
    
    private var orderListView: some View {
        List {
            ForEach(orders) { order in
                OrderHistoryRow(order: order) {
                    selectedOrder = order
                    showingOrderDetail = true
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            await refreshOrders()
        }
    }
    
    private func loadOrders() {
        isLoading = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            orders = generateDummyOrders()
            isLoading = false
        }
    }
    
    private func refreshOrders() async {
        // Simulate async refresh
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await MainActor.run {
            orders = generateDummyOrders()
        }
    }
    
    private func generateDummyOrders() -> [Order] {
        let dummyUser = User(
            id: "dummy-user-123",
            email: "student@u.northwestern.edu",
            firstName: "Alex",
            lastName: "Johnson",
            phoneNumber: "+1-555-0123"
        )
        
        let dummyProducts = [
            Product(
                inventoryName: "coffee_latte",
                displayName: "Vanilla Latte",
                price: 4.99,
                quantity: 10,
                category: .drinks
            ),
            Product(
                inventoryName: "energy_drink",
                displayName: "Red Bull",
                price: 3.49,
                quantity: 15,
                category: .drinks
            ),
            Product(
                inventoryName: "chips_bbq",
                displayName: "BBQ Chips",
                price: 2.99,
                quantity: 20,
                category: .chipscandy
            ),
            Product(
                inventoryName: "granola_bar",
                displayName: "Granola Bar",
                price: 1.99,
                quantity: 25,
                category: .foodsnacks
            ),
            Product(
                inventoryName: "water_bottle",
                displayName: "Water Bottle",
                price: 1.49,
                quantity: 30,
                category: .drinks
            )
        ]
        
        let orders = [
            Order(
                user: dummyUser,
                items: [
                    CartItem(product: dummyProducts[0], quantity: 1, userId: UUID()),
                    CartItem(product: dummyProducts[2], quantity: 1, userId: UUID())
                ],
                status: .delivered,
                rawAmount: 12.97,
                tip: 2.00,
                totalAmount: 14.97,
                deliveryAddress: "Elder Hall, Room 305",
                createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                estimatedDeliveryTime: Calendar.current.date(byAdding: .minute, value: 25, to: Date()) ?? Date(),
                actualDeliveryTime: Calendar.current.date(byAdding: .minute, value: 23, to: Date()) ?? Date()
            ),
            
            Order(
                user: dummyUser,
                items: [
                    CartItem(product: dummyProducts[1], quantity: 1, userId: UUID()),
                    CartItem(product: dummyProducts[3], quantity: 2, userId: UUID()),
                    CartItem(product: dummyProducts[4], quantity: 1, userId: UUID())
                ],
                status: .delivered,
                rawAmount: 10.46,
                tip: 1.50,
                totalAmount: 11.96,
                deliveryAddress: "Willard Hall, Room 127",
                createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
                estimatedDeliveryTime: Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date(),
                actualDeliveryTime: Calendar.current.date(byAdding: .minute, value: 28, to: Date()) ?? Date()
            ),
            
            Order(
                user: dummyUser,
                items: [
                    CartItem(product: dummyProducts[0], quantity: 1, userId: UUID()),
                    CartItem(product: dummyProducts[2], quantity: 2, userId: UUID())
                ],
                status: .inQueue,
                rawAmount: 10.97,
                tip: 1.75,
                totalAmount: 12.72,
                deliveryAddress: "Sargent Hall, Room 412",
                createdAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
                estimatedDeliveryTime: Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
            ),
            
            Order(
                user: dummyUser,
                items: [
                    CartItem(product: dummyProducts[1], quantity: 1, userId: UUID()),
                    CartItem(product: dummyProducts[4], quantity: 2, userId: UUID())
                ],
                status: .inProgress,
                rawAmount: 6.47,
                tip: 1.00,
                totalAmount: 7.47,
                deliveryAddress: "Foster-Walker Complex, Room 208",
                createdAt: Calendar.current.date(byAdding: .minute, value: -45, to: Date()) ?? Date(),
                estimatedDeliveryTime: Calendar.current.date(byAdding: .minute, value: 35, to: Date()) ?? Date()
            ),
            
            Order(
                user: dummyUser,
                items: [
                    CartItem(product: dummyProducts[3], quantity: 3, userId: UUID()),
                    CartItem(product: dummyProducts[0], quantity: 1, userId: UUID())
                ],
                status: .cancelled,
                rawAmount: 7.96,
                tip: 0.00,
                totalAmount: 7.96,
                deliveryAddress: "Allison Hall, Room 156",
                createdAt: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()
            )
        ]
        
        return orders.sorted { $0.createdAt > $1.createdAt }
    }
}

struct OrderHistoryRow: View {
    let order: Order
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppMetrics.spacingSmall) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(order.deliveryAddress)
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                            .lineLimit(1)
                        
                        Text(order.createdAt, style: .date)
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Spacer()
                    
              /*      VStack(alignment: .trailing, spacing: 4) {
                        Text("$\(order.totalAmount, specifier: "%.2f")")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.accent)
                        
                        StatusBadge(status: order.status)
                    }*/
                }
                
                HStack {
                    Text("\(order.items.count) item\(order.items.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Spacer()
                    
                    if let estimatedTime = order.estimatedDeliveryTime {
                        Text("Est. \(estimatedTime, style: .time)")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                // Quick preview of items
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppMetrics.spacingSmall) {
                        ForEach(order.items.prefix(3)) { item in
                            Text("\(item.quantity)x \(item.product.displayName)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppColors.secondaryBackground)
                                .foregroundColor(AppColors.textSecondary)
                                .cornerRadius(AppMetrics.cornerRadiusSmall)
                        }
                        
                        if order.items.count > 3 {
                            Text("+\(order.items.count - 3) more")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                                .italic()
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding(AppMetrics.spacing)
            .background(AppColors.secondaryBackground)
            .cornerRadius(AppMetrics.cornerRadiusLarge)
        }
        .buttonStyle(PlainButtonStyle())
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 4, leading: AppMetrics.spacing, bottom: 4, trailing: AppMetrics.spacing))
    }
}

struct StatusBadge: View {
    let status: OrderStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(AppMetrics.cornerRadiusSmall)
    }
    
    private var statusColor: Color {
        switch status {
        case .pending:
            return .orange
        case .inQueue:
            return .blue
        case .inProgress:
            return AppColors.northwesternPurple
        case .delivered:
            return .green
        case .cancelled:
            return .red
        case .disputed:
            return .red
        }
    }
}

struct OrderDetailView: View {
    let order: Order
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppMetrics.spacingLarge) {
                    // Order Summary
                    orderSummarySection
                    
                    // Items List
                    itemsSection
                    
                    // Delivery Details
                    deliverySection
                    
                    // Payment Details
                    paymentSection
                }
                .padding()
            }
            .navigationTitle("Order Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var orderSummarySection: some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacing) {
            Text("Order Summary")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: AppMetrics.spacingSmall) {
                HStack {
                    Text("Order ID")
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text(order.id.uuidString.prefix(8).uppercased())
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                HStack {
                    Text("Status")
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    StatusBadge(status: order.status)
                }
                
                HStack {
                    Text("Order Date")
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text(order.createdAt, style: .date)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                HStack {
                    Text("Order Time")
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text(order.createdAt, style: .time)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
            .padding()
            .background(AppColors.secondaryBackground)
            .cornerRadius(AppMetrics.cornerRadiusLarge)
        }
    }
    
    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacing) {
            Text("Items")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: AppMetrics.spacingSmall) {
                ForEach(order.items) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.product.displayName)
                                .font(.body)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text(item.product.category.displayName)
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        Spacer()
                        
                      /*  VStack(alignment: .trailing, spacing: 2) {
                            Text("$\(item.product.price, specifier: "%.2f")")
                                .font(.body)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("Qty: \(item.quantity)")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }*/
                    }
                    .padding()
                    .background(AppColors.secondaryBackground)
                    .cornerRadius(AppMetrics.cornerRadiusLarge)
                }
            }
        }
    }
    
    private var deliverySection: some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacing) {
            Text("Delivery Details")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: AppMetrics.spacingSmall) {
                HStack {
                    Text("Address")
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text(order.deliveryAddress)
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.trailing)
                }
                
                if let estimatedTime = order.estimatedDeliveryTime {
                    HStack {
                        Text("Estimated Delivery")
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                        Text(estimatedTime, style: .time)
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
                
                if let actualTime = order.actualDeliveryTime {
                    HStack {
                        Text("Actual Delivery")
                        .foregroundColor(AppColors.textSecondary)
                        Spacer()
                        Text(actualTime, style: .time)
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
            }
            .padding()
            .background(AppColors.secondaryBackground)
            .cornerRadius(AppMetrics.cornerRadiusLarge)
        }
    }
    
    private var paymentSection: some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacing) {
            Text("Payment Details")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: AppMetrics.spacingSmall) {
                HStack {
                    Text("Subtotal")
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                   /* Text("$\(order.rawAmount, specifier: "%.2f")")
                        .foregroundColor(AppColors.textPrimary)*/
                }
                
                HStack {
                    Text("Tip")
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                  /*  Text("$\(order.tip, specifier: "%.2f")")
                        .foregroundColor(AppColors.textPrimary)*/
                }
                
                Divider()
                
                HStack {
                    Text("Total")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                 /*   Text("$\(order.totalAmount, specifier: "%.2f")")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.accent)*/
                }
            }
            .padding()
            .background(AppColors.secondaryBackground)
            .cornerRadius(AppMetrics.cornerRadiusLarge)
        }
    }
}

#Preview {
    OrderHistoryView()
}
