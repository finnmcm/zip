//
//  BannerNotificationView.swift
//  Zip
//

import SwiftUI

struct BannerNotificationView: View {
    let message: String
    let type: CartViewModel.BannerType
    let onDismiss: () -> Void
    let isExiting: Bool // Add this parameter
    @State private var isVisible = false
    
    private var backgroundColor: Color {
        return .white
    }
    
    private var iconName: String {
        switch type {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "xmark.circle.fill"
        case .info:
            return "info.circle.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: AppMetrics.spacing) {
            Image(systemName: iconName)
                .foregroundColor(.white)
                .font(.title2)
            
            Text(message)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
        }
        .padding(.horizontal, AppMetrics.spacingLarge)
        .padding(.vertical, AppMetrics.spacing)
        .background(AppColors.accent)
        .cornerRadius(AppMetrics.cornerRadiusLarge)
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        .padding(.horizontal, AppMetrics.spacingLarge)
        .padding(.bottom, AppMetrics.spacingLarge)
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0.0)
        .offset(y: isVisible ? 0 : 50) // Add slide-down effect
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isVisible)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isVisible = true
            }
        }
        .onChange(of: isExiting) { _, newValue in
            if newValue {
                // Trigger exit animation
                withAnimation(.easeInOut(duration: 0.3)) {
                    isVisible = false
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            
            BannerNotificationView(
                message: "Item added to cart!",
                type: .success,
                onDismiss: {},
                isExiting: false
            )
        }
    }
}
