//
//  ProductCard.swift
//  Zip
//

import SwiftUI
import Inject

struct ProductCard: View {
    @ObserveInjection var inject
    let product: Product
    let cartViewModel: CartViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacing) {
            // Product Image
            ZStack {
                RoundedRectangle(cornerRadius: AppMetrics.cornerRadiusLarge)
                    .fill(AppColors.secondaryBackground)
                    .frame(height: AppMetrics.productCardImageHeight)
                
                if let imageURL = product.primaryImageURL, !imageURL.isEmpty {
                    AsyncImage(url: URL(string: imageURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(height: AppMetrics.productCardImageHeight)
                                .clipped()
                        case .failure(let error):
                            VStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.red.opacity(0.7))
                                Text("Error")
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                                Text(imageURL)
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                                    .lineLimit(1)
                            }
                            .onAppear {
                                print("❌ AsyncImage failed for \(product.displayName): \(error)")
                                print("   URL: \(imageURL)")
                            }
                        case .empty:
                            VStack {
                                Image(systemName: "shippingbox")
                                    .font(.system(size: 40))
                                    .foregroundStyle(AppColors.accent.opacity(0.7))
                                Text("Loading...")
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                            }
                        @unknown default:
                            VStack {
                                Image(systemName: "shippingbox")
                                    .font(.system(size: 40))
                                    .foregroundStyle(AppColors.accent.opacity(0.7))
                                Text("Unknown")
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                } else {
                    VStack {
                        Image(systemName: "shippingbox")
                            .font(.system(size: 40))
                            .foregroundStyle(AppColors.accent.opacity(0.7))
                        Text("No Image")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                    }
                    .onAppear {
                        print("🔍 Product \(product.displayName) has no image URL")
                        print("   - primaryImageURL: \(product.primaryImageURL ?? "nil")")
                        print("   - images count: \(product.images.count)")
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: AppMetrics.spacingSmall) {
                // Product Name
                Text(product.displayName)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundStyle(AppColors.textPrimary)
                
                // Category Badge
                Text(product.category.displayName)
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
                    print("🛒 ProductCard: Add to cart button tapped for '\(product.displayName)'")
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    cartViewModel.add(product: product)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.caption.bold())
                        Text("Add to Cart")
                            .font(.caption.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(product.quantity > 0 ? AppColors.accent : .gray.opacity(0.3))
                    .foregroundColor(product.quantity > 0 ? .white : .gray)
                    .cornerRadius(AppMetrics.cornerRadiusSmall)
                }
                .buttonStyle(.plain)
                .disabled(product.quantity <= 0)
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


