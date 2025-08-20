//
//  ProductCard.swift
//  Zip
//

import SwiftUI
import Inject

struct ProductCard: View {
    @ObserveInjection var inject
    let product: Product
    let addAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacing) {
            // Product Image
            ZStack {
                RoundedRectangle(cornerRadius: AppMetrics.cornerRadiusLarge)
                    .fill(AppColors.secondaryBackground)
                    .frame(height: 140)
                
                Image(systemName: "shippingbox")
                    .font(.system(size: 40))
                    .foregroundStyle(AppColors.accent.opacity(0.7))
            }
            
            VStack(alignment: .leading, spacing: AppMetrics.spacingSmall) {
                // Product Name
                Text(product.name)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundStyle(AppColors.textPrimary)
                
                // Category Badge
                Text(product.category.capitalized)
                    .font(.caption)
                    .foregroundStyle(AppColors.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColors.accent.opacity(0.1))
                    .cornerRadius(AppMetrics.cornerRadiusSmall)
                
                // Price
                Text("$\(NSDecimalNumber(decimal: product.price).doubleValue, specifier: "%.2f")")
                    .font(.title3.bold())
                    .foregroundStyle(AppColors.accent)
                
                // Add to Cart Button
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    addAction()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.caption.bold())
                        Text("Add to Cart")
                            .font(.caption.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(product.inStock ? AppColors.accent : .gray.opacity(0.3))
                    .foregroundColor(product.inStock ? .white : .gray)
                    .cornerRadius(AppMetrics.cornerRadiusSmall)
                }
                .buttonStyle(.plain)
                .disabled(!product.inStock)
            }
        }
        .padding(AppMetrics.spacing)
        .background(AppColors.background)
        .cornerRadius(AppMetrics.cornerRadiusLarge)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: AppMetrics.cornerRadiusLarge)
                .stroke(AppColors.secondaryBackground, lineWidth: 1)
        )
        .enableInjection()
    }
}


