//
//  FeatureProductCard.swift
//  Zip
//

import SwiftUI
import Inject

struct FeatureProductCard: View {
    @ObserveInjection var inject
    let product: Product
    let cartViewModel: CartViewModel
    let authViewModel: AuthViewModel
    
    var body: some View {
        NavigationLink(destination: ProductDetailView(
            product: product,
            cartViewModel: cartViewModel,
            authViewModel: authViewModel,
            addToCart: {
                // This will be handled by the ProductDetailView
            }
        )) {
            VStack(alignment: .leading, spacing: AppMetrics.spacingSmall) {
                // Product Image
                ZStack {
                    RoundedRectangle(cornerRadius: AppMetrics.cornerRadiusLarge)
                        .fill(AppColors.secondaryBackground)
                        .frame(height: AppMetrics.featureCardImageHeight)
                    
                    if let imageURL = product.primaryImageURL, !imageURL.isEmpty {
                        AsyncImage(url: URL(string: imageURL)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: AppMetrics.featureCardImageHeight)
                                    .clipped()
                            case .failure(let error):
                                VStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.system(size: 30))
                                        .foregroundStyle(.red.opacity(0.7))
                                    Text("Error")
                                        .font(.caption2)
                                        .foregroundStyle(.red)
                                }
                                .onAppear {
                                    print("❌ FeatureCard AsyncImage FAILED for \(product.displayName)")
                                    print("   Error: \(error)")
                                    print("   URL: \(imageURL)")
                                    print("   Images count: \(product.images.count)")
                                }
                            case .empty:
                                Image(systemName: "shippingbox")
                                    .font(.system(size: 35))
                                    .foregroundStyle(AppColors.accent.opacity(0.7))
                            @unknown default:
                                Image(systemName: "shippingbox")
                                    .font(.system(size: 35))
                                    .foregroundStyle(AppColors.accent.opacity(0.7))
                            }
                        }
                    } else {
                        VStack {
                            Image(systemName: "shippingbox")
                                .font(.system(size: 35))
                                .foregroundStyle(AppColors.accent.opacity(0.7))
                            Text("No URL")
                                .font(.caption2)
                                .foregroundStyle(.gray)
                        }
                        .onAppear {
                            print("🔍 FeatureCard: Product \(product.displayName) has NO IMAGE URL")
                            print("   - primaryImageURL: \(product.primaryImageURL ?? "nil")")
                            print("   - images count: \(product.images.count)")
                        }
                    }
                }
                
                // Price
                Text(product.displayName)
                    .font(.headline.bold())
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
        .buttonStyle(.plain)
        .enableInjection()
    }
}

