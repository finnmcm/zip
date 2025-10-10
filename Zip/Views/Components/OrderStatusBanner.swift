//
//  OrderStatusBanner.swift
//  Zip
//

import SwiftUI

struct OrderStatusBanner: View {
    let order: Order
    let onDismiss: () -> Void
    let onOrderCancelled: ((Order) -> Void)?
    @ObservedObject var authViewModel: AuthViewModel
    
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
            return "scooter"
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
    private var statusSubtitle: String {
        switch order.status {
        case .inQueue:
            return "Finding the next available Zipper..."
        case .inProgress:
            return "You'll be notified when it arrives"
        default:
            return "Order status update"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main banner content
            ZStack {
                // NavigationLink for the main banner area
                NavigationLink(destination: OrderTrackingView(order: order, authViewModel: authViewModel, onOrderCancelled: onOrderCancelled)) {
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
                            
                            Text(statusSubtitle)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        Spacer()
                        
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
                .allowsHitTesting(true)
                
            }
            
        }
        .padding(.horizontal, AppMetrics.spacingLarge)
        .padding(.top, AppMetrics.spacing)
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
    let onBannerDismiss: () -> Void
    let onOrderCancelled: ((Order) -> Void)?
    @ObservedObject var authViewModel: AuthViewModel
    
    var body: some View {
        if let order = activeOrder, 
           [OrderStatus.inQueue, OrderStatus.inProgress].contains(order.status) {
            OrderStatusBanner(
                order: order,
                onDismiss: onBannerDismiss,
                onOrderCancelled: onOrderCancelled,
                authViewModel: authViewModel
            )
            .allowsHitTesting(true)
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
                    user: User(id: "test-user-id", email: "test@u.northwestern.edu", firstName: "John", lastName: "Doe", phoneNumber: "123-456-7890", storeCredit: 0.0, verified: true, fcmToken: nil),
                    items: [],
                    status: .inQueue,
                    rawAmount: 15.99,
                    tip: 2.00,
                    totalAmount: 17.99,
                    deliveryAddress: "123 Main St",
                    estimatedDeliveryTime: Date().addingTimeInterval(1800), // 30 minutes from now
                    firstName: "John",
                    lastName: "Doe"
                ),
                onDismiss: {},
                onOrderCancelled: nil,
                authViewModel: AuthViewModel()
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
                    user: User(id: "test-user-id", email: "test@u.northwestern.edu", firstName: "John", lastName: "Doe", phoneNumber: "123-456-7890", storeCredit: 0.0, verified: true, fcmToken: nil),
                    items: [],
                    status: .inProgress,
                    rawAmount: 15.99,
                    tip: 2.00,
                    totalAmount: 17.99,
                    deliveryAddress: "123 Main St",
                    estimatedDeliveryTime: Date().addingTimeInterval(600), // 10 minutes from now
                    firstName: "John",
                    lastName: "Doe"
                ),
                onDismiss: {},
                onOrderCancelled: nil,
                authViewModel: AuthViewModel()
            )
            
            Spacer()
        }
    }
}
