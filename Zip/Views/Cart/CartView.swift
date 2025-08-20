//
//  CartView.swift
//  Zip
//

import SwiftUI
import SwiftData
import Inject

struct CartView: View {
    @ObserveInjection var inject
    @Environment(\.modelContext) private var context
    @State private var viewModel: CartViewModel?
    @State private var checkoutViewModel: CheckoutViewModel?
    @State private var showConfirmation: Bool = false
    @State private var showCheckout: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                if (viewModel?.items.isEmpty ?? true) {
                    VStack(spacing: AppMetrics.spacingLarge) {
                        Image(systemName: "cart")
                            .font(.system(size: 64))
                            .foregroundStyle(AppColors.textSecondary)
                        
                        Text("Your cart is empty")
                            .font(.title2.bold())
                            .foregroundStyle(AppColors.textSecondary)
                        
                        Text("Add some products from the shop to get started")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.textSecondary.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppMetrics.spacingLarge)
                    }
                    .padding(.top, 64)
                } else {
                    VStack(spacing: 0) {
                        // Cart Items
                        List {
                            ForEach(viewModel?.items ?? [], id: \.id) { item in
                                CartItemRow(
                                    item: item,
                                    increment: { viewModel?.increment(item: item) },
                                    decrement: { viewModel?.decrement(item: item) },
                                    remove: { viewModel?.remove(item: item) }
                                )
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .padding(.vertical, 4)
                            }
                        }
                        .listStyle(.plain)
                        .background(AppColors.background)

                        // Checkout Section
                        VStack(spacing: AppMetrics.spacing) {
                            Divider()
                            
                            VStack(spacing: AppMetrics.spacingSmall) {
                                HStack {
                                    Text("Subtotal")
                                        .font(.body)
                                    Spacer()
                                    Text("$\(NSDecimalNumber(decimal: viewModel?.subtotal ?? 0).doubleValue, specifier: "%.2f")")
                                        .font(.body)
                                }
                                
                                HStack {
                                    Text("Delivery Fee")
                                        .font(.body)
                                    Spacer()
                                    Text("$0.99")
                                        .font(.body)
                                }
                                
                                Divider()
                                
                                HStack {
                                    Text("Total")
                                        .font(.title3.bold())
                                    Spacer()
                                    Text("$\(NSDecimalNumber(decimal: (viewModel?.subtotal ?? 0) + Decimal(0.99)).doubleValue, specifier: "%.2f")")
                                        .font(.title3.bold())
                                        .foregroundStyle(AppColors.accent)
                                }
                            }
                            .padding(.horizontal, AppMetrics.spacingLarge)
                            
                            Button(action: {
                                showCheckout = true
                            }) {
                                HStack {
                                    Image(systemName: "creditcard")
                                    Text("Proceed to Checkout")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppColors.accent)
                                .foregroundColor(.white)
                                .cornerRadius(AppMetrics.cornerRadiusLarge)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, AppMetrics.spacingLarge)
                            .padding(.bottom, AppMetrics.spacingLarge)
                        }
                        .background(AppColors.secondaryBackground)
                    }
                }
            }
            .navigationTitle("Cart")
            .sheet(isPresented: $showCheckout) {
                if let viewModel = viewModel {
                    CheckoutView(viewModel: CheckoutViewModel(context: context, cart: viewModel))
                }
            }
            .sheet(isPresented: $showConfirmation) {
                OrderConfirmationView(order: checkoutViewModel?.lastOrder)
            }
        }
        .onAppear {
            if viewModel == nil { 
                viewModel = CartViewModel(context: context) 
            }
        }
        .enableInjection()
    }
}


