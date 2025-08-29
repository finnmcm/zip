//
//  Configuration.swift
//  Zip
//

import Foundation

/// Configuration manager for environment-specific settings
final class Configuration {
    
    // MARK: - Singleton
    static let shared = Configuration()
    
    // MARK: - Properties
    private let environment: Environment
    
    // MARK: - Initialization
    private init() {
        #if DEBUG
        self.environment = .development
        #else
        self.environment = .production
        #endif
    }
    
    // MARK: - Environment
    enum Environment: String {
        case development = "development"
        case production = "production"
        case testing = "testing"
        
        var displayName: String {
            switch self {
            case .development:
                return "Development"
            case .production:
                return "Production"
            case .testing:
                return "Testing"
            }
        }
    }
    
    // MARK: - Supabase Configuration
    var supabaseURL: String {
        // First try to read from environment variables (Xcode run scheme)
        if let envURL = ProcessInfo.processInfo.environment["SUPABASE_URL"], !envURL.isEmpty {
            print("🔧 Configuration: Using SUPABASE_URL from environment: \(envURL)")
            return envURL
        }
        
        // Second try: read from .env file
        if let envURL = EnvironmentLoader.shared.getValue(for: "SUPABASE_URL"), !envURL.isEmpty {
            print("🔧 Configuration: Using SUPABASE_URL from .env file: \(envURL)")
            return envURL
        }
        
        print("⚠️ Configuration: SUPABASE_URL not found in environment or .env file, using fallback")
        
        // Fallback to environment-specific configuration
        switch environment {
        case .development:
            return "YOUR_DEV_SUPABASE_URL"
        case .production:
            return "YOUR_PROD_SUPABASE_URL"
        case .testing:
            return "YOUR_TEST_SUPABASE_URL"
        }
    }
    
    var supabaseAnonKey: String {
        // First try to read from environment variables (Xcode run scheme)
        if let envKey = ProcessInfo.processInfo.environment["SUPABASE_KEY"], !envKey.isEmpty {
            print("🔧 Configuration: Using SUPABASE_KEY from environment (length: \(envKey.count))")
            return envKey
        }
        
        // Second try: read from .env file
        if let envKey = EnvironmentLoader.shared.getValue(for: "SUPABASE_KEY"), !envKey.isEmpty {
            print("🔧 Configuration: Using SUPABASE_KEY from .env file (length: \(envKey.count))")
            return envKey
        }
        
        print("⚠️ Configuration: SUPABASE_KEY not found in environment or .env file, using fallback")
        
        // Fallback to environment-specific configuration
        switch environment {
        case .development:
            return "YOUR_DEV_SUPABASE_ANON_KEY"
        case .production:
            return "YOUR_PROD_SUPABASE_ANON_KEY"
        case .testing:
            return "YOUR_TEST_SUPABASE_ANON_KEY"
        }
    }
    
    var supabaseServiceRoleKey: String {
        switch environment {
        case .development:
            return "YOUR_DEV_SUPABASE_SERVICE_ROLE_KEY"
        case .production:
            return "YOUR_PROD_SUPABASE_SERVICE_ROLE_KEY"
        case .testing:
            return "YOUR_TEST_SUPABASE_SERVICE_ROLE_KEY"
        }
    }
    
    // MARK: - Stripe Configuration
    var stripePublishableKey: String {
        // Prefer environment variable or .env
        if let key = ProcessInfo.processInfo.environment["STRIPE_PUBLISHABLE_KEY"], !key.isEmpty {
            return key
        }
        if let key = EnvironmentLoader.shared.getValue(for: "STRIPE_PUBLISHABLE_KEY"), !key.isEmpty {
            return key
        }
        // Fallbacks
        switch environment {
        case .development:
            return "YOUR_DEV_STRIPE_PUBLISHABLE_KEY"
        case .production:
            return "YOUR_PROD_STRIPE_PUBLISHABLE_KEY"
        case .testing:
            return "YOUR_TEST_STRIPE_PUBLISHABLE_KEY"
        }
    }
    
