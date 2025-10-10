//
//  CartItemRow.swift
//  Zip
//

import SwiftUI
import Inject

struct CartItemRow: View {
    @ObserveInjection var inject
    let item: CartItem
    let increment: () -> Void
    let decrement: () -> Void
    let remove: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: AppMetrics.spacing) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.product.displayName)
                        .font(.headline)
                        .foregroundStyle(AppColors.textPrimary)
                    Text("$\(NSDecimalNumber(decimal: item.product.price).doubleValue, specifier: "%.2f")")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                Spacer()
                
                // Quantity Controls
                HStack(spacing: 8) {
                    Button(action: decrement) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppColors.textSecondary)
                            .scaleEffect(0.9)
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(0.9)
                    .animation(.easeInOut(duration: 0.1), value: true)
                    
                    Text("\(item.quantity)")
                        .font(.headline)
                        .frame(minWidth: 30)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Button(action: increment) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(item.quantity >= item.product.quantity ? AppColors.textSecondary.opacity(0.3) : AppColors.accent)
                            .scaleEffect(0.9)
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(0.9)
                    .animation(.easeInOut(duration: 0.1), value: true)
                    .disabled(item.quantity >= item.product.quantity)
                }
                
                // Remove Button
                Button(action: remove) {
                    Image(systemName: "trash.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                        .scaleEffect(0.9)
                }
                .buttonStyle(.plain)
                .scaleEffect(0.9)
                .animation(.easeInOut(duration: 0.1), value: true)
            }
            
            // Stock warning indicator
            if item.quantity >= item.product.quantity {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text("Maximum stock reached (\(item.product.quantity) available)")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.orange.opacity(0.1))
                .cornerRadius(4)
            } else if item.quantity > item.product.quantity * 3 / 4 {
                // Show warning when cart quantity is more than 75% of available stock
                HStack(spacing: 4) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                    Text("Only \(item.product.quantity) in stock")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.blue.opacity(0.1))
                .cornerRadius(4)
            }
        }
        .padding()
        .background(AppColors.secondaryBackground)
        .cornerRadius(AppMetrics.cornerRadiusSmall)
        .enableInjection()
    }
}


