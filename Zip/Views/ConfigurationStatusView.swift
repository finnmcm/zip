//
//  ConfigurationStatusView.swift
//  Zip
//

import SwiftUI

struct ConfigurationStatusView: View {
    @State private var configurationStatus: String = ""
    @State private var isConfigured: Bool = false
    @State private var configurationErrors: [String] = []
    
    var body: some View {
        NavigationView {
            List {
                Section("Configuration Status") {
                    HStack {
                        Image(systemName: isConfigured ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(isConfigured ? .green : .red)
                        
                        VStack(alignment: .leading) {
                            Text(isConfigured ? "Configured" : "Not Configured")
                                .font(.headline)
                            Text(configurationStatus)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if !configurationErrors.isEmpty {
                    Section("Configuration Errors") {
                        ForEach(configurationErrors, id: \.self) { error in
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text(error)
                            }
                        }
                    }
                }
                
                Section("Environment") {
                    HStack {
                        Text("Current Environment")
                        Spacer()
                        Text(Configuration.shared.currentEnvironment.displayName)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text(Configuration.shared.appVersion)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build Number")
                        Spacer()
                        Text(Configuration.shared.buildNumber)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Supabase Configuration") {
                    HStack {
                        Text("Supabase URL")
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(Configuration.shared.supabaseURL)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            if let plistURL = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String, !plistURL.isEmpty {
                                Text("From Info.plist")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            } else {
                                Text("From Fallback")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    
                    HStack {
                        Text("Anon Key")
                        Spacer()
                        VStack(alignment: .trailing) {
                            if Configuration.shared.supabaseAnonKey.isEmpty {
                                Text("Not Set")
                                    .foregroundColor(.red)
                            } else if Configuration.shared.supabaseAnonKey == "YOUR_DEV_SUPABASE_ANON_KEY" {
                                Text("Default Placeholder")
                                    .foregroundColor(.orange)
                            } else {
                                Text("Set (length: \(Configuration.shared.supabaseAnonKey.count))")
                                    .foregroundColor(.green)
                            }
                            
                            if let plistKey = Bundle.main.infoDictionary?["SUPABASE_KEY"] as? String, !plistKey.isEmpty {
                                Text("From Info.plist")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            } else {
                                Text("From Fallback")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                
                Section("Stripe Configuration") {
                    HStack {
                        Text("Publishable Key")
                        Spacer()
                        VStack(alignment: .trailing) {
                            if Configuration.shared.stripePublishableKey.isEmpty {
                                Text("Not Set")
                                    .foregroundColor(.red)
                            } else if Configuration.shared.stripePublishableKey == "YOUR_DEV_STRIPE_PUBLISHABLE_KEY" {
                                Text("Default Placeholder")
                                    .foregroundColor(.orange)
                            } else {
                                Text("Set (length: \(Configuration.shared.stripePublishableKey.count))")
                                    .foregroundColor(.green)
                            }
                            
                            if let plistKey = Bundle.main.infoDictionary?["STRIPE_PUBLISHABLE_KEY"] as? String, !plistKey.isEmpty {
                                Text("From Info.plist")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            } else {
                                Text("From Fallback")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                
                Section("Info.plist Values") {
                    HStack {
                        Text("SUPABASE_URL")
                        Spacer()
                        if let plistURL = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String {
                            Text(plistURL.isEmpty ? "Empty" : "Set")
                                .foregroundColor(plistURL.isEmpty ? .red : .green)
                        } else {
                            Text("Not Set")
                                .foregroundColor(.red)
                        }
                    }
                    
                    HStack {
                        Text("SUPABASE_KEY")
                        Spacer()
                        if let plistKey = Bundle.main.infoDictionary?["SUPABASE_KEY"] as? String {
                            Text(plistKey.isEmpty ? "Empty" : "Set (\(plistKey.count) chars)")
                                .foregroundColor(plistKey.isEmpty ? .red : .green)
                        } else {
                            Text("Not Set")
                                .foregroundColor(.red)
                        }
                    }
                    
                    HStack {
                        Text("STRIPE_PUBLISHABLE_KEY")
                        Spacer()
                        if let plistStripeKey = Bundle.main.infoDictionary?["STRIPE_PUBLISHABLE_KEY"] as? String {
                            Text(plistStripeKey.isEmpty ? "Empty" : "Set (\(plistStripeKey.count) chars)")
                                .foregroundColor(plistStripeKey.isEmpty ? .red : .green)
                        } else {
                            Text("Not Set")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section("Actions") {
                    Button("Refresh Status") {
                        refreshConfigurationStatus()
                    }
                    
                    Button("Show Debug Info") {
                        showDebugInfo()
                    }
                    
                    Button("Test Info.plist Loading") {
                        testInfoPlistLoading()
                    }
                    
                    Button("Copy Configuration") {
                        copyConfigurationToClipboard()
                    }
                }
            }
            .navigationTitle("Configuration")
            .onAppear {
                refreshConfigurationStatus()
            }
        }
    }
    
    private func refreshConfigurationStatus() {
        let config = Configuration.shared
        isConfigured = config.isConfigured
        configurationStatus = config.configurationStatus
        configurationErrors = config.validateConfiguration()
    }
    
    private func copyConfigurationToClipboard() {
        let config = Configuration.shared
        let configText = """
        Configuration Status: \(config.configurationStatus)
        
        Environment: \(config.currentEnvironment.displayName)
        Supabase URL: \(config.supabaseURL)
        Anon Key: \(config.supabaseAnonKey.isEmpty ? "Not Set" : "Set (length: \(config.supabaseAnonKey.count))")
        Stripe Key: \(config.stripePublishableKey.isEmpty ? "Not Set" : "Set (length: \(config.stripePublishableKey.count))")
        
        Info.plist Values:
        SUPABASE_URL: \(Bundle.main.infoDictionary?["SUPABASE_URL"] as? String ?? "Not Set")
        SUPABASE_KEY: \((Bundle.main.infoDictionary?["SUPABASE_KEY"] as? String)?.isEmpty == false ? "Set (\((Bundle.main.infoDictionary?["SUPABASE_KEY"] as? String)?.count ?? 0) chars)" : "Not Set")
        STRIPE_PUBLISHABLE_KEY: \((Bundle.main.infoDictionary?["STRIPE_PUBLISHABLE_KEY"] as? String)?.isEmpty == false ? "Set (\((Bundle.main.infoDictionary?["STRIPE_PUBLISHABLE_KEY"] as? String)?.count ?? 0) chars)" : "Not Set")
        
        App Version: \(config.appVersion)
        Build Number: \(config.buildNumber)
        """
        
        UIPasteboard.general.string = configText
        
        // Show a brief toast or alert
        // In a real app, you might want to use a proper toast library
    }
    
    private func showDebugInfo() {
        let debugInfo = Configuration.shared.debugInfoPlistConfiguration()
        print(debugInfo)
        
        // You could also show this in an alert or sheet
        // For now, just print to console
    }
    
    private func testInfoPlistLoading() {
        print("🔍 === INFO.PLIST LOADING TEST ===")
        
        let infoDict = Bundle.main.infoDictionary ?? [:]
        print("Total Info.plist keys: \(infoDict.count)")
        
        // Test specific configuration keys
        let supabaseURL = infoDict["SUPABASE_URL"] as? String
        let supabaseKey = infoDict["SUPABASE_KEY"] as? String
        let stripeKey = infoDict["STRIPE_PUBLISHABLE_KEY"] as? String
        
        // Test Configuration integration
        print("\n🔧 Configuration Integration:")
        print("Final supabaseURL: \(Configuration.shared.supabaseURL)")
        print("Final supabaseAnonKey: \(Configuration.shared.supabaseAnonKey.isEmpty ? "Not set" : "Set (length: \(Configuration.shared.supabaseAnonKey.count))")")
        print("Final stripePublishableKey: \(Configuration.shared.stripePublishableKey.isEmpty ? "Not set" : "Set (length: \(Configuration.shared.stripePublishableKey.count))")")
        
        print("=== END INFO.PLIST TEST ===\n")
    }
}

#Preview {
    ConfigurationStatusView()
}
