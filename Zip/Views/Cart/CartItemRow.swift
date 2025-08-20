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
        HStack {
            VStack(alignment: .leading) {
                Text(item.productName)
                    .font(.headline)
                Text("$\(NSDecimalNumber(decimal: item.unitPrice).doubleValue, specifier: "%.2f")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack {
                Button("-") { decrement() }
                    .buttonStyle(.bordered)
                Text("\(item.quantity)")
                    .frame(minWidth: 30)
                Button("+") { increment() }
                    .buttonStyle(.bordered)
            }
            
            Button("Remove") { remove() }
                .foregroundColor(.red)
                .buttonStyle(.bordered)
        }
        .padding()
        .enableInjection()
    }
}


