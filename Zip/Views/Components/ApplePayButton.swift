//
//  ApplePayButton.swift
//  Zip
//

import SwiftUI
import PassKit

struct ApplePayButton: View {
    let action: () -> Void
    
    var body: some View {
        ApplePayButtonRepresentable(action: action)
            .frame(height: 50)
    }
}

struct ApplePayButtonRepresentable: UIViewRepresentable {
    let action: () -> Void
    
    func makeUIView(context: Context) -> PKPaymentButton {
        let button = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)
        button.addTarget(context.coordinator, action: #selector(Coordinator.buttonTapped), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: PKPaymentButton, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }
    
    class Coordinator: NSObject {
        let action: () -> Void
        
        init(action: @escaping () -> Void) {
            self.action = action
        }
        
        @objc func buttonTapped() {
            action()
        }
    }
}
