//
//  ContentView.swift
//  Zip
//
//  Created by Finn McMillan on 8/19/25.
//

import SwiftUI
import SwiftData
import Inject

struct ContentView: View {
    @ObserveInjection var inject
    @Environment(\.modelContext) private var context
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        Group {
            if authViewModel.currentUser != nil {
                MainTabView()
                    .environmentObject(authViewModel)
            } else {
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
        .onAppear {
            // Initialize with the actual context from environment
            if authViewModel.context == nil {
                authViewModel.updateContext(context)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: User.self)
}
