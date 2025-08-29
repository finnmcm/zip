//
//  StripeService.swift
//  Zip
//

import Foundation
import Stripe
import StripePaymentSheet
import Supabase
import UIKit

struct PaymentResult {
    let success: Bool
    let transactionId: String?
    let errorMessage: String?
}

protocol StripeServiceProtocol {
    func processPayment(amount: Decimal, tip: Decimal, description: String?, orderId: UUID?) async -> PaymentResult
}

final class StripeService: StripeServiceProtocol {
    private let configuration = Configuration.shared
    private var supabase: SupabaseClient?

    init() {
        if let url = URL(string: configuration.supabaseURL), !configuration.supabaseAnonKey.isEmpty, configuration.supabaseAnonKey != "YOUR_DEV_SUPABASE_ANON_KEY" {
            self.supabase = SupabaseClient(supabaseURL: url, supabaseKey: configuration.supabaseAnonKey)
        } else {
            self.supabase = nil
        }
    }

    func processPayment(amount: Decimal, tip: Decimal, description: String?, orderId: UUID? = nil) async -> PaymentResult {
        let total = (amount as NSDecimalNumber).doubleValue + (tip as NSDecimalNumber).doubleValue

        guard total > 0 else {
            return PaymentResult(success: false, transactionId: nil, errorMessage: "Amount must be greater than 0")
        }

        // Create PaymentIntent via Supabase Edge Function
        guard let clientSecret = await createPaymentIntent(total: total, description: description, orderId: orderId) else {
            return PaymentResult(success: false, transactionId: nil, errorMessage: "Failed to create payment intent")
        }

        // Present PaymentSheet
        let paymentResult = await presentPaymentSheet(clientSecret: clientSecret)
        return paymentResult
    }

    private func createPaymentIntent(total: Double, description: String?, orderId: UUID? = nil) async -> String? {
        guard let supabase = supabase else {
            print("❌ Supabase client not configured for payments")
            return nil
        }
        do {
            struct Request: Codable { 
                let amount: Double; 
                let currency: String; 
                let description: String?;
                let metadata: [String: String]?
            }
            struct Response: Codable { let clientSecret: String }
            
            var metadata: [String: String]?
            if let orderId = orderId {
                metadata = ["order_id": orderId.uuidString]
            }
            
            let req = Request(amount: total, currency: "usd", description: description, metadata: metadata)
            
            let result: Response = try await supabase.functions.invoke(
                "create-payment-intent",
                options: FunctionInvokeOptions(body: req)
            )
            
            print("✅ Payment intent created successfully with client secret")
            return result.clientSecret
        } catch {
            print("❌ Error invoking create-payment-intent: \(error)")
            return nil
        }
    }

    private func presentPaymentSheet(clientSecret: String) async -> PaymentResult {
        await withCheckedContinuation { continuation in
            var configuration = PaymentSheet.Configuration()
            configuration.merchantDisplayName = self.configuration.appName
            configuration.allowsDelayedPaymentMethods = false

            let paymentSheet = PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: configuration)

            DispatchQueue.main.async {
                guard let topVC = UIApplication.shared.topMostViewController() else {
                    continuation.resume(returning: PaymentResult(success: false, transactionId: nil, errorMessage: "Unable to present payment UI"))
                    return
                }

                paymentSheet.present(from: topVC) { result in
                    switch result {
                    case .completed:
                        continuation.resume(returning: PaymentResult(success: true, transactionId: nil, errorMessage: nil))
                    case .failed(let error):
                        continuation.resume(returning: PaymentResult(success: false, transactionId: nil, errorMessage: error.localizedDescription))
                    case .canceled:
                        continuation.resume(returning: PaymentResult(success: false, transactionId: nil, errorMessage: "Canceled"))
                    }
                }
            }
        }
    }
}


