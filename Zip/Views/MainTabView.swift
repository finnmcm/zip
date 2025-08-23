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
                    Text("Shop")
                }
            
            CartView(cartViewModel: cartViewModel)
                .tabItem { 
                    Image(systemName: "cart")
                    Text("Cart")
                }
                .badge(cartViewModel.items.isEmpty ? 0 : cartViewModel.items.reduce(0) { $0 + $1.quantity })
                .onAppear {
                    print("🛒 MainTabView: Cart tab appeared with \(cartViewModel.items.count) items")
                }
            
            ProfileView(authViewModel: authViewModel)
                .tabItem { 
                    Image(systemName: "person")
                    Text("Profile")
                }
        }
        .tint(AppColors.accent)
        .enableInjection()
    }
}


