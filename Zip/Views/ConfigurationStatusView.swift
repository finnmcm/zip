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
                            if let envURL = ProcessInfo.processInfo.environment["SUPABASE_URL"], !envURL.isEmpty {
                                Text("From Environment")
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
                            
                            if let envKey = ProcessInfo.processInfo.environment["SUPABASE_KEY"], !envKey.isEmpty {
                                Text("From Environment")
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
                
                Section("Environment Variables") {
                    HStack {
                        Text("SUPABASE_URL")
                        Spacer()
                        if let envURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] {
                            Text(envURL.isEmpty ? "Empty" : "Set")
                                .foregroundColor(envURL.isEmpty ? .red : .green)
                        } else {
                            Text("Not Set")
                                .foregroundColor(.red)
                        }
                    }
                    
                    HStack {
                        Text("SUPABASE_KEY")
                        Spacer()
                        if let envKey = ProcessInfo.processInfo.environment["SUPABASE_KEY"] {
                            Text(envKey.isEmpty ? "Empty" : "Set (\(envKey.count) chars)")
                                .foregroundColor(envKey.isEmpty ? .red : .green)
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
                    
                    Button("Test Environment Variables") {
                        testEnvironmentVariables()
                    }
                    
                    Button("Test .env File Loading") {
                        testEnvFileLoading()
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
        
        Environment Variables:
        SUPABASE_URL: \(ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "Not Set")
        SUPABASE_KEY: \(ProcessInfo.processInfo.environment["SUPABASE_KEY"]?.isEmpty == false ? "Set (\(ProcessInfo.processInfo.environment["SUPABASE_KEY"]?.count ?? 0) chars)" : "Not Set")
        
        App Version: \(config.appVersion)
        Build Number: \(config.buildNumber)
        """
        
        UIPasteboard.general.string = configText
        
        // Show a brief toast or alert
        // In a real app, you might want to use a proper toast library
    }
    
    private func showDebugInfo() {
        let debugInfo = Configuration.shared.debugEnvironmentVariables()
        print(debugInfo)
        
        // You could also show this in an alert or sheet
        // For now, just print to console
    }
    
    private func testEnvironmentVariables() {
        let allEnvVars = ProcessInfo.processInfo.environment
        
        print("🔍 === ENVIRONMENT VARIABLES TEST ===")
        print("Total environment variables: \(allEnvVars.count)")
        
        // Check for Supabase variables specifically
        let supabaseVars = allEnvVars.filter { $0.key.contains("SUPABASE") }
        print("Supabase-related variables: \(supabaseVars.count)")
        
        if supabaseVars.isEmpty {
            print("❌ NO SUPABASE ENVIRONMENT VARIABLES FOUND!")
            print("This means the environment variables are not being passed to the app.")
            print("Possible causes:")
            print("1. Environment variables are only set for LaunchAction, not BuildAction")
            print("2. App is running from a build, not from Xcode")
            print("3. Scheme configuration is incorrect")
        } else {
            print("✅ Found Supabase environment variables:")
            for (key, value) in supabaseVars {
                let displayValue = key.contains("KEY") ? "Set (length: \(value.count))" : value
                print("  \(key): \(displayValue)")
            }
        }
        
        // Show current configuration values
        print("\n🔧 Current Configuration Values:")
        print("supabaseURL: \(Configuration.shared.supabaseURL)")
        print("supabaseAnonKey: \(Configuration.shared.supabaseAnonKey.isEmpty ? "Not set" : "Set (length: \(Configuration.shared.supabaseAnonKey.count))")")
        
        print("=== END TEST ===\n")
    }
    
    private func testEnvFileLoading() {
        print("🔍 === .ENV FILE LOADING TEST ===")
        
        // Test EnvironmentLoader
        let envLoader = EnvironmentLoader.shared
        envLoader.debugPrint()
        
        // Test specific values
        let supabaseURL = envLoader.getValue(for: "SUPABASE_URL")
        let supabaseKey = envLoader.getValue(for: "SUPABASE_KEY")
        
        print("\n🔧 .env File Values:")
        print("SUPABASE_URL: \(supabaseURL ?? "Not found")")
        print("SUPABASE_KEY: \(supabaseKey?.isEmpty == false ? "Set (length: \(supabaseKey?.count ?? 0))" : "Not found")")
        
        // Test Configuration integration
        print("\n🔧 Configuration Integration:")
        print("Final supabaseURL: \(Configuration.shared.supabaseURL)")
        print("Final supabaseAnonKey: \(Configuration.shared.supabaseAnonKey.isEmpty ? "Not set" : "Set (length: \(Configuration.shared.supabaseAnonKey.count))")")
        
        print("=== END .ENV TEST ===\n")
    }
}

#Preview {
    ConfigurationStatusView()
}
