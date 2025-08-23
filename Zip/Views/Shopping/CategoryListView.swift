//
//  CategoryListView.swift
//  Zip
//

import SwiftUI
import Inject

struct CategoryListView: View {
    @ObserveInjection var inject
    let cartViewModel: CartViewModel
    
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
                        ForEach(categories, id: \.self) { category in
                            NavigationLink(destination: ProductListView(category: category, cartViewModel: cartViewModel)) {
                                CategoryCard(category: category)
                            }
                            .buttonStyle(.plain)
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
                    Text(category.displayName)
                        .font(.title)
                        .foregroundStyle(AppColors.accent)
                        .padding(.leading, 10)
                    Spacer()
                }
            }
            
    }
    .padding(.vertical, 10)
    }
}


