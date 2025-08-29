//
//  ZipApp.swift
//  Zip
//
//  Created by Finn McMillan on 8/19/25.
//

import SwiftUI
import Inject
import Stripe

@main
struct ZipApp: App {
    init() {
        #if DEBUG
        Bundle(path: "/Applications/InjectionIII.app/Contents/Resources/iOSInjection.bundle")?.load()
        #endif
        // Initialize Stripe publishable key
        let publishableKey = Configuration.shared.stripePublishableKey
        if !publishableKey.isEmpty && !publishableKey.contains("YOUR_") {
            STPAPIClient.shared.publishableKey = publishableKey
            print("✅ Stripe initialized with publishable key (length: \(publishableKey.count))")
        } else {
            print("⚠️ Stripe publishable key not configured. Payments will be disabled.")
        }
    }
    @ObserveInjection var inject
    
    var body: some Scene {
        
        WindowGroup {
           ContentView()
        //   ConfigurationStatusView()
                .enableInjection()  // Just once here
        }
    }
}
