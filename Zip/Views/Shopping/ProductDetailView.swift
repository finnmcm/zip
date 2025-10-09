//
//  ProductDetailView.swift
//  Zip
//

import SwiftUI
import Inject

struct ProductDetailView: View {
    @ObserveInjection var inject
    let product: Product
    let cartViewModel: CartViewModel
    let authViewModel: AuthViewModel
    let addToCart: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Store closed banner
                StoreClosedBanner(currentUser: authViewModel.currentUser)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AppMetrics.spacingLarge) {
                    // Product Image
                    ZStack {
                        RoundedRectangle(cornerRadius: AppMetrics.cornerRadiusLarge)
                            .fill(AppColors.secondaryBackground)
                            .frame(height: 300)
                        
                        if let imageURL = product.primaryImageURL, !imageURL.isEmpty {
                            AsyncImage(url: URL(string: imageURL)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 300)
                                        .clipped()
                                case .failure(let error):
                                    VStack(spacing: 12) {
                                        Image(systemName: "exclamationmark.triangle")
                                            .font(.system(size: 60))
                                            .foregroundStyle(.red.opacity(0.7))
                                        Text("Failed to load image")
                                            .font(.caption)
                                            .foregroundStyle(.red)
                                        Text(imageURL.prefix(40) + "...")
                                            .font(.caption2)
                                            .foregroundStyle(.gray)
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding()
                                    .onAppear {
                                        print("❌ DetailView AsyncImage FAILED for \(product.displayName)")
                                        print("   Error: \(error)")
                                        print("   URL: \(imageURL)")
                                        print("   Images count: \(product.images.count)")
                                        if !product.images.isEmpty {
                                            print("   First image URL: \(product.images.first?.imageURL ?? "nil")")
                                        }
                                    }
                                case .empty:
                                    ProgressView()
                                        .scaleEffect(1.5)
                                @unknown default:
                                    Image(systemName: "shippingbox")
                                        .font(.system(size: 80))
                                        .foregroundStyle(AppColors.accent.opacity(0.7))
                                }
                            }
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "shippingbox")
                                    .font(.system(size: 80))
                                    .foregroundStyle(AppColors.accent.opacity(0.7))
                                Text("No image available")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                            .onAppear {
                                print("🔍 DetailView: Product \(product.displayName) has NO IMAGE URL")
                                print("   - primaryImageURL: \(product.primaryImageURL ?? "nil")")
                                print("   - images count: \(product.images.count)")
                                print("   - deprecated imageURL: \(product.imageURL ?? "nil")")
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: AppMetrics.spacing) {
                        // Product Info
                        Text(product.displayName)
                            .font(.title.bold())
                            .foregroundStyle(AppColors.textPrimary)
                        
                        Text(product.category.displayName)
                            .font(.subheadline)
                            .foregroundStyle(AppColors.accent)
                            .padding(.horizontal, AppMetrics.spacing)
                            .padding(.vertical, 4)
                            .background(AppColors.accent.opacity(0.1))
                            .cornerRadius(AppMetrics.cornerRadiusSmall)
                        
                        Text("$\(NSDecimalNumber(decimal: product.price).doubleValue, specifier: "%.2f")")
                            .font(.title2.bold())
                            .foregroundStyle(AppColors.accent)
                        
                        // Availability
                        HStack {
                            Image(systemName: product.quantity > 0 ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(product.quantity > 0 ? .green : .red)
                            Text(product.quantity > 0 ? "In Stock" : "Out of Stock")
                                .font(.subheadline)
                                .foregroundStyle(product.quantity > 0 ? .green : .red)
                        }
                        .padding(.top, AppMetrics.spacing)
                        
                        Spacer(minLength: AppMetrics.spacingLarge)
                        
                        // Add to Cart Button
                        Button(action: {
                            print("🛒 ProductDetailView: Add to cart button tapped for '\(product.displayName)'")
                            addToCart()
                        }) {
                            HStack {
                                Image(systemName: "cart.badge.plus")
                                Text("Add to Cart")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(product.quantity > 0 ? AppColors.accent : .gray)
                            .foregroundColor(.white)
                            .cornerRadius(AppMetrics.cornerRadiusLarge)
                        }
                        .disabled(product.quantity <= 0)
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, AppMetrics.spacingLarge)
                    }
                }
            }
            .navigationTitle("Product Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .enableInjection()
    }
}
