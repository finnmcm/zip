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
            // Product Image (fixed height container)
            ZStack {
                RoundedRectangle(cornerRadius: AppMetrics.cornerRadiusLarge)
                    .fill(AppColors.secondaryBackground)
                
                if let imageURL = product.primaryImageURL, !imageURL.isEmpty {
                    AsyncImage(url: URL(string: imageURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: AppMetrics.productCardImageHeight)
                                .clipped()
                        case .failure(let error):
                            VStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.red.opacity(0.7))
                                Text("Error")
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                                Text(imageURL.prefix(30) + "...")
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                                    .lineLimit(1)
                            }
                            .onAppear {
                                print("❌ AsyncImage FAILED for \(product.displayName)")
                                print("   Error: \(error)")
                                print("   URL: \(imageURL)")
                                print("   Images count: \(product.images.count)")
                                if !product.images.isEmpty {
                                    print("   First image URL: \(product.images.first?.imageURL ?? "nil")")
                                }
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
                            .onAppear {
                                print("🔄 AsyncImage LOADING for \(product.displayName)")
                                print("   URL: \(imageURL)")
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
                        print("🔍 Product \(product.displayName) has NO IMAGE URL")
                        print("   - primaryImageURL: \(product.primaryImageURL ?? "nil")")
                        print("   - images count: \(product.images.count)")
                        print("   - deprecated imageURL: \(product.imageURL ?? "nil")")
                        for (index, image) in product.images.enumerated() {
                            print("   - Image \(index): \(image.imageURL ?? "nil")")
                        }
                    }
                }
            }
            .frame(height: AppMetrics.productCardImageHeight)
            
            VStack(alignment: .leading, spacing: AppMetrics.spacingSmall) {
                // Product Name (fixed height with 2 lines)
                Text(product.displayName)
                    .font(.system(size: 15))
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .frame(height: 40, alignment: .top)
                    .foregroundStyle(AppColors.textPrimary)
                
                // Stock Alert Area (fixed height to normalize cards)
                ZStack(alignment: .leading) {
                    // Transparent placeholder to maintain height
                    Text("Placeholder")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .opacity(0)
                    
                    // Actual stock alert (if present)
                    if product.quantity <= 0 {
                        Text("Out of Stock")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.red.opacity(0.1))
                            .cornerRadius(AppMetrics.cornerRadiusSmall)
                    } else if product.quantity <= 5 {
                        Text("\(product.quantity) left")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.orange.opacity(0.1))
                            .cornerRadius(AppMetrics.cornerRadiusSmall)
                    }
                }
                .frame(height: 24, alignment: .leading)
                
                Spacer()
                
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
            .frame(minHeight: 160)
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


