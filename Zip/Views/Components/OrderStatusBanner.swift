//
//  OrderStatusBanner.swift
//  Zip
//

import SwiftUI

struct OrderStatusBanner: View {
    let order: Order
    let onTap: () -> Void
    let onDismiss: () -> Void
    
    @State private var isVisible = false
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?
    
    private var statusColor: Color {
        switch order.status {
        case .inQueue:
            return AppColors.northwesternPurple
        case .inProgress:
            return AppColors.accent
        default:
            return AppColors.northwesternPurple
        }
    }
    
    private var statusIcon: String {
        switch order.status {
        case .inQueue:
            return "clock.fill"
        case .inProgress:
            return "bicycle"
        default:
            return "clock.fill"
        }
    }
    
    private var statusMessage: String {
        switch order.status {
        case .inQueue:
            return "Your order is in the queue"
        case .inProgress:
            return "Your order is on the way!"
        default:
            return "Order status update"
        }
    }
    
    private var estimatedTimeString: String {
        guard let estimatedTime = order.estimatedDeliveryTime else {
            return "ETA: Calculating..."
        }
        
        let timeRemaining = estimatedTime.timeIntervalSinceNow
        if timeRemaining <= 0 {
            return "ETA: Arriving soon!"
        }
        
        let minutes = Int(timeRemaining / 60)
        if minutes < 1 {
            return "ETA: Less than 1 minute"
        } else if minutes == 1 {
            return "ETA: 1 minute"
        } else {
            return "ETA: \(minutes) minutes"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main banner content
            Button(action: onTap) {
                HStack(spacing: AppMetrics.spacing) {
                    // Status icon with background
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: statusIcon)
                            .foregroundColor(.white)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(statusMessage)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text(estimatedTimeString)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    // Dismiss button
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AppMetrics.spacingLarge)
                .padding(.vertical, AppMetrics.spacing)
                .background(
                    LinearGradient(
                        colors: [
                            statusColor,
                            statusColor.opacity(0.8)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(AppMetrics.cornerRadiusLarge)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            
            // Progress bar for in-progress orders
            if order.status == .inProgress {
                ProgressView()
                    .progressViewStyle(LinearProgressViewStyle(tint: .white.opacity(0.6)))
                    .scaleEffect(x: 1, y: 0.5, anchor: .center)
                    .padding(.horizontal, AppMetrics.spacingLarge)
                    .padding(.top, 8)
            }
        }
        .padding(.horizontal, AppMetrics.spacingLarge)
        .padding(.top, AppMetrics.spacingLarge)
        .scaleEffect(isVisible ? 1.0 : 0.9)
        .opacity(isVisible ? 1.0 : 0.0)
        .offset(y: isVisible ? 0 : -50)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isVisible)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isVisible = true
            }
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            // Update time remaining every 30 seconds
            if let estimatedTime = order.estimatedDeliveryTime {
                timeRemaining = estimatedTime.timeIntervalSinceNow
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Order Status Banner Container
struct OrderStatusBannerContainer: View {
    let activeOrder: Order?
    let onBannerTap: () -> Void
    let onBannerDismiss: () -> Void
    
    var body: some View {
        if let order = activeOrder, 
           [OrderStatus.inQueue, OrderStatus.inProgress].contains(order.status) {
            OrderStatusBanner(
                order: order,
                onTap: onBannerTap,
                onDismiss: onBannerDismiss
            )
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()
        
        VStack {
            // Preview for in-queue order
            OrderStatusBanner(
                order: Order(
                    user: User(id: "test-user-id", email: "test@u.northwestern.edu", firstName: "John", lastName: "Doe", phoneNumber: "123-456-7890"),
                    items: [],
                    status: .inQueue,
                    rawAmount: 15.99,
                    tip: 2.00,
                    totalAmount: 17.99,
                    deliveryAddress: "123 Main St",
                    estimatedDeliveryTime: Date().addingTimeInterval(1800) // 30 minutes from now
                ),
                onTap: {},
                onDismiss: {}
            )
            
            Spacer()
        }
    }
}

#Preview("In Progress") {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()
        
        VStack {
            // Preview for in-progress order
            OrderStatusBanner(
                order: Order(
                    user: User(id: "test-user-id", email: "test@u.northwestern.edu", firstName: "John", lastName: "Doe", phoneNumber: "123-456-7890"),
                    items: [],
                    status: .inProgress,
                    rawAmount: 15.99,
                    tip: 2.00,
                    totalAmount: 17.99,
                    deliveryAddress: "123 Main St",
                    estimatedDeliveryTime: Date().addingTimeInterval(600) // 10 minutes from now
                ),
                onTap: {},
                onDismiss: {}
            )
            
            Spacer()
        }
    }
}
