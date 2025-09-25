//
//  OrderStatusBannerDemo.swift
//  Zip
//

import SwiftUI

struct OrderStatusBannerDemo: View {
    @StateObject private var orderStatusViewModel = OrderStatusViewModel()
    @State private var selectedStatus: OrderStatus = .inQueue
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppMetrics.spacingLarge) {
                // Status selector
                Picker("Order Status", selection: $selectedStatus) {
                    Text("In Queue").tag(OrderStatus.inQueue)
                    Text("In Progress").tag(OrderStatus.inProgress)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppMetrics.spacingLarge)
                
                // Demo controls
                VStack(spacing: AppMetrics.spacing) {
                    Button("Show In-Queue Order") {
                        showMockOrder(status: .inQueue)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Show In-Progress Order") {
                        showMockOrder(status: .inProgress)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Hide Banner") {
                        orderStatusViewModel.dismissBanner()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal, AppMetrics.spacingLarge)
                
                Spacer()
                
                // Order info display
                if let order = orderStatusViewModel.activeOrder {
                    VStack(alignment: .leading, spacing: AppMetrics.spacing) {
                        Text("Current Order:")
                            .font(.headline)
                        
                        Text("Status: \(order.status.displayName)")
                            .font(.subheadline)
                        
                        if let eta = order.estimatedDeliveryTime {
                            Text("ETA: \(eta, style: .time)")
                                .font(.subheadline)
                        }
                        
                        Text("Total: $\(String(format: "%.2f", NSDecimalNumber(decimal: order.totalAmount).doubleValue))")
                            .font(.subheadline)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(AppMetrics.cornerRadiusLarge)
                    .padding(.horizontal, AppMetrics.spacingLarge)
                }
            }
            .navigationTitle("Order Banner Demo")
            .navigationBarTitleDisplayMode(.inline)
        }
        .overlay(
            // Order status banner at the top
            VStack {
                OrderStatusBannerContainer(
                    activeOrder: orderStatusViewModel.activeOrder,
                    onBannerDismiss: {
                        orderStatusViewModel.dismissBanner()
                    }
                )
                
                Spacer()
            }
        )
    }
    
    private func showMockOrder(status: OrderStatus) {
        let mockUser = User(
            id: "demo-user-id",
            email: "demo@u.northwestern.edu",
            firstName: "Demo",
            lastName: "User",
            phoneNumber: "123-456-7890",
            storeCredit: 0.0,
            role: .customer,
            verified: true,
            fcmToken: nil
        )
        
        let mockOrder = Order(
            user: mockUser,
            items: [],
            status: status,
            rawAmount: 15.99,
            tip: 2.00,
            totalAmount: 17.99,
            deliveryAddress: "123 Demo St",
            estimatedDeliveryTime: Date().addingTimeInterval(status == .inQueue ? 1800 : 600) // 30 min for queue, 10 min for progress
        )
        
        orderStatusViewModel.activeOrder = mockOrder
    }
}

#Preview {
    OrderStatusBannerDemo()
}
