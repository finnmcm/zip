//
//  CategoryListView.swift
//  Zip
//

import SwiftUI
import Inject

struct CategoryListView: View {
    @ObserveInjection var inject
    @State private var searchText = ""
    let cartViewModel: CartViewModel
    let shoppingViewModel: ShoppingViewModel
    let orderStatusViewModel: OrderStatusViewModel
    let authViewModel: AuthViewModel
    
    private let categories = ProductCategory.allCases
    
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    init(cartViewModel: CartViewModel, shoppingViewModel: ShoppingViewModel, orderStatusViewModel: OrderStatusViewModel, authViewModel: AuthViewModel) {
        self.cartViewModel = cartViewModel
        self.shoppingViewModel = shoppingViewModel
        self.orderStatusViewModel = orderStatusViewModel
        self.authViewModel = authViewModel
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Order status banner at the top
                    if let activeOrder = orderStatusViewModel.activeOrder {
                        OrderStatusBannerContainer(
                            activeOrder: orderStatusViewModel.activeOrder,
                            onBannerDismiss: {
                                orderStatusViewModel.dismissBanner()
                            }
                        )
                    }
                    
                    // Store closed banner
                    StoreClosedBanner(currentUser: authViewModel.currentUser)
                    
                    // Email verification banner
                    EmailVerificationBanner(currentUser: authViewModel.currentUser)
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            // Header
                            HStack {
                                Rectangle()
                                    .foregroundStyle(AppColors.accent)
                                    .frame(width: 120, height: 2)
                                
                                Image("logo_inverted")
                                    .resizable()
                                    .frame(width: 100, height: 100)
                                
                                Rectangle()
                                    .foregroundStyle(AppColors.accent)
                                    .frame(width: 120, height: 2)
                            }
                            
                            // Product Search Bar
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(AppColors.textSecondary)
                                    .padding(.leading, AppMetrics.spacing)
                                
                                TextField("Search all products...", text: $searchText)
                                    .textFieldStyle(.plain)
                                    .font(.body)
                                    .foregroundStyle(AppColors.textPrimary)
                                
                                if !searchText.isEmpty {
                                    Button(action: {
                                        searchText = ""
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(AppColors.textSecondary)
                                    }
                                    .padding(.trailing, AppMetrics.spacing)
                                }
                            }
                            .padding(.vertical, AppMetrics.spacing)
                            .background(
                                RoundedRectangle(cornerRadius: AppMetrics.cornerRadius)
                                    .fill(AppColors.surface)
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                            .padding(.horizontal, AppMetrics.spacingLarge)
                            
                            // Search Results
                            if !searchText.isEmpty {
                                let searchResults = shoppingViewModel.products.filter { product in
                                    product.displayName.localizedCaseInsensitiveContains(searchText) ||
                                    product.category.displayName.localizedCaseInsensitiveContains(searchText)
                                }
                                
                                if !searchResults.isEmpty {
                                    VStack(alignment: .leading, spacing: AppMetrics.spacingSmall) {
                                        Text("Search Results (\(searchResults.count))")
                                            .font(.headline)
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
                                    }
                                    .padding(.vertical, AppMetrics.spacing)
                                } else {
                                    VStack(spacing: AppMetrics.spacing) {
                                        Image(systemName: "magnifyingglass")
                                            .font(.system(size: 32))
                                            .foregroundStyle(AppColors.textSecondary)
                                        
                                        Text("No products found")
                                            .font(.headline)
                                            .foregroundStyle(AppColors.textPrimary)
                                        
                                        Text("Try searching with different keywords")
                                            .font(.subheadline)
                                            .foregroundStyle(AppColors.textSecondary)
                                    }
                                    .padding(.vertical, AppMetrics.spacingLarge)
                                }
                            }
                            
                            // Categories Grid
                            VStack {
                                if shoppingViewModel.isLoading {
                                    VStack(spacing: AppMetrics.spacingLarge) {
                                        ProgressView()
                                            .tint(AppColors.accent)
                                            .scaleEffect(1.5)
                                        Text("Loading products...")
                                            .font(.subheadline)
                                            .foregroundStyle(AppColors.textSecondary)
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                } else if let errorMessage = shoppingViewModel.errorMessage {
                                    VStack(spacing: AppMetrics.spacingLarge) {
                                        Image(systemName: "exclamationmark.triangle")
                                            .font(.system(size: 48))
                                            .foregroundStyle(AppColors.textSecondary)
                                        
                                        Text("Unable to load products")
                                            .font(.headline)
                                            .foregroundStyle(AppColors.textSecondary)
                                        
                                        Text(errorMessage)
                                            .font(.subheadline)
                                            .foregroundStyle(AppColors.textSecondary.opacity(0.7))
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, AppMetrics.spacingLarge)
                                        
                                        Button("Retry") {
                                            Task {
                                                await shoppingViewModel.loadProducts()
                                            }
                                        }
                                        .padding()
                                        .background(AppColors.accent)
                                        .foregroundStyle(.white)
                                        .cornerRadius(AppMetrics.cornerRadiusLarge)
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                } else {
                                    ForEach(categories, id: \.self) { category in
                                            CategoryCard(category: category, productCount: shoppingViewModel.products.filter { $0.category == category }.count, cartViewModel: cartViewModel, shoppingViewModel: shoppingViewModel, authViewModel: authViewModel)
                                    }
                                }
                            }
                            .padding(.horizontal, AppMetrics.spacingLarge)
                            
                            Spacer(minLength: 0)
                        }
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
            }
            .navigationTitle("Shop")
            .navigationBarHidden(true)
        }
        .enableInjection()
    }
}

