//
//  CheckoutView.swift
//  Zip
//

import SwiftUI
import Inject

struct CheckoutView: View {
    @ObserveInjection var inject
    @ObservedObject var viewModel: CheckoutViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showConfirmation: Bool = false
    @State private var tipAmount: Decimal = 0.0
    @State private var onCampus: Bool = true
    @State var selectedBuilding: String = ""
    @State var selectedAddress: String = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
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
                                Text("$0.99")
                                    .font(.body)
                            }
                            HStack {
                                Text("Tip")
                                    .font(.body)
                                Spacer()
                                Text("$\(NSDecimalNumber(decimal: tipAmount).doubleValue, specifier: "%.2f")")
                                    .font(.body)
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Total")
                                    .font(.title3.bold())
                                Spacer()
                                Text("$\(NSDecimalNumber(decimal: viewModel.cart.subtotal + Decimal(0.99) + tipAmount).doubleValue, specifier: "%.2f")")
                                    .font(.title3.bold())
                                    .foregroundStyle(AppColors.accent)
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
            Button(action: { tipAmount = 3.00; viewModel.tipAmount = 3.00 }) {
                Text("$3.00")
                    .font(.headline)
                    .foregroundStyle(tipAmount != 3.00 ? AppColors.textSecondary : AppColors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppMetrics.spacing)
                    .background(tipAmount != 3.00 ? AppColors.secondaryBackground : AppColors.accent.opacity(0.1))
            }
            .buttonStyle(.plain)
            
            Button(action: { tipAmount = 2.00; viewModel.tipAmount = 2.00 }) {
                Text("$2.00")
                    .font(.headline)
                    .font(.headline)
                    .foregroundStyle(tipAmount != 2.00 ? AppColors.textSecondary : AppColors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppMetrics.spacing)
                    .background(tipAmount != 2.00 ? AppColors.secondaryBackground : AppColors.accent.opacity(0.1))
            }
            .buttonStyle(.plain)
            Button(action: { tipAmount = 1.00; viewModel.tipAmount = 1.00 }) {
                Text("$1.00")
                    .font(.headline)
                    .font(.headline)
                    .foregroundStyle(tipAmount != 1.00 ? AppColors.textSecondary : AppColors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppMetrics.spacing)
                    .background(tipAmount != 1.00 ? AppColors.secondaryBackground : AppColors.accent.opacity(0.1))
            }
            .buttonStyle(.plain)
            Button(action: { tipAmount = 0.00; viewModel.tipAmount = 0.00 }) {
                Text("No Tip")
                    .font(.headline)
                    .font(.headline)
                    .foregroundStyle(tipAmount != 0.00 ? AppColors.textSecondary : AppColors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppMetrics.spacing)
                    .background(tipAmount != 0.00 ? AppColors.secondaryBackground : AppColors.accent.opacity(0.1))
            }
            .buttonStyle(.plain)
        }
        .background(AppColors.secondaryBackground)
        .cornerRadius(AppMetrics.cornerRadiusLarge)
        .padding(.horizontal, AppMetrics.spacingLarge)

                    // Delivery Info
                    VStack(alignment: .leading, spacing: AppMetrics.spacing) {
                        HStack {
                            Text("Delivery Information")
                                .font(.title2.bold())
                                .padding(.horizontal, AppMetrics.spacingLarge)
                                Spacer()
                        }
                        HStack{
                            Button(action: { onCampus = true }) {
                                Text("On Campus")
                                    .font(.headline)
                                    .foregroundStyle( !onCampus ? AppColors.textSecondary : AppColors.accent)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, AppMetrics.spacing)
                                    .background( !onCampus ? AppColors.secondaryBackground : AppColors.accent.opacity(0.1))
                                }
                                .buttonStyle(.plain)
            
                            Button(action: { onCampus = false }) {
                                Text("Off Campus")
                                    .font(.headline)
                                    .font(.headline)
                                    .foregroundStyle(onCampus ? AppColors.textSecondary : AppColors.accent)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, AppMetrics.spacing)
                                    .background(onCampus ? AppColors.secondaryBackground : AppColors.accent.opacity(0.1))
                            }
                            .buttonStyle(.plain)
                         }
                         .background(AppColors.secondaryBackground)
                        .cornerRadius(AppMetrics.cornerRadiusLarge)
                        .padding(.horizontal, AppMetrics.spacingLarge)

                        if onCampus {
                            BuildingSearchView(selectedBuilding: $selectedBuilding)
                        }
                        else{
                            AddressSelectionView(selectedAddress: $selectedAddress)
                        }
                    }
                    
                    // Payment Button
                    VStack(spacing: AppMetrics.spacing) {
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AppMetrics.spacingLarge)
                        }
                        
                        Button(action: {
                            Task {
                                await viewModel.confirmPayment()
                                if viewModel.lastOrder != nil {
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
                            .background(AppColors.accent)
                            .foregroundColor(.white)
                            .cornerRadius(AppMetrics.cornerRadiusLarge)
                        }
                        .disabled(viewModel.isProcessing)
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
            .sheet(isPresented: $showConfirmation) {
                OrderConfirmationView(order: viewModel.lastOrder)
                    .onDisappear {
                        dismiss()
                    }
            }
            }
        }
        .enableInjection()
    }
}
