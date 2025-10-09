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
                    .task {
                        // Load products immediately when authenticated view appears
                        print("📱 ContentView: .task triggered, loading products...")
                        await shoppingViewModel.loadProducts()
                        print("📱 ContentView: .task completed")
                    }
                    .onAppear {
                        print("📱 ContentView: MainTabView appeared, isAuthenticated: \(authViewModel.isAuthenticated)")
                        
                        // Set up authentication success callback for subsequent logins
                        authViewModel.onAuthenticationSuccess = {
                            print("📱 ContentView: onAuthenticationSuccess callback triggered")
                            Task {
                                await shoppingViewModel.loadProducts()
                            }
                        }
                        
                        // Set up email verification success callback
                        authViewModel.onEmailVerificationSuccess = {
                            print("🔄 ContentView: Email verification callback triggered - refreshing products...")
                            Task {
                                await shoppingViewModel.loadProducts()
                            }
                        }
                    }
                    .onChange(of: authViewModel.isAuthenticated) { oldValue, newValue in
                        print("📱 ContentView: isAuthenticated changed from \(oldValue) to \(newValue)")
                        if newValue {
                            print("📱 ContentView: User became authenticated, loading products...")
                            Task {
                                await shoppingViewModel.loadProducts()
                            }
                        }
                    }
            } else if authViewModel.isPendingEmailVerification,
                      let email = authViewModel.pendingVerificationEmail,
                      let password = authViewModel.pendingVerificationPassword {
                // Show email verification pending view
                EmailVerificationPendingView(email: email, password: password)
                    .environmentObject(authViewModel)
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
