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
    
    // MARK: - Helper Methods
    
    /// Refreshes user orders and updates the active order
    /// - Parameters:
    ///   - userId: The ID of the user to refresh orders for
    ///   - authViewModel: The AuthViewModel instance to update
    private func refreshUserOrders(userId: String, authViewModel: AuthViewModel?) async {
        print("🔄 MainTabView: Starting to refresh user orders for userId: \(userId)")
        
        do {
            // Fetch user orders and store them in the User's orders attribute
            let supabaseService = SupabaseService()
            print("🔗 MainTabView: Supabase client configured: \(supabaseService.isClientConfigured)")
            
            if supabaseService.isClientConfigured {
                print("📡 MainTabView: Fetching orders from Supabase...")
                let orders = try await supabaseService.fetchUserOrders(userId: userId)
                print("✅ MainTabView: Successfully fetched \(orders.count) orders from Supabase")
                
                await MainActor.run {
                    print("👤 MainTabView: Updating user orders in AuthViewModel...")
                    authViewModel?.updateUserOrders(orders)
                    print("✅ MainTabView: User orders updated in AuthViewModel")
                }
                
                // Load active order from the fetched orders
                await MainActor.run {
                    print("🎯 MainTabView: Loading active order from pre-fetched orders...")
                    orderStatusViewModel.loadActiveOrderFromOrders(orders)
                    print("✅ MainTabView: Active order loaded from pre-fetched orders")
                }
            } else {
                print("⚠️ MainTabView: Supabase not configured, falling back to original method")
                // Fall back to the original method if Supabase is not configured
                await orderStatusViewModel.loadActiveOrder(userId: userId)
                print("✅ MainTabView: Active order loaded from original method")
            }
        } catch {
            print("❌ MainTabView: Error fetching user orders: \(error)")
            // Fall back to the original method on error
            await orderStatusViewModel.loadActiveOrder(userId: userId)
            print("✅ MainTabView: Active order loaded from fallback method")
        }
    }
    
    var body: some View {
        TabView {
            CategoryListView(cartViewModel: cartViewModel, shoppingViewModel: shoppingViewModel)
                .tabItem { 
                    Image(systemName: "bag")
                }
            
            CartView(cartViewModel: cartViewModel, authViewModel: authViewModel, orderStatusViewModel: orderStatusViewModel)
                .tabItem { 
                    Image(systemName: "cart")
                }
                .badge(cartViewModel.items.isEmpty ? 0 : cartViewModel.items.reduce(0) { $0 + $1.quantity })
                .onAppear {
                    print("🛒 MainTabView: Cart tab appeared with \(cartViewModel.items.count) items")
                }
            OrderHistoryView(authViewModel: authViewModel)
                .tabItem { 
                    Image(systemName: "bag")
                }
            
            ProfileView(authViewModel: authViewModel)
                .tabItem { 
                    Image(systemName: "person")
                }
        }
        .tint(AppColors.accent)
        .enableInjection()
        .onAppear {
            print("🚀 MainTabView: onAppear triggered")
            // Set up the callback for refreshing orders
            print("🔗 MainTabView: Setting up OrderStatusViewModel callback...")
            orderStatusViewModel.onOrdersRefresh = { [weak authViewModel] userId in
                print("🔄 MainTabView: Callback triggered to refresh orders for userId: \(userId)")
                Task {
                    await refreshUserOrders(userId: userId, authViewModel: authViewModel)
                }
            }
            print("✅ MainTabView: OrderStatusViewModel callback set up successfully")
            
            // Load user orders and active order if user is authenticated
            if let currentUser = authViewModel.currentUser {
                print("👤 MainTabView: User authenticated, refreshing orders for: \(currentUser.email)")
                Task {
                    await refreshUserOrders(userId: currentUser.id, authViewModel: authViewModel)
                }
            } else {
                print("👤 MainTabView: No authenticated user, loading mock data for development")
                // For development/testing, load mock data
                #if DEBUG
                orderStatusViewModel.loadMockActiveOrder()
                #endif
            }
        }
        .onChange(of: authViewModel.currentUser) { _, newUser in
            print("🔄 MainTabView: User changed - newUser: \(newUser?.email ?? "nil")")
            // Reload user orders and active order when user changes
            if let user = newUser {
                print("👤 MainTabView: New user logged in, refreshing orders for: \(user.email)")
                Task {
                    await refreshUserOrders(userId: user.id, authViewModel: authViewModel)
                }
            } else {
                print("👤 MainTabView: User logged out, clearing active order")
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


