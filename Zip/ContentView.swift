//
//  ContentView.swift
//  Zip
//
//  Created by Finn McMillan on 8/19/25.
//

import SwiftUI
import Inject

struct ContentView: View {
    @ObserveInjection var inject
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var cartViewModel = CartViewModel()
        @StateObject private var shoppingViewModel = ShoppingViewModel()
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView(cartViewModel: cartViewModel, authViewModel: authViewModel, shoppingViewModel: shoppingViewModel)
                    .environmentObject(authViewModel)
                    .onAppear {
                        // Set up authentication success callback
                        authViewModel.onAuthenticationSuccess = {
                            Task {
                                await shoppingViewModel.loadProducts()
                            }
                        }
                        
                        // If already authenticated, load products
                        if authViewModel.isAuthenticated {
                            Task {
                                await shoppingViewModel.loadProducts()
                            }
                        }
                    }
            } else {
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
    }
}

#Preview {
    ContentView()
}
