//
//  CheckoutView.swift
//  Zip
//

import SwiftUI
import Inject
import PassKit

struct CheckoutView: View {
    @ObserveInjection var inject
    @ObservedObject var viewModel: CheckoutViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showConfirmation: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppMetrics.spacingLarge) {
                        // Order Summary
                        VStack(alignment: .leading, spacing: AppMetrics.spacing) {
                           Text("Order Summary")
                                .font(.title2.bold()) 
                                .padding(.horizontal, AppMetrics.spacingLarge)
                            
                            VStack(spacing: AppMetrics.spacing) {
                                ForEach(viewModel.cart.items, id: \.id) { item in
                                    HStack {
                                        Text(item.product.displayName)
                                            .font(.body)
                                        Spacer()
                                        Text("\(item.quantity) × $\(NSDecimalNumber(decimal: item.product.price).doubleValue, specifier: "%.2f")")
                                            .font(.body)
                                            .foregroundStyle(AppColors.textSecondary)
                                    }
                                }
                                
                                Divider()
                                
                                HStack {
                                    Text("Subtotal")
                                        .font(.body)
                                    Spacer()
                                    Text("$\(NSDecimalNumber(decimal: viewModel.cart.subtotal).doubleValue, specifier: "%.2f")")
                                        .font(.body)
                                }
                                
                                HStack {
                                    Text("Delivery Fee")
                                        .font(.body)
                                    Spacer()
                                    Text("0.00")
                                        .font(.body)
                                }
                                HStack {
                                    Text("Tip")
                                        .font(.body)
                                    Spacer()
                                    Text("$\(NSDecimalNumber(decimal: viewModel.tipAmount).doubleValue, specifier: "%.2f")")
                                        .font(.body)
                                }
                                
                                Divider()
                                
                                HStack {
                                    Text("Total")
                                        .font(.title3.bold())
                                    Spacer()
                                    Text("$\(NSDecimalNumber(decimal: viewModel.finalAmount).doubleValue, specifier: "%.2f")")
                                        .font(.title3.bold())
                                        .foregroundStyle(AppColors.accent)
                                }
                                
                                if viewModel.appliedStoreCredit > 0 {
                                    HStack {
                                        Text("After Store Credit")
                                            .font(.caption)
                                            .foregroundStyle(AppColors.textSecondary)
                                        Spacer()
                                        Text("$\(NSDecimalNumber(decimal: viewModel.finalAmount).doubleValue, specifier: "%.2f")")
                                            .font(.caption)
                                            .foregroundStyle(AppColors.accent)
                                    }
                                }
                            }
                            .padding()
                            .background(AppColors.secondaryBackground)
                            .cornerRadius(AppMetrics.cornerRadiusLarge)
                            .padding(.horizontal, AppMetrics.spacingLarge)
                            
                        }
                        HStack {
                        Text("Tip your Zipper:")
                                .font(.title2.bold()) 
                                .padding(.horizontal, AppMetrics.spacingLarge)
                                Spacer()
                        }
                        HStack(spacing: 0) {
                Button(action: { viewModel.tipAmount = 3.00 }) {
                    Text("$3.00")
                        .font(.headline)
                        .foregroundStyle(viewModel.tipAmount != 3.00 ? AppColors.textSecondary : AppColors.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppMetrics.spacing)
                        .background(viewModel.tipAmount != 3.00 ? AppColors.secondaryBackground : AppColors.accent.opacity(0.1))
                }
                .buttonStyle(.plain)
                
                Button(action: { viewModel.tipAmount = 2.00 }) {
                    Text("$2.00")
                        .font(.headline)
                        .foregroundStyle(viewModel.tipAmount != 2.00 ? AppColors.textSecondary : AppColors.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppMetrics.spacing)
                        .background(viewModel.tipAmount != 2.00 ? AppColors.secondaryBackground : AppColors.accent.opacity(0.1))
                }
                .buttonStyle(.plain)
                Button(action: { viewModel.tipAmount = 1.00 }) {
                    Text("$1.00")
                        .font(.headline)
                        .foregroundStyle(viewModel.tipAmount != 1.00 ? AppColors.textSecondary : AppColors.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppMetrics.spacing)
                        .background(viewModel.tipAmount != 1.00 ? AppColors.secondaryBackground : AppColors.accent.opacity(0.1))
                }
                .buttonStyle(.plain)
                Button(action: { viewModel.tipAmount = 0.00 }) {
                    Text("No Tip")
                        .font(.headline)
                        .foregroundStyle(viewModel.tipAmount != 0.00 ? AppColors.textSecondary : AppColors.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppMetrics.spacing)
                        .background(viewModel.tipAmount != 0.00 ? AppColors.secondaryBackground : AppColors.accent.opacity(0.1))
                }
                .buttonStyle(.plain)
            }
            .background(AppColors.secondaryBackground)
            .cornerRadius(AppMetrics.cornerRadiusLarge)
            .padding(.horizontal, AppMetrics.spacingLarge)

                        // Store Credit Section
                        if let currentUser = viewModel.authViewModel.currentUser, currentUser.storeCredit > 0 {
                            VStack(alignment: .leading, spacing: AppMetrics.spacing) {
                                HStack {
                                    Text("Store Credit")
                                        .font(.title2.bold())
                                        .padding(.horizontal, AppMetrics.spacingLarge)
                                    Spacer()
                                }
                                
                                VStack(spacing: AppMetrics.spacing) {
                                    HStack {
                                        Text("Available: $\(String(format: "%.2f", NSDecimalNumber(decimal: currentUser.storeCredit).doubleValue))")
                                            .font(.subheadline)
                                            .foregroundStyle(AppColors.textSecondary)
                                        Spacer()
                                    }
                                    
                                    if viewModel.appliedStoreCredit > 0 {
                                        HStack {
                                            Text("Applied: -$\(String(format: "%.2f", NSDecimalNumber(decimal: viewModel.appliedStoreCredit).doubleValue))")
                                                .font(.subheadline)
                                                .foregroundStyle(AppColors.accent)
                                            Spacer()
                                            Button("Remove") {
                                                viewModel.removeStoreCredit()
                                            }
                                            .font(.caption)
                                            .foregroundStyle(AppColors.accent)
                                        }
                                    }
                                    
                                    HStack {
                                        Button("Apply $\(String(format: "%.2f", NSDecimalNumber(decimal: viewModel.maxStoreCreditApplicable).doubleValue))") {
                                            viewModel.applyStoreCredit(viewModel.maxStoreCreditApplicable)
                                        }
                                        .font(.caption)
                                        .padding(.horizontal, AppMetrics.spacing)
                                        .padding(.vertical, AppMetrics.spacingSmall)
                                        .background(AppColors.accent)
                                        .foregroundStyle(.white)
                                        .cornerRadius(AppMetrics.cornerRadiusSmall)
                                        .disabled(viewModel.appliedStoreCredit > 0)
                                        
                                        Spacer()
                                    }
                                }
                                .padding()
                                .background(AppColors.secondaryBackground)
                                .cornerRadius(AppMetrics.cornerRadiusLarge)
                                .padding(.horizontal, AppMetrics.spacingLarge)
                            }
                        }

                        // Delivery Info
                        VStack(alignment: .leading, spacing: AppMetrics.spacing) {
                            HStack {
                                Text("Delivery Information")
                                    .font(.title2.bold())
                                    .padding(.horizontal, AppMetrics.spacingLarge)
                                    Spacer()
                            }
                            HStack{
                                Button(action: { viewModel.isCampusDelivery = true }) {
                                    Text("On Campus")
                                        .font(.headline)
                                        .foregroundStyle( !viewModel.isCampusDelivery ? AppColors.textSecondary : AppColors.accent)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, AppMetrics.spacing)
                                        .background( !viewModel.isCampusDelivery ? AppColors.secondaryBackground : AppColors.accent.opacity(0.1))
                                    }
                                    .buttonStyle(.plain)
                
                                Button(action: { viewModel.isCampusDelivery = false }) {
                                    Text("Off Campus")
                                        .font(.headline)
                                        .foregroundStyle(viewModel.isCampusDelivery ? AppColors.textSecondary : AppColors.accent)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, AppMetrics.spacing)
                                        .background(viewModel.isCampusDelivery ? AppColors.secondaryBackground : AppColors.accent.opacity(0.1))
                                }
                                .buttonStyle(.plain)
                             }
                             .background(AppColors.secondaryBackground)
                            .cornerRadius(AppMetrics.cornerRadiusLarge)
                            .padding(.horizontal, AppMetrics.spacingLarge)

                            if viewModel.isCampusDelivery {
                                BuildingSearchView(selectedBuilding: $viewModel.selectedBuilding, viewModel: viewModel)
                            }
                            else{
                                AddressSelectionView(selectedAddress: $viewModel.selectedAddress, checkoutViewModel: viewModel)
                            }
                        }
                        
                        // Payment Buttons
                        VStack(spacing: AppMetrics.spacing) {
                            if let errorMessage = viewModel.errorMessage {
                                Text(errorMessage)
                                    .font(.footnote)
                                    .foregroundStyle(.red)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, AppMetrics.spacingLarge)
                            }
                            
                            // Apple Pay Button
                            if viewModel.isApplePayAvailable {
                                ApplePayButton(action: {
                                    Task {
                                        await viewModel.confirmApplePayPayment()
                                        // Check for successful payment and order creation
                                        if viewModel.lastOrder != nil && viewModel.paymentError == nil {
                                            showConfirmation = true
                                        }
                                    }
                                })
                                .frame(height: 50)
                                .cornerRadius(AppMetrics.cornerRadiusLarge)
                                .disabled(viewModel.isProcessing || viewModel.isCampusDelivery == true && viewModel.selectedBuilding == "" || !viewModel.isCampusDelivery && viewModel.selectedAddress == "" || !(viewModel.authViewModel.currentUser?.verified ?? false))
                                .padding(.horizontal, AppMetrics.spacingLarge)
                            }
                            
                            // Regular Payment Button
                            Button(action: {
                                Task {
                                    await viewModel.confirmPayment()
                                    // Check for successful payment and order creation
                                    if viewModel.lastOrder != nil && viewModel.paymentError == nil {
                                        showConfirmation = true
                                    }
                                }
                            }) {
                                HStack {
                                    if viewModel.isProcessing {
                                        ProgressView()
                                            .tint(.white)
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "creditcard.fill")
                                    }
                                    Text(viewModel.isProcessing ? "Processing..." : "Confirm Order")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(viewModel.isCampusDelivery == true && viewModel.selectedBuilding == "" || !viewModel.isCampusDelivery && viewModel.selectedAddress == "" ? AppColors.textSecondary : AppColors.accent)
                                .foregroundColor(.white)
                                .cornerRadius(AppMetrics.cornerRadiusLarge)
                            }
                            .disabled(viewModel.isProcessing || viewModel.isCampusDelivery == true && viewModel.selectedBuilding == "" || !viewModel.isCampusDelivery && viewModel.selectedAddress == "" || !(viewModel.authViewModel.currentUser?.verified ?? false))
                            .buttonStyle(.plain)
                            .padding(.horizontal, AppMetrics.spacingLarge)
                            .padding(.bottom, AppMetrics.spacingLarge)
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
                
                // Error Banner Overlay
                if viewModel.showErrorBanner {
                    VStack {
                        Spacer()
                        
                        BannerNotificationView(
                            message: viewModel.paymentError ?? "Payment failed. Please try again.",
                            type: .error,
                            onDismiss: {
                                viewModel.dismissErrorBanner()
                            },
                            isExiting: false
                        )
                    }
                    .transition(.move(edge: .bottom))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.showErrorBanner)
                }
            }
        }
        .sheet(isPresented: $showConfirmation) {
            OrderConfirmationView(order: viewModel.lastOrder)
                .onDisappear {
                    dismiss()
                }
        }
        .enableInjection()
    }
}
