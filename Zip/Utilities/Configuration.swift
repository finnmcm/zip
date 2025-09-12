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
        // Read from Info.plist
        if let url = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String, !url.isEmpty {
            print("🔧 Configuration: Using SUPABASE_URL from Info.plist: \(url)")
            return url
        }
        
        print("⚠️ Configuration: SUPABASE_URL not found in Info.plist, using fallback")
        
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
        // Read from Info.plist
        if let key = Bundle.main.infoDictionary?["SUPABASE_KEY"] as? String, !key.isEmpty {
            print("🔧 Configuration: Using SUPABASE_KEY from Info.plist (length: \(key.count))")
            return key
        }
        
        print("⚠️ Configuration: SUPABASE_KEY not found in Info.plist, using fallback")
        
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
        // Read from Info.plist
        if let key = Bundle.main.infoDictionary?["STRIPE_PUBLISHABLE_KEY"] as? String, !key.isEmpty {
            print("🔧 Configuration: Using STRIPE_PUBLISHABLE_KEY from Info.plist (length: \(key.count))")
            return key
        }
        
        print("⚠️ Configuration: STRIPE_PUBLISHABLE_KEY not found in Info.plist, using fallback")
        
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
            errors.append("Supabase URL is not configured in Info.plist")
        }
        
        if supabaseAnonKey == "YOUR_DEV_SUPABASE_ANON_KEY" || supabaseAnonKey.isEmpty {
            errors.append("Supabase anonymous key is not configured in Info.plist")
        }
        
        // Check Stripe configuration
        if stripePublishableKey == "YOUR_DEV_STRIPE_PUBLISHABLE_KEY" || stripePublishableKey.isEmpty {
            errors.append("Stripe publishable key is not configured in Info.plist")
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
        let plistURL = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String ?? "Not set"
        let plistKey = Bundle.main.infoDictionary?["SUPABASE_KEY"] as? String ?? "Not set"
        let plistStripeKey = Bundle.main.infoDictionary?["STRIPE_PUBLISHABLE_KEY"] as? String ?? "Not set"
        
        return """
        🔧 Configuration Debug Info:
        Environment: \(environment.displayName)
        Supabase URL (Info.plist): \(plistURL)
        Supabase Key (Info.plist): \(plistKey.isEmpty ? "Not set" : "Set (length: \(plistKey.count))")
        Stripe Key (Info.plist): \(plistStripeKey.isEmpty ? "Not set" : "Set (length: \(plistStripeKey.count))")
        Final Supabase URL: \(supabaseURL)
        Final Supabase Key: \(supabaseAnonKey.isEmpty ? "Not set" : "Set (length: \(supabaseAnonKey.count))")
        Final Stripe Key: \(stripePublishableKey.isEmpty ? "Not set" : "Set (length: \(stripePublishableKey.count))")
        Configuration Valid: \(isConfigured)
        """
    }
    
    // MARK: - Info.plist Debug
    func debugInfoPlistConfiguration() -> String {
        let infoDict = Bundle.main.infoDictionary ?? [:]
        let supabaseURL = infoDict["SUPABASE_URL"] as? String ?? "Not set"
        let supabaseKey = infoDict["SUPABASE_KEY"] as? String ?? "Not set"
        let stripeKey = infoDict["STRIPE_PUBLISHABLE_KEY"] as? String ?? "Not set"
        
        var debugInfo = "🔍 Info.plist Configuration Debug:\n"
        debugInfo += "Total Info.plist keys: \(infoDict.count)\n\n"
        
        debugInfo += "✅ Configuration keys found in Info.plist:\n"
        debugInfo += "  SUPABASE_URL: \(supabaseURL)\n"
        debugInfo += "  SUPABASE_KEY: \(supabaseKey.isEmpty ? "Not set" : "Set (length: \(supabaseKey.count))")\n"
        debugInfo += "  STRIPE_PUBLISHABLE_KEY: \(stripeKey.isEmpty ? "Not set" : "Set (length: \(stripeKey.count))")\n\n"
        
        debugInfo += "🔧 Final Configuration Values:\n"
        debugInfo += "supabaseURL: \(self.supabaseURL)\n"
        debugInfo += "supabaseAnonKey: \(self.supabaseAnonKey.isEmpty ? "Not set" : "Set (length: \(self.supabaseAnonKey.count))")\n"
        debugInfo += "stripePublishableKey: \(self.stripePublishableKey.isEmpty ? "Not set" : "Set (length: \(self.stripePublishableKey.count))")\n"
        
        return debugInfo
    }
}
