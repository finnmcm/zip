//
//  ConfirmationDialog.swift
//  Zip
//

import SwiftUI

struct ConfirmationDialog: View {
    let title: String
    let message: String
    let confirmButtonTitle: String
    let cancelButtonTitle: String
    let confirmAction: () -> Void
    let cancelAction: () -> Void
    let isDestructive: Bool
    
    init(
        title: String,
        message: String,
        confirmButtonTitle: String = "Confirm",
        cancelButtonTitle: String = "Cancel",
        isDestructive: Bool = false,
        confirmAction: @escaping () -> Void,
        cancelAction: @escaping () -> Void = {}
    ) {
        self.title = title
        self.message = message
        self.confirmButtonTitle = confirmButtonTitle
        self.cancelButtonTitle = cancelButtonTitle
        self.isDestructive = isDestructive
        self.confirmAction = confirmAction
        self.cancelAction = cancelAction
    }
    
    var body: some View {
        VStack(spacing: AppMetrics.spacingLarge) {
            // Title
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppColors.northwesternPurple)
                .multilineTextAlignment(.center)
            
            // Message
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            // Buttons
            VStack(spacing: AppMetrics.spacing) {
                // Confirm Button
                Button(action: confirmAction) {
                    Text(confirmButtonTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppMetrics.spacing)
                        .background(isDestructive ? Color.red : AppColors.northwesternPurple)
                        .cornerRadius(AppMetrics.cornerRadiusSmall)
                }
                
                // Cancel Button
                Button(action: cancelAction) {
                    Text(cancelButtonTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.northwesternPurple)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppMetrics.spacing)
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppMetrics.cornerRadiusSmall)
                                .stroke(AppColors.northwesternPurple, lineWidth: 2)
                        )
                }
            }
        }
        .padding(AppMetrics.spacingLarge)
        .background(Color(.systemBackground))
        .cornerRadius(AppMetrics.cornerRadiusLarge)
        .shadow(radius: 10)
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
        
        ConfirmationDialog(
            title: "Cancel Order",
            message: "Are you sure you want to cancel this order? This action cannot be undone and you will receive a full refund.",
            confirmButtonTitle: "Yes, Cancel Order",
            cancelButtonTitle: "Keep Order",
            isDestructive: true,
            confirmAction: {
                print("Order cancelled")
            },
            cancelAction: {
                print("Order kept")
            }
        )
        .padding(.horizontal, AppMetrics.spacingLarge)
    }
}
