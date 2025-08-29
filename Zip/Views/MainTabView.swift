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
            
            CartView(cartViewModel: cartViewModel)
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
        .overlay(
            // Banner notification overlay
            VStack {
                Spacer()
                
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


