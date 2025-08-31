import SwiftUI
import Inject

struct OrderConfirmationView: View {
    @ObserveInjection var inject
    let order: Order?
    
    var body: some View {
        VStack(spacing: AppMetrics.spacingLarge) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)
            
            Text("Order Placed!")
                .font(.title.bold())
            
            if let order = order {
                Text("Order #\(String(order.id.uuidString.prefix(6)))  •  $\(String(format: "%.2f", NSDecimalNumber(decimal: order.totalAmount).doubleValue))")
                    .foregroundStyle(AppColors.textSecondary)
            }
            
            Text("Estimated delivery: 20-30 minutes")
                .foregroundStyle(AppColors.textSecondary)
            
            Text("Thank you for choosing Zip!")
                .font(.headline)
                .foregroundStyle(AppColors.accent)
        }
        .padding()
        .enableInjection()
    }
}