//
//  StripeService.swift
//  Zip
//

import Foundation

struct PaymentResult {
    let success: Bool
    let transactionId: String
}

protocol StripeServiceProtocol {
    func processPayment(amount: Decimal) async throws -> PaymentResult
}

final class StripeService: StripeServiceProtocol {
    func processPayment(amount: Decimal) async throws -> PaymentResult {
        // Stubbed success for MVP
        return PaymentResult(success: true, transactionId: UUID().uuidString)
    }
}


