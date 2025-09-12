//
//  StripeService.swift
//  Zip
//

import Foundation
import Stripe
import StripePaymentSheet
import StripeApplePay
import PassKit
import Supabase
import UIKit
import ObjectiveC

struct PaymentResult {
    let success: Bool
    let transactionId: String?
    let errorMessage: String?
}

protocol StripeServiceProtocol {
    func processPayment(amount: Decimal, tip: Decimal, description: String?, orderId: UUID?) async -> PaymentResult
    func processApplePayPayment(amount: Decimal, tip: Decimal, description: String?, orderId: UUID?) async -> PaymentResult
    func isApplePayAvailable() -> Bool
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
    
    // MARK: - Apple Pay Methods
    
    func isApplePayAvailable() -> Bool {
        return PKPaymentAuthorizationController.canMakePayments()
    }
    
    func processApplePayPayment(amount: Decimal, tip: Decimal, description: String?, orderId: UUID? = nil) async -> PaymentResult {
        let total = (amount as NSDecimalNumber).doubleValue + (tip as NSDecimalNumber).doubleValue

        guard total > 0 else {
            return PaymentResult(success: false, transactionId: nil, errorMessage: "Amount must be greater than 0")
        }

        guard isApplePayAvailable() else {
            return PaymentResult(success: false, transactionId: nil, errorMessage: "Apple Pay is not available on this device")
        }

        // Create PaymentIntent via Supabase Edge Function
        guard let clientSecret = await createPaymentIntent(total: total, description: description, orderId: orderId) else {
            return PaymentResult(success: false, transactionId: nil, errorMessage: "Failed to create payment intent")
        }

        // Present Apple Pay
        let paymentResult = await presentApplePay(clientSecret: clientSecret, amount: total, description: description)
        return paymentResult
    }
    
    private func presentApplePay(clientSecret: String, amount: Double, description: String?) async -> PaymentResult {
        await withCheckedContinuation { continuation in
            // Create payment request
            let paymentRequest = StripeAPI.paymentRequest(withMerchantIdentifier: "merchant.com.finnmcm.zip", country: "US", currency: "USD")
            
            // Configure payment request
            let subtotal = amount
            paymentRequest.paymentSummaryItems = [
                PKPaymentSummaryItem(label: "Subtotal", amount: NSDecimalNumber(value: subtotal)),
                PKPaymentSummaryItem(label: description ?? "Zip Order", amount: NSDecimalNumber(value: amount))
            ]
            
            // Create and present Apple Pay controller
            let paymentController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
            let delegate = ApplePayDelegate(clientSecret: clientSecret) { result in
                continuation.resume(returning: result)
            }
            
            // Store delegate as strong reference to prevent deallocation
            objc_setAssociatedObject(paymentController, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            paymentController.delegate = delegate
            
            DispatchQueue.main.async {
                paymentController.present { success in
                    if !success {
                        continuation.resume(returning: PaymentResult(success: false, transactionId: nil, errorMessage: "Failed to present Apple Pay"))
                    }
                }
            }
        }
    }
}

// MARK: - Apple Pay Delegate

private class ApplePayDelegate: NSObject, PKPaymentAuthorizationControllerDelegate {
    private let clientSecret: String
    private let completion: (PaymentResult) -> Void
    
    init(clientSecret: String, completion: @escaping (PaymentResult) -> Void) {
        self.clientSecret = clientSecret
        self.completion = completion
    }
    
    func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        // Convert PKPayment to Stripe PaymentMethod
        STPAPIClient.shared.createPaymentMethod(with: payment) { paymentMethod, error in
            if let error = error {
                completion(PKPaymentAuthorizationResult(status: .failure, errors: [error]))
                return
            }
            
            guard let paymentMethod = paymentMethod else {
                completion(PKPaymentAuthorizationResult(status: .failure, errors: [NSError(domain: "StripeError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create payment method"])]))
                return
            }
            
            // Confirm payment with Stripe
            let paymentIntentParams = STPPaymentIntentParams(clientSecret: self.clientSecret)
            paymentIntentParams.paymentMethodId = paymentMethod.stripeId
            
            STPAPIClient.shared.confirmPaymentIntent(with: paymentIntentParams) { paymentIntent, error in
                if let error = error {
                    completion(PKPaymentAuthorizationResult(status: .failure, errors: [error]))
                } else if let paymentIntent = paymentIntent, paymentIntent.status == .succeeded {
                    self.completion(PaymentResult(success: true, transactionId: paymentIntent.stripeId, errorMessage: nil))
                    completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
                } else {
                    completion(PKPaymentAuthorizationResult(status: .failure, errors: [NSError(domain: "StripeError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Payment failed"])]))
                }
            }
        }
    }
    
    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss {
            // Controller is dismissed
        }
    }
}



