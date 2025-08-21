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
        HStack(spacing: AppMetrics.spacing) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.product.name)
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
                        .foregroundStyle(AppColors.accent)
                        .scaleEffect(0.9)
                }
                .buttonStyle(.plain)
                .scaleEffect(0.9)
                .animation(.easeInOut(duration: 0.1), value: true)
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
        .padding()
        .background(AppColors.secondaryBackground)
        .cornerRadius(AppMetrics.cornerRadiusSmall)
        .enableInjection()
    }
}