struct CategoryCard: View {
    let category: ProductCategory
    let productCount: Int
    let cartViewModel: CartViewModel
    let shoppingViewModel: ShoppingViewModel
    let authViewModel: AuthViewModel
    
    // Get featured products for this category (first 3-4 products)
    private var featuredProducts: [Product] {
        let categoryProducts = shoppingViewModel.products.filter { $0.category == category && $0.quantity > 0 }
        return Array(categoryProducts.prefix(4))
    }
    
    var body: some View {
        VStack(spacing: AppMetrics.spacing) {
        NavigationLink(destination: ProductListView(category: category, cartViewModel: cartViewModel, shoppingViewModel: shoppingViewModel, authViewModel: authViewModel)) {
            HStack{
                Image(systemName: category.iconName)
                .foregroundStyle(AppColors.northwesternPurple)
                .font(.title)
                .padding(.top, 10)
            Text(category.displayName)
                .font(.title)
                .foregroundStyle(AppColors.textPrimary)
                .padding(.top, 10)

                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(AppColors.textSecondary)
                    .font(.title)
                    .padding(.trailing, 20)
                    .padding(.top, 10)
            }
        }
        .buttonStyle(.plain)
            // Featured Products Section
            if !featuredProducts.isEmpty {
                VStack(alignment: .leading, spacing: AppMetrics.spacingSmall) {
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppMetrics.spacing) {
                            ForEach(featuredProducts) { product in
                                FeatureProductCard(product: product, cartViewModel: cartViewModel, authViewModel: authViewModel)
                                    .frame(width: 160)
                            }
                        }
                    }
                }
            }
            
            /*
            RoundedRectangle(cornerRadius: 20.0)
                                    .stroke(AppColors.northwesternPurple, lineWidth: 2.0)
            .frame(width: 350, height: 100)
            .foregroundStyle(.white)
            .overlay {
                HStack{
                    Image(systemName: category.iconName)
                    .foregroundStyle(AppColors.northwesternPurple)
                    .padding(.leading, 20)
                    .font(.title)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.displayName)
                            .font(.title)
                            .foregroundStyle(AppColors.accent)
                        
                        Text("\(productCount) items")
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .padding(.leading, 10)
                    
                    Spacer()
                }
            }   
            */
        }
        .padding(.vertical, 10)
    }
}


