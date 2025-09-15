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
    @State private var hasAttemptedAutoLogin = false
    
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
                        
                        // Set up email verification success callback
                        authViewModel.onEmailVerificationSuccess = {
                            print("🔄 Email verification callback triggered - refreshing products...")
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
                    .onAppear {
                        // Attempt auto-login only once when the login view appears
                        if !hasAttemptedAutoLogin {
                            hasAttemptedAutoLogin = true
                            Task {
                                await authViewModel.attemptAutoLogin()
                            }
                        }
                    }
            }
        }
    }
}

#Preview {
    ContentView()
}
