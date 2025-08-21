//
//  ContentView.swift
//  Zip
//
//  Created by Finn McMillan on 8/19/25.
//

import SwiftUI
import Inject

struct ContentView: View {
    @ObserveInjection var inject
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var cartViewModel = CartViewModel()
    
    var body: some View {
        Group {
            if authViewModel.currentUser != nil {
                MainTabView(cartViewModel: cartViewModel)
                    .environmentObject(authViewModel)
            } else {
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
    }
}

#Preview {
    ContentView()
}
