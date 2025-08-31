//
//  MainTabView.swift
//  Zip
//

import SwiftUI
import Inject

struct MainTabView: View {
    @ObserveInjection var inject
    @ObservedObject var cartViewModel: CartViewModel
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var shoppingViewModel: ShoppingViewModel
    @StateObject private var orderStatusViewModel = OrderStatusViewModel()

    
    init(cartViewModel: CartViewModel, authViewModel: AuthViewModel, shoppingViewModel: ShoppingViewModel) {
        self.cartViewModel = cartViewModel
        self.authViewModel = authViewModel
        self.shoppingViewModel = shoppingViewModel
    }
    
    var body: some View {
        TabView {
            CategoryListView(cartViewModel: cartViewModel, shoppingViewModel: shoppingViewModel)
                .tabItem { 
                    Image(systemName: "bag")
                }
            
            CartView(cartViewModel: cartViewModel, authViewModel: authViewModel)
                .tabItem { 
                    Image(systemName: "cart")
                }
                .badge(cartViewModel.items.isEmpty ? 0 : cartViewModel.items.reduce(0) { $0 + $1.quantity })
                .onAppear {
                    print("🛒 MainTabView: Cart tab appeared with \(cartViewModel.items.count) items")
                }
            
            ProfileView(authViewModel: authViewModel)
                .tabItem { 
                    Image(systemName: "person")
                }
        }
        .tint(AppColors.accent)
        .enableInjection()
        .onAppear {
            // Load active order if user is authenticated
            if let currentUser = authViewModel.currentUser {
                Task {
                    await orderStatusViewModel.loadActiveOrder(userId: currentUser.id)
                }
            } else {
                // For development/testing, load mock data
                #if DEBUG
                orderStatusViewModel.loadMockActiveOrder()
                #endif
            }
        }
        .onChange(of: authViewModel.currentUser) { _, newUser in
            // Reload active order when user changes
            if let user = newUser {
                Task {
                    await orderStatusViewModel.loadActiveOrder(userId: user.id)
                }
            } else {
                // Clear active order when user logs out
                orderStatusViewModel.dismissBanner()
            }
        }

        .overlay(
            // Banner notification overlay
            VStack {
                // Order status banner at the top
                OrderStatusBannerContainer(
                    activeOrder: orderStatusViewModel.activeOrder,
                    onBannerTap: {
                        orderStatusViewModel.handleBannerTap()
                    },
                    onBannerDismiss: {
                        orderStatusViewModel.dismissBanner()
                    }
                )
                
                Spacer()
                
                // Cart notification banner at the bottom
                if cartViewModel.showBanner {
                    BannerNotificationView(
                        message: cartViewModel.bannerMessage,
                        type: cartViewModel.bannerType,
                        onDismiss: {
                            cartViewModel.hideBanner()
                        },
                        isExiting: cartViewModel.isExiting
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.8)),
                        removal: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.8)).combined(with: .offset(y: 50))
                    ))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: cartViewModel.showBanner)
                }
            }
        )
    }
}


