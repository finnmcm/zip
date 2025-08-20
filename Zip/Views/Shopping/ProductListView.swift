//
//  ProductListView.swift
//  Zip
//

import SwiftUI
import SwiftData
import Inject

struct ProductListView: View {
    @ObserveInjection var inject
    @StateObject private var viewModel = ShoppingViewModel()
    @Environment(\.modelContext) private var context
    @State private var cartViewModel: CartViewModel?
    @State private var selectedProduct: Product?
    @State private var searchText = ""

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    private var filteredProducts: [Product] {
        if searchText.isEmpty {
            return viewModel.products
        } else {
            return viewModel.products.filter { product in
                product.name.localizedCaseInsensitiveContains(searchText) ||
                product.category.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppColors.textSecondary)
                        
                        TextField("Search products...", text: $searchText)
                            .textFieldStyle(.plain)
                        
                        if !searchText.isEmpty {
                            Button("Clear") {
                                searchText = ""
                            }
                            .font(.caption)
                            .foregroundStyle(AppColors.accent)
                        }
                    }
                    .padding()
                    .background(AppColors.secondaryBackground)
                    .cornerRadius(AppMetrics.cornerRadiusLarge)
                    .padding(.horizontal, AppMetrics.spacingLarge)
                    .padding(.top, AppMetrics.spacingLarge)
                    
                    if viewModel.isLoading {
                        Spacer()
                        VStack(spacing: AppMetrics.spacingLarge) {
                            ProgressView()
                                .tint(AppColors.accent)
                                .scaleEffect(1.5)
                            Text("Loading products...")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        Spacer()
                    } else if filteredProducts.isEmpty {
                        Spacer()
                        VStack(spacing: AppMetrics.spacingLarge) {
                            Image(systemName: searchText.isEmpty ? "shippingbox" : "magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundStyle(AppColors.textSecondary)
                            
                            Text(searchText.isEmpty ? "No products available" : "No results found")
                                .font(.headline)
                                .foregroundStyle(AppColors.textSecondary)
                            
                            Text(searchText.isEmpty ? "Check back soon for new items" : "Try adjusting your search terms")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.textSecondary.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AppMetrics.spacingLarge)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: AppMetrics.spacingLarge) {
                                ForEach(filteredProducts, id: \.id) { product in
                                    ProductCard(product: product) {
                                        cartViewModel?.add(product: product)
                                    }
                                    .onTapGesture {
                                        selectedProduct = product
                                    }
                                }
                            }
                            .padding(.horizontal, AppMetrics.spacingLarge)
                            .padding(.top, AppMetrics.spacingLarge)
                        }
                    }
                }
            }
            .navigationTitle("Shop")
            .sheet(item: $selectedProduct) { product in
                ProductDetailView(product: product) {
                    cartViewModel?.add(product: product)
                    selectedProduct = nil
                }
            }
        }
        .task { await viewModel.loadProducts() }
        .onAppear {
            if cartViewModel == nil { 
                cartViewModel = CartViewModel(context: context) 
            }
        }
        .enableInjection()
    }
}


