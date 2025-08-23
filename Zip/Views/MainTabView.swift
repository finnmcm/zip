//
//  MainTabView.swift
//  Zip
//

import SwiftUI
import Inject

struct MainTabView: View {
    @ObserveInjection var inject
    @ObservedObject var cartViewModel: CartViewModel
    
    init(cartViewModel: CartViewModel) {
        self.cartViewModel = cartViewModel
    }
    
    var body: some View {
        TabView {
            CategoryListView(cartViewModel: cartViewModel)
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
            
            ProfileView()
                .tabItem { 
                    Image(systemName: "person")
                    Text("Profile")
                }
        }
        .tint(AppColors.accent)
        .enableInjection()
    }
}


