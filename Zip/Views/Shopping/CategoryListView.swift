//
//  CategoryListView.swift
//  Zip
//

import SwiftUI
import Inject

struct CategoryListView: View {
    @ObserveInjection var inject
    let cartViewModel: CartViewModel
    
    private let categories = [
        "Snacks",
        "Chips and Candy", 
        "Dorm/Party/School",
        "Medical",
    ]
    
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: AppMetrics.spacingLarge) {
                    // Header
                    VStack(spacing: AppMetrics.spacingSmall) {
                        Text("What are you craving?")
                            .font(.title.bold())
                            .foregroundStyle(AppColors.textPrimary)
                        
                        Text("Quick delivery to your campus location")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .padding(.top, AppMetrics.spacingLarge)
                    
                    // Categories Grid
                    LazyVGrid(columns: columns, spacing: AppMetrics.spacingLarge) {
                        ForEach(categories, id: \.self) { category in
                            NavigationLink(destination: ProductListView(category: category, cartViewModel: cartViewModel)) {
                                CategoryCard(category: category)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AppMetrics.spacingLarge)
                    
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
    let category: String
    
    var body: some View {
        VStack(spacing: AppMetrics.spacing) {
            ZStack {
                RoundedRectangle(cornerRadius: AppMetrics.cornerRadiusLarge)
                    .fill(AppColors.secondaryBackground)
                    .frame(height: 120)
                
                Image(systemName: iconName)
                    .font(.system(size: 40))
                    .foregroundStyle(AppColors.accent)
            }
            
            Text(category.capitalized)
                .font(.headline)
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding(AppMetrics.spacing)
        .background(AppColors.background)
        .cornerRadius(AppMetrics.cornerRadiusLarge)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: AppMetrics.cornerRadiusLarge)
                .stroke(AppColors.secondaryBackground, lineWidth: 1)
        )
    }
    
    private var iconName: String {
        switch category {
        case "Snacks": return "birthday.cake"
        case "Beverages": return "cup.and.saucer"
        case "Food": return "fork.knife"
        case "Study": return "book"
        case "Convenience": return "shippingbox"
        default: return "shippingbox"
        }
    }
}


