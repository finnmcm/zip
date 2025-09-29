//
//  OrderHistoryView.swift
//  Zip
//
//  Created by AI Assistant on 2024
//

import SwiftUI

struct OrderHistoryView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var isLoading = false
    @State private var selectedOrder: Order?
    @State private var showingOrderDetail = false
    @State private var errorMessage: String?
    @State private var refreshTask: Task<Void, Never>?
    @State private var lastRefreshTime: Date = .distantPast
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                if isLoading {
                    loadingView
                } else {
                    orderListView
                }
            }
            .navigationTitle("Order History")
            .navigationBarTitleDisplayMode(.large)

            .sheet(isPresented: $showingOrderDetail) {
                if let order = selectedOrder {
                    OrderDetailView(order: order)
                }
            }
            .onAppear {
                loadOrders()
            }
            .onDisappear {
                // Cancel any pending refresh tasks when view disappears
                refreshTask?.cancel()
            }
            .refreshable {
                await performRefresh()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var userOrders: [Order] {
        authViewModel.currentUser?.orders ?? []
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: AppMetrics.spacingLarge) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accent))
            
            Text("Loading Orders...")
                .font(.body)
                .foregroundColor(AppColors.textSecondary)
        }
    }
    
    // MARK: - Error View
    
    private var errorView: some View {
        VStack(spacing: AppMetrics.spacingLarge) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(AppColors.textSecondary)
            
            Text("Error Loading Orders")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
            
            Text(errorMessage ?? "An unknown error occurred")
                .font(.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppMetrics.spacingLarge)
            
            Button("Try Again") {
                Task {
                    await performRefresh()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.accent)
        }
        .padding()
    }
    
    // MARK: - Empty State View
    
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

        }
        .padding()
    }
    
    // MARK: - Order List View
    
    private var orderListView: some View {
        List {
            ForEach(userOrders) { order in
                OrderHistoryRow(order: order) {
                    selectedOrder = order
                    showingOrderDetail = true
                }
            }
        }
        .listStyle(.plain)
    }
    
    // MARK: - Data Loading Methods
    
    private func loadOrders() {
        // If we already have orders from the user, no need to load
        if !userOrders.isEmpty {
            return
        }
        
        // If no user is authenticated, show empty state
        guard authViewModel.currentUser != nil else {
            return
        }
        
        // Load orders if we don't have them yet
        Task {
            await performRefresh()
        }
    }
    
    private func performRefresh() async {
        // Cancel any existing refresh task
        refreshTask?.cancel()
        
        // Check if we're refreshing too frequently (debounce)
        let timeSinceLastRefresh = Date().timeIntervalSince(lastRefreshTime)
        if timeSinceLastRefresh < 2.0 { // 2 second minimum between refreshes
            return
        }
        
        // Create a new refresh task
        refreshTask = Task {
            await refreshOrders()
        }
        
        // Wait for the task to complete
        await refreshTask?.value
    }
    
    private func refreshOrders() async {
        guard let currentUser = authViewModel.currentUser else {
            await MainActor.run {
                errorMessage = "Please sign in to view your order history"
            }
            return
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let supabaseService = SupabaseService()
            
            if supabaseService.isClientConfigured {
                // Fetch fresh orders from Supabase
                let orders = try await supabaseService.fetchUserOrders(userId: currentUser.id)
                
                // Check if the task was cancelled
                if Task.isCancelled {
                    return
                }
                
                await MainActor.run {
                    // Update the user's orders in AuthViewModel
                    authViewModel.updateUserOrders(orders)
                    isLoading = false
                    lastRefreshTime = Date()
                }
            } else {
                // Supabase not configured, show error
                await MainActor.run {
                    errorMessage = "Order service is not available. Please try again later."
                    isLoading = false
                }
            }
        } catch {
            // Check if the task was cancelled
            if Task.isCancelled {
                await MainActor.run {
                    isLoading = false
                }
                return
            }
            
            await MainActor.run {
                if let urlError = error as? URLError, urlError.code == .cancelled {
                    // Request was cancelled, don't show error
                    isLoading = false
                } else {
                    errorMessage = "Failed to load orders: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
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
    @State private var deliveryImageURL: String?
    @State private var isLoadingDeliveryImage = false
    
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
                    
                    // Delivery Image (if available)
                    if order.status == .delivered {
                        deliveryImageSection
                    }
                    
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
            .onAppear {
                loadDeliveryImage()
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
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("$\(NSDecimalNumber(decimal: item.product.price).doubleValue, specifier: "%.2f")")
                                .font(.body)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("Qty: \(item.quantity)")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
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
    
    private var deliveryImageSection: some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacing) {
            Text("Delivery Photo")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: AppMetrics.spacingSmall) {
                if isLoadingDeliveryImage {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading delivery photo...")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppMetrics.spacingLarge)
                } else if let imageURL = deliveryImageURL {
                    AsyncImage(url: URL(string: imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                            .cornerRadius(AppMetrics.cornerRadiusLarge)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: AppMetrics.cornerRadiusLarge)
                            .fill(AppColors.secondaryBackground)
                            .frame(height: 200)
                            .overlay(
                                VStack(spacing: AppMetrics.spacingSmall) {
                                    ProgressView()
                                        .scaleEffect(1.2)
                                    Text("Loading image...")
                                        .font(.caption)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            )
                    }
                } else {
                    VStack(spacing: AppMetrics.spacingSmall) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 40))
                            .foregroundColor(AppColors.textSecondary)
                        
                        Text("No delivery photo available")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppMetrics.spacingLarge)
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
                    Text("$\(NSDecimalNumber(decimal: order.rawAmount).doubleValue, specifier: "%.2f")")
                        .foregroundColor(AppColors.textPrimary)
                }
                
                HStack {
                    Text("Tip")
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text("$\(NSDecimalNumber(decimal: order.tip).doubleValue, specifier: "%.2f")")
                        .foregroundColor(AppColors.textPrimary)
                }
                
                Divider()
                
                HStack {
                    Text("Total")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    Text("$\(NSDecimalNumber(decimal: order.totalAmount).doubleValue, specifier: "%.2f")")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.accent)
                }
            }
            .padding()
            .background(AppColors.secondaryBackground)
            .cornerRadius(AppMetrics.cornerRadiusLarge)
        }
    }
    
    // MARK: - Data Loading Methods
    
    private func loadDeliveryImage() {
        // Only load if we don't already have the image URL
        guard deliveryImageURL == nil && !isLoadingDeliveryImage else {
            print("🔍 Skipping delivery image load - already loaded or loading")
            return
        }
        
        // Check if order already has the image URL
        if let existingURL = order.deliveryImageURL {
            print("🔍 Using existing delivery image URL: \(existingURL)")
            deliveryImageURL = existingURL
            return
        }
        
        print("🔍 Loading delivery image for order: \(order.id)")
        isLoadingDeliveryImage = true
        
        Task {
            do {
                let supabaseService = SupabaseService()
                let imageURL = try await supabaseService.fetchDeliveryImageURL(for: order.id)
                
                await MainActor.run {
                    print("🔍 Delivery image URL result: \(imageURL ?? "nil")")
                    deliveryImageURL = imageURL
                    isLoadingDeliveryImage = false
                }
            } catch {
                await MainActor.run {
                    print("⚠️ Failed to load delivery image: \(error)")
                    isLoadingDeliveryImage = false
                }
            }
        }
    }
}

#Preview {
    OrderHistoryView(authViewModel: AuthViewModel())
}
