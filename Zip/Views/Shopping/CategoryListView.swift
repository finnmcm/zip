//
//  CategoryListView.swift
//  Zip
//

import SwiftUI
import Inject

struct CategoryListView: View {
    @ObserveInjection var inject
    @State private var searchText = ""
    @ObservedObject var cartViewModel: CartViewModel
    @ObservedObject var shoppingViewModel: ShoppingViewModel
    @ObservedObject var orderStatusViewModel: OrderStatusViewModel
    @ObservedObject var authViewModel: AuthViewModel
    
    private let categories = ProductCategory.allCases
    
    init(cartViewModel: CartViewModel, shoppingViewModel: ShoppingViewModel, orderStatusViewModel: OrderStatusViewModel, authViewModel: AuthViewModel) {
        self._cartViewModel = ObservedObject(wrappedValue: cartViewModel)
        self._shoppingViewModel = ObservedObject(wrappedValue: shoppingViewModel)
        self._orderStatusViewModel = ObservedObject(wrappedValue: orderStatusViewModel)
        self._authViewModel = ObservedObject(wrappedValue: authViewModel)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: AppMetrics.spacingLarge) {
                            // Modern Header Section
                            VStack(spacing: AppMetrics.spacing) {
                                Image("logo_inverted")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 80)
                                    .padding(.top, AppMetrics.spacingSmall)
                                
                            }
                            .padding(.horizontal, AppMetrics.spacingLarge)
                            
                            // Search Bar Section
                            searchBarView
                                .padding(.horizontal, AppMetrics.spacingLarge)
                            
                            // Search Results Section
                            if !searchText.isEmpty {
                                searchResultsView
                            } else {
                                // Categories Section
                                categoriesContentView
                            }
                        }
                        .padding(.bottom, AppMetrics.spacingLarge)
                    }
                    
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
                .overlay(alignment: .top) {
                    // Banners overlaid on top
                    VStack(spacing: 0) {
                        // Order status banner at the top
                        if let activeOrder = orderStatusViewModel.activeOrder {
                            OrderStatusBannerContainer(
                                activeOrder: activeOrder,
                                onBannerDismiss: {
                                    orderStatusViewModel.dismissBanner()
                                },
                                onOrderCancelled: { _ in
                                    orderStatusViewModel.clearActiveOrder()
                                    Task {
                                        await authViewModel.refreshCurrentUser()
                                    }
                                },
                                authViewModel: authViewModel
                            )
                        }
                        
                        // Store closed banner
                   //     StoreClosedBanner(currentUser: authViewModel.currentUser)
                        
                        // Email verification banner
                        EmailVerificationBanner(currentUser: authViewModel.currentUser, authViewModel: authViewModel)
                    }
                }
            }
            .navigationTitle("Shop")
            .navigationBarHidden(true)
        }
        .enableInjection()
    }
    
    // MARK: - Search Bar
    private var searchBarView: some View {
        HStack(spacing: AppMetrics.spacing) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppColors.textSecondary)
                .font(.system(size: 18))
            
            TextField("Search products...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .foregroundStyle(AppColors.textPrimary)
                .autocorrectionDisabled()
            
            if !searchText.isEmpty {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        searchText = ""
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppColors.textSecondary)
                        .font(.system(size: 18))
                }
            }
        }
        .padding(.horizontal, AppMetrics.spacingLarge)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.surface)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Search Results
    private var searchResultsView: some View {
        let searchResults = shoppingViewModel.products.filter { product in
            product.displayName.localizedCaseInsensitiveContains(searchText) ||
            product.category.displayName.localizedCaseInsensitiveContains(searchText)
        }
        
        return VStack(alignment: .leading, spacing: AppMetrics.spacing) {
            if !searchResults.isEmpty {
                Text("Found \(searchResults.count) \(searchResults.count == 1 ? "product" : "products")")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.horizontal, AppMetrics.spacingLarge)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppMetrics.spacing) {
                        ForEach(searchResults) { product in
                            FeatureProductCard(product: product, cartViewModel: cartViewModel, authViewModel: authViewModel)
                                .frame(width: 160)
                        }
                    }
                    .padding(.horizontal, AppMetrics.spacingLarge)
                }
            } else {
                VStack(spacing: AppMetrics.spacing) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(AppColors.textSecondary.opacity(0.5))
                    
                    Text("No products found")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Text("Try searching with different keywords")
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
    }
    
    // MARK: - Categories Content
    @ViewBuilder
    private var categoriesContentView: some View {
        let _ = print("🏪 CategoryListView: Rendering categoriesContentView - isLoading: \(shoppingViewModel.isLoading), products count: \(shoppingViewModel.products.count), errorMessage: \(shoppingViewModel.errorMessage ?? "nil")")
        
        if shoppingViewModel.isLoading {
            loadingView
        } else if let errorMessage = shoppingViewModel.errorMessage {
            errorView(message: errorMessage)
        } else {
            VStack(alignment: .leading, spacing: AppMetrics.spacing) {
                Text("Browse Categories")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.horizontal, AppMetrics.spacingLarge)
                
                VStack(spacing: AppMetrics.spacing) {
                    ForEach(categories, id: \.self) { category in
                        CategoryCard(
                            category: category,
                            productCount: shoppingViewModel.products.filter { $0.category == category }.count,
                            inStockCount: shoppingViewModel.products.filter { $0.category == category && $0.quantity > 0 }.count,
                            cartViewModel: cartViewModel,
                            shoppingViewModel: shoppingViewModel,
                            authViewModel: authViewModel
                        )
                    }
                }
                .padding(.horizontal, AppMetrics.spacingLarge)
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: AppMetrics.spacingLarge) {
            ProgressView()
                .tint(AppColors.accent)
                .scaleEffect(1.5)
            Text("Loading products...")
                .font(.system(size: 16))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Error View
    private func errorView(message: String) -> some View {
        VStack(spacing: AppMetrics.spacingLarge) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(AppColors.textSecondary.opacity(0.5))
            
            Text("Unable to load products")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppMetrics.spacingLarge)
            
            Button(action: {
                Task {
                    await shoppingViewModel.loadProducts()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(AppColors.accent)
                .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    let category: ProductCategory
    let productCount: Int
    let inStockCount: Int
    @ObservedObject var cartViewModel: CartViewModel
    @ObservedObject var shoppingViewModel: ShoppingViewModel
    @ObservedObject var authViewModel: AuthViewModel
    
    private var isAssetImage: Bool {
        return category == .foodsnacks || category == .chipscandy
    }
    
    var body: some View {
        NavigationLink(destination: ProductListView(
            category: category,
            cartViewModel: cartViewModel,
            shoppingViewModel: shoppingViewModel,
            authViewModel: authViewModel
        )) {
            cardContent
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Card Content
    private var cardContent: some View {
        HStack(spacing: AppMetrics.spacingLarge) {
            categoryIcon
            
            Text(category.displayName)
                .font(.system(size: 23, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
            
            Spacer()
            
            /*
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary)*/
        }
        .padding(.horizontal, AppMetrics.spacingLarge)
        .padding(.vertical, AppMetrics.spacingLarge)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.border.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Category Icon
    @ViewBuilder
    private var categoryIcon: some View {
        if isAssetImage {
            Image(category.iconName)
                .resizable()
                .renderingMode(.template)
                .foregroundColor(AppColors.northwesternPurple)
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
        } else {
            Image(systemName: category.iconName)
                .font(.system(size: 28))
                .foregroundStyle(AppColors.northwesternPurple)
                .frame(width: 32, height: 32)
        }
    }
}
