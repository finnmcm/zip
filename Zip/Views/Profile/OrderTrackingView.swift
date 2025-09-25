//
//  OrderTrackingView.swift
//  Zip
//

import SwiftUI

struct OrderTrackingView: View {
    let order: Order
    @StateObject private var viewModel = OrderTrackingViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppMetrics.spacingLarge) {
                headerSection
                orderStatusSection
                orderDetailsSection
                orderItemsSection
                deliveryInfoSection
                actionButtonsSection
            }
            .padding(.horizontal, AppMetrics.spacing)
        }
        .refreshable {
            await viewModel.refreshOrderStatus()
        }
        .onAppear {
            viewModel.setOrder(order)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: AppMetrics.spacing) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.northwesternPurple)
                }
                
                Spacer()
                
                Text("Order Tracking")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.northwesternPurple)
                
                Spacer()
                
                // Invisible spacer to center the title
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.clear)
            }
            
            Divider()
        }
    }
    
    // MARK: - Order Status Section
    private var orderStatusSection: some View {
        VStack(spacing: AppMetrics.spacing) {
            HStack {
                Text("Status")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(order.status.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(order.status.color)
                    .padding(.horizontal, AppMetrics.spacingSmall)
                    .padding(.vertical, AppMetrics.spacingSmall / 2)
                    .background(order.status.color.opacity(0.1))
                    .cornerRadius(AppMetrics.cornerRadiusSmall)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Order Details Section
    private var orderDetailsSection: some View {
        VStack(spacing: AppMetrics.spacing) {
            HStack {
                Text("Order Details")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(spacing: AppMetrics.spacingSmall) {
                detailRow(title: "Order ID", value: order.id.uuidString.prefix(8).uppercased())
                detailRow(title: "Order Date", value: order.createdAt.formatted(date: .abbreviated, time: .shortened))
                detailRow(title: "Total Amount", value: order.totalAmount.formatted(.currency(code: "USD")))
                detailRow(title: "Tip", value: order.tip.formatted(.currency(code: "USD")))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Order Items Section
    private var orderItemsSection: some View {
        VStack(spacing: AppMetrics.spacing) {
            HStack {
                Text("Order Items")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            LazyVStack(spacing: AppMetrics.spacingSmall) {
                ForEach(order.items) { item in
                    orderItemRow(item)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Delivery Info Section
    private var deliveryInfoSection: some View {
        VStack(spacing: AppMetrics.spacing) {
            HStack {
                Text("Delivery Information")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(spacing: AppMetrics.spacingSmall) {
                detailRow(title: "Delivery Address", value: order.deliveryAddress)
                if let estimatedTime = order.estimatedDeliveryTime {
                    detailRow(title: "Estimated Delivery", value: estimatedTime.formatted(date: .omitted, time: .shortened))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: AppMetrics.spacing) {
            Button(action: {
                // Cancel Order action
                print("Cancel Order tapped")
            }) {
                Text("Cancel Order")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppMetrics.spacing)
                    .padding(.horizontal, AppMetrics.spacing)
                    .background(AppColors.northwesternPurple)
                    .cornerRadius(AppMetrics.cornerRadiusSmall)
            }
            
            Button(action: {
                // Report Problem action
                print("Report Problem tapped")
            }) {
                Text("Report Problem")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppMetrics.spacing)
                    .padding(.horizontal, AppMetrics.spacing)
                    .background(AppColors.northwesternPurple)
                    .cornerRadius(AppMetrics.cornerRadiusSmall)
            }
        }
        .padding(.top, AppMetrics.spacing)
        .padding(.bottom, AppMetrics.spacingLarge)
    }
    
    // MARK: - Helper Views
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
    
    private func orderItemRow(_ item: CartItem) -> some View {
        HStack(spacing: AppMetrics.spacingSmall) {
            // Placeholder for product image
            RoundedRectangle(cornerRadius: AppMetrics.cornerRadiusSmall)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.product.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(item.product.category.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Qty: \(item.quantity)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text((item.product.price * Decimal(item.quantity)).formatted(.currency(code: "USD")))
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .padding(.vertical, AppMetrics.spacingSmall)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        OrderTrackingView(
            order: Order(
                user: User(id: "test-user-id", email: "test@u.northwestern.edu", firstName: "John", lastName: "Doe", phoneNumber: "123-456-7890", storeCredit: 0.0, verified: true, fcmToken: nil),
                items: [
                    CartItem(
                        product: Product(
                            inventoryName: "coffee",
                            displayName: "Coffee",
                            price: 3.99,
                            quantity: 10,
                            category: .drinks
                        ),
                        quantity: 2,
                        userId: UUID()
                    )
                ],
                status: .inQueue,
                rawAmount: 15.99,
                tip: 2.00,
                totalAmount: 17.99,
                deliveryAddress: "123 Main St",
                estimatedDeliveryTime: Date().addingTimeInterval(1800) // 30 minutes from now
            )
        )
    }
}
