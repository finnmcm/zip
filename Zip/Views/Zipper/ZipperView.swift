import Foundation
import SwiftUI
import UIKit

struct ZipperView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: ZipperViewModel
    @State private var showingOrderDetail = false
    @State private var selectedOrder: Order?
    @State private var showCamera = false
    
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        self._viewModel = StateObject(wrappedValue: ZipperViewModel(authViewModel: authViewModel))
    }
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Hi, \(authViewModel.currentUser?.firstName ?? "")")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Refresh") {
                            Task {
                                await viewModel.refreshData()
                            }
                        }
                        .disabled(viewModel.isLoading)
                    }
                }
                .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                    Button("OK") {
                        viewModel.clearMessages()
                    }
                } message: {
                    Text(viewModel.errorMessage ?? "")
                }
                .alert("Success", isPresented: .constant(viewModel.successMessage != nil)) {
                    Button("OK") {
                        viewModel.clearMessages()
                    }
                } message: {
                    Text(viewModel.successMessage ?? "")
                }
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if viewModel.hasActiveOrder {
            // Show active order with unclosable sheet
            ActiveOrderView(
                order: viewModel.activeOrder!,
                onCompleteOrder: {
                    showCamera = true
                }
            )
            .interactiveDismissDisabled(true)
            .fullScreenCover(isPresented: $showCamera) {
                CameraPickerInlineView(
                    onImagePicked: { image in
                        showCamera = false
                        Task { await viewModel.completeOrder(with: image) }
                    },
                    onCancel: {
                        showCamera = false
                    }
                )
            }
        } else {
            // Show pending orders list
            PendingOrdersView(
                orders: viewModel.pendingOrders,
                isLoading: viewModel.isLoading,
                onAcceptOrder: { order in
                    Task {
                        await viewModel.acceptOrder(order)
                    }
                },
                onRefresh: {
                    Task {
                        await viewModel.refreshData()
                    }
                }
            )
        }
    }
}

// MARK: - Active Order View
struct ActiveOrderView: View {
    let order: Order
    let onCompleteOrder: () -> Void
    
    var body: some View {
        VStack(spacing: AppMetrics.spacingLarge) {
            // Header
            VStack(spacing: AppMetrics.spacing) {
                Image(systemName: "bicycle")
                    .font(.system(size: 60))
                    .foregroundColor(AppColors.accent)
                
                Text("Active Delivery")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Complete this order to accept new ones")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, AppMetrics.spacingLarge)
            
            // Order Details Card
            VStack(alignment: .leading, spacing: AppMetrics.spacing) {
                // Customer Info
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(AppColors.accent)
                    VStack(alignment: .leading) {
                        Text("Customer")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Text(order.user.fullName)
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    Spacer()
                }
                
                Divider()
                
                // Delivery Address
                HStack(alignment: .top) {
                    Image(systemName: "location.circle.fill")
                        .foregroundColor(AppColors.accent)
                    VStack(alignment: .leading) {
                        Text("Delivery Address")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Text(order.deliveryAddress)
                            .font(.body)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    Spacer()
                }
                
                if let instructions = order.deliveryInstructions, !instructions.isEmpty {
                    Divider()
                    
                    HStack(alignment: .top) {
                        Image(systemName: "note.text")
                            .foregroundColor(AppColors.accent)
                        VStack(alignment: .leading) {
                            Text("Instructions")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                            Text(instructions)
                                .font(.body)
                                .foregroundColor(AppColors.textPrimary)
                        }
                        Spacer()
                    }
                }
                
                Divider()
                
                // Order Items
                VStack(alignment: .leading, spacing: AppMetrics.spacingSmall) {
                    Text("Order Items")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    ForEach(order.items) { item in
                        HStack {
                            Text("\(item.quantity)x \(item.product.displayName)")
                                .font(.body)
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            Text("$\(String(format: "%.2f", NSDecimalNumber(decimal: item.product.price * Decimal(item.quantity)).doubleValue))")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.textPrimary)
                        }
                    }
                }
                
                Divider()
                
                // Total
                HStack {
                    Text("Total")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    Text("$\(String(format: "%.2f", NSDecimalNumber(decimal: order.totalAmount).doubleValue))")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
            .padding(AppMetrics.spacing)
            .background(AppColors.secondaryBackground)
            .cornerRadius(AppMetrics.cornerRadius)
            
            Spacer()
            
            // Complete Order Button
            Button(action: onCompleteOrder) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Complete Order")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.accent)
                .cornerRadius(AppMetrics.cornerRadius)
            }
            .padding(.horizontal, AppMetrics.spacing)
            .padding(.bottom, AppMetrics.spacingLarge)
        }
        .padding(.horizontal, AppMetrics.spacing)
    }
}

// MARK: - Pending Orders View
struct PendingOrdersView: View {
    let orders: [Order]
    let isLoading: Bool
    let onAcceptOrder: (Order) -> Void
    let onRefresh: () -> Void
    
    var body: some View {
        VStack {
            if isLoading {
                Spacer()
                ProgressView("Loading orders...")
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
            } else if orders.isEmpty {
                Spacer()
                VStack(spacing: AppMetrics.spacing) {
                    Image(systemName: "clock")
                        .font(.system(size: 50))
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("No Pending Orders")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Check back later for new delivery requests")
                        .font(.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                Spacer()
            } else {
                List {
                    ForEach(orders) { order in
                        PendingOrderRow(
                            order: order,
                            onAccept: {
                                onAcceptOrder(order)
                            }
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(PlainListStyle())
                .refreshable {
                    onRefresh()
                }
            }
        }
    }
}

// MARK: - Pending Order Row
struct PendingOrderRow: View {
    let order: Order
    let onAccept: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacing) {
            // Header with time and total
            HStack {
                VStack(alignment: .leading) {
                    Text("Order #\(String(order.id.uuidString.prefix(8)))")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Text("\(order.createdAt, formatter: timeFormatter)")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Text("$\(String(format: "%.2f", NSDecimalNumber(decimal: order.totalAmount).doubleValue))")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.accent)
                }
            }
            
            // Customer and address
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "person.circle")
                        .foregroundColor(AppColors.textSecondary)
                    Text(order.user.fullName)
                        .font(.body)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                HStack {
                    Image(systemName: "location")
                        .foregroundColor(AppColors.textSecondary)
                    Text(order.deliveryAddress)
                        .font(.body)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(2)
                }
            }
            
            // Order items preview
            VStack(alignment: .leading, spacing: 2) {
                Text("Items:")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                ForEach(order.items.prefix(3)) { item in
                    Text("\(item.quantity)x \(item.product.displayName)")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                if order.items.count > 3 {
                    Text("+ \(order.items.count - 3) more items")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            // Accept button
            Button(action: onAccept) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Accept Order")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.accent)
                .cornerRadius(AppMetrics.cornerRadius)
            }
        }
        .padding(AppMetrics.spacing)
        .background(AppColors.secondaryBackground)
        .cornerRadius(AppMetrics.cornerRadius)
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - Inline Camera Picker
struct CameraPickerInlineView: UIViewControllerRepresentable {
    var onImagePicked: (UIImage) -> Void
    var onCancel: () -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPickerInlineView
        init(_ parent: CameraPickerInlineView) { self.parent = parent }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.onCancel() }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage { parent.onImagePicked(image) } else { parent.onCancel() }
        }
    }
}

#Preview {
    ZipperView(authViewModel: AuthViewModel())
}