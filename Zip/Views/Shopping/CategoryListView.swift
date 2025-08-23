//
//  CategoryListView.swift
//  Zip
//

import SwiftUI
import Inject

struct CategoryListView: View {
    @ObserveInjection var inject
    let cartViewModel: CartViewModel
    let shoppingViewModel: ShoppingViewModel
    
    private let categories = ProductCategory.allCases
    
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: AppMetrics.spacingLarge) {
                    // Header
                    HStack{
                        ZStack{
                            Circle()
                            .frame(width: 50)
                            .foregroundStyle(AppColors.accent)
                            Image(systemName: "shippingbox")
                            .foregroundStyle(.white)
                            .font(.title)
                        }
                        
                        Text("What are you craving?")
                        .font(.title2)
                        Spacer()
                    }
                    .padding(.leading, 20)
                    .padding(.top, 10)
                    
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
                                NavigationLink(destination: ProductListView(category: category, cartViewModel: cartViewModel, shoppingViewModel: shoppingViewModel)) {
                                    CategoryCard(category: category, productCount: shoppingViewModel.products.filter { $0.category == category }.count)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, AppMetrics.spacingLarge)
                    .padding(.top, 20)
                    
                    Spacer()
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
    
    var body: some View {
        VStack() {
            RoundedRectangle(cornerRadius: 20.0)
            .stroke(.purple, lineWidth: 2.0)
            .frame(width: 350, height: 100)
            .foregroundStyle(.white)
            .overlay {
                HStack{
                    Image(systemName: category.iconName)
                    .foregroundStyle(.purple)
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
            
    }
    .padding(.vertical, 10)
    }
}