    var stripeSecretKey: String {
        switch environment {
        case .development:
            return "YOUR_DEV_STRIPE_SECRET_KEY"
        case .production:
            return "YOUR_PROD_STRIPE_SECRET_KEY"
        case .testing:
            return "YOUR_TEST_STRIPE_SECRET_KEY"
        }
    }
    
    // MARK: - App Configuration
    var appName: String {
        return "Zip"
    }
    
    var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    var buildNumber: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var currentEnvironment: Environment {
        return environment
    }
    
    // MARK: - Feature Flags
    var isDebugMode: Bool {
        return environment == .development
    }
    
    var isProductionMode: Bool {
        return environment == .production
    }
    
    var isTestingMode: Bool {
        return environment == .testing
    }
    
    // MARK: - Validation
    func validateConfiguration() -> [String] {
        var errors: [String] = []
        
        // Check Supabase configuration
        if supabaseURL == "YOUR_DEV_SUPABASE_URL" || supabaseURL.isEmpty {
            errors.append("Supabase URL is not configured")
        }
        
        if supabaseAnonKey == "YOUR_DEV_SUPABASE_ANON_KEY" || supabaseAnonKey.isEmpty {
            errors.append("Supabase anonymous key is not configured")
        }
        
        // Check Stripe configuration
        if stripePublishableKey == "YOUR_DEV_STRIPE_PUBLISHABLE_KEY" || stripePublishableKey.isEmpty {
            errors.append("Stripe publishable key is not configured")
        }
        
        return errors
    }
    
    // MARK: - Configuration Status
    var isConfigured: Bool {
        return validateConfiguration().isEmpty
    }
    
    var configurationStatus: String {
        if isConfigured {
            return "✅ Configuration is valid"
        } else {
            let errors = validateConfiguration()
            return "❌ Configuration errors: \(errors.joined(separator: ", "))"
        }
    }
    
    // MARK: - Debug Information
    func debugConfiguration() -> String {
        let envURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "Not set"
        let envKey = ProcessInfo.processInfo.environment["SUPABASE_KEY"] ?? "Not set"
        
        return """
        🔧 Configuration Debug Info:
        Environment: \(environment.displayName)
        Supabase URL (env): \(envURL)
        Supabase Key (env): \(envKey.isEmpty ? "Not set" : "Set (length: \(envKey.count))")
        Final Supabase URL: \(supabaseURL)
        Final Supabase Key: \(supabaseAnonKey.isEmpty ? "Not set" : "Set (length: \(supabaseAnonKey.count))")
        Configuration Valid: \(isConfigured)
        """
    }
    
    // MARK: - Environment Variable Debug
    func debugEnvironmentVariables() -> String {
        let allEnvVars = ProcessInfo.processInfo.environment
        let supabaseVars = allEnvVars.filter { $0.key.contains("SUPABASE") }
        
        var debugInfo = "🔍 Environment Variables Debug:\n"
        debugInfo += "Total environment variables: \(allEnvVars.count)\n"
        debugInfo += "Supabase-related variables: \(supabaseVars.count)\n\n"
        
        if supabaseVars.isEmpty {
            debugInfo += "❌ No Supabase environment variables found!\n"
            debugInfo += "This usually means:\n"
            debugInfo += "1. Environment variables are not set in the scheme\n"
            debugInfo += "2. App is running from build, not from Xcode\n"
            debugInfo += "3. Scheme configuration is incorrect\n\n"
        } else {
            debugInfo += "✅ Found Supabase environment variables:\n"
            for (key, value) in supabaseVars {
                let displayValue = key.contains("KEY") ? "Set (length: \(value.count))" : value
                debugInfo += "  \(key): \(displayValue)\n"
            }
        }
        
        debugInfo += "\n🔧 Current Configuration Values:\n"
        debugInfo += "supabaseURL: \(supabaseURL)\n"
        debugInfo += "supabaseAnonKey: \(supabaseAnonKey.isEmpty ? "Not set" : "Set (length: \(supabaseAnonKey.count))")\n"
        
        return debugInfo
    }
}
