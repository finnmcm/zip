//
//  CartView.swift
//  Zip
//

import SwiftUI
import Inject

struct CartView: View {
    @ObserveInjection var inject
    @ObservedObject var cartViewModel: CartViewModel
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var orderStatusViewModel: OrderStatusViewModel

    @State private var checkoutViewModel: CheckoutViewModel?
    @State private var showConfirmation: Bool = false
    @State private var showCheckout: Bool = false

    init(cartViewModel: CartViewModel, authViewModel: AuthViewModel, orderStatusViewModel: OrderStatusViewModel) {
        self.cartViewModel = cartViewModel
        self.authViewModel = authViewModel
        self.orderStatusViewModel = orderStatusViewModel
    }
    
    // MARK: - Computed Properties
    
    private var buttonText: String {
        if StoreHoursManager.shared.isStoreOpen {
            return "Proceed to Checkout"
        } else if StoreHoursManager.shared.isCurrentUserAdmin {
            return "Proceed to Checkout (Admin)"
        } else {
            return "Store Closed"
        }
    }
    
    private var buttonColor: Color {
        if StoreHoursManager.shared.canPlaceOrders {
            return AppColors.accent
        } else {
            return Color.gray
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                if cartViewModel.items.isEmpty {
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
                    .onAppear {
                        print("🛒 CartView: Empty cart state displayed")
                    }
                } else {
                    VStack(spacing: 0) {
                        // Store closed banner
                        StoreClosedBanner(currentUser: authViewModel.currentUser)
                        
                        // Cart Items
                        List {
                            ForEach(cartViewModel.items, id: \.id) { item in
                                CartItemRow(
                                    item: item,
                                    increment: { cartViewModel.increment(item: item) },
                                    decrement: { cartViewModel.decrement(item: item) },
                                    remove: { cartViewModel.remove(item: item) }
                                )
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .padding(.vertical, 4)
                            }
                        }
                        .listStyle(.plain)
                        .background(AppColors.background)
                        .onAppear {
                            print("🛒 CartView: Cart items list displayed with \(cartViewModel.items.count) items")
                        }

                        // Checkout Section
                        VStack(spacing: AppMetrics.spacing) {
                            Divider()
                            
                            VStack(spacing: AppMetrics.spacingSmall) {
                                HStack {
                                    Text("Subtotal")
                                        .font(.body)
                                    Spacer()
                                    Text("$\(NSDecimalNumber(decimal: cartViewModel.subtotal).doubleValue, specifier: "%.2f")")
                                        .font(.body)
                                }
                                
                                HStack {
                                    Text("Delivery Fee")
                                        .font(.body)
                                    Spacer()
                                    Text("$0.00")
                                        .font(.body)
                                }
                                
                                Divider()
                                
                                HStack {
                                    Text("Total")
                                        .font(.title3.bold())
                                    Spacer()
                                    Text("$\(NSDecimalNumber(decimal: cartViewModel.subtotal).doubleValue, specifier: "%.2f")")
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
                                    Text(buttonText)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(buttonColor)
                                .foregroundColor(.white)
                                .cornerRadius(AppMetrics.cornerRadiusLarge)
                            }
                            .buttonStyle(.plain)
                            .disabled(!StoreHoursManager.shared.canPlaceOrders)
                            .padding(.horizontal, AppMetrics.spacingLarge)
                            .padding(.bottom, AppMetrics.spacingLarge)
                        }
                        .background(AppColors.secondaryBackground)
                    }
                }
            }
            .navigationTitle("Cart")
            .onAppear {
                print("🛒 CartView: View appeared with \(cartViewModel.items.count) items")
                // Update StoreHoursManager with current user for admin checks
                StoreHoursManager.shared.setCurrentUser(authViewModel.currentUser)
            }
            .onChange(of: cartViewModel.items.count) { oldCount, newCount in
                print("🛒 CartView: Items count changed from \(oldCount) to \(newCount)")
            }
            .sheet(isPresented: $showCheckout) {
                CheckoutView(viewModel: CheckoutViewModel(cart: cartViewModel, authViewModel: authViewModel, orderStatusViewModel: orderStatusViewModel))
            }
            .sheet(isPresented: $showConfirmation) {
                OrderConfirmationView(order: checkoutViewModel?.lastOrder)
            }
        }
        .enableInjection()
    }
}


