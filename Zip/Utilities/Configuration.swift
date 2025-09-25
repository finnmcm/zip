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
    
    // MARK: - Firebase Configuration
    var firebaseAPIKey: String {
        // Read from Info.plist
        if let key = Bundle.main.infoDictionary?["FIREBASE_API_KEY"] as? String, !key.isEmpty {
            print("🔧 Configuration: Using FIREBASE_API_KEY from Info.plist (length: \(key.count))")
            return key
        }
        
        print("⚠️ Configuration: FIREBASE_API_KEY not found in Info.plist, using fallback")
        
        // Fallbacks
        switch environment {
        case .development:
            return "YOUR_DEV_FIREBASE_API_KEY"
        case .production:
            return "YOUR_PROD_FIREBASE_API_KEY"
        case .testing:
            return "YOUR_TEST_FIREBASE_API_KEY"
        }
    }
    
    var firebaseSenderID: String {
        // Read from Info.plist
        if let senderID = Bundle.main.infoDictionary?["FIREBASE_SENDER_ID"] as? String, !senderID.isEmpty {
            print("🔧 Configuration: Using FIREBASE_SENDER_ID from Info.plist: \(senderID)")
            return senderID
        }
        
        print("⚠️ Configuration: FIREBASE_SENDER_ID not found in Info.plist, using fallback")
        
        // Fallbacks
        switch environment {
        case .development:
            return "YOUR_DEV_FIREBASE_SENDER_ID"
        case .production:
            return "YOUR_PROD_FIREBASE_SENDER_ID"
        case .testing:
            return "YOUR_TEST_FIREBASE_SENDER_ID"
        }
    }
    
    var firebaseProjectID: String {
        // Read from Info.plist
        if let projectID = Bundle.main.infoDictionary?["FIREBASE_PROJECT_ID"] as? String, !projectID.isEmpty {
            print("🔧 Configuration: Using FIREBASE_PROJECT_ID from Info.plist: \(projectID)")
            return projectID
        }
        
        print("⚠️ Configuration: FIREBASE_PROJECT_ID not found in Info.plist, using fallback")
        
        // Fallbacks
        switch environment {
        case .development:
            return "YOUR_DEV_FIREBASE_PROJECT_ID"
        case .production:
            return "YOUR_PROD_FIREBASE_PROJECT_ID"
        case .testing:
            return "YOUR_TEST_FIREBASE_PROJECT_ID"
        }
    }
    
    var firebaseGoogleAppID: String {
        // Read from Info.plist
        if let appID = Bundle.main.infoDictionary?["FIREBASE_GOOGLE_APP_ID"] as? String, !appID.isEmpty {
            print("🔧 Configuration: Using FIREBASE_GOOGLE_APP_ID from Info.plist (length: \(appID.count))")
            return appID
        }
        
        print("⚠️ Configuration: FIREBASE_GOOGLE_APP_ID not found in Info.plist, using fallback")
        
        // Fallbacks
        switch environment {
        case .development:
            return "YOUR_DEV_FIREBASE_GOOGLE_APP_ID"
        case .production:
            return "YOUR_PROD_FIREBASE_GOOGLE_APP_ID"
        case .testing:
            return "YOUR_TEST_FIREBASE_GOOGLE_APP_ID"
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
        
        // Check Firebase configuration
        if firebaseAPIKey == "YOUR_DEV_FIREBASE_API_KEY" || firebaseAPIKey.isEmpty {
            errors.append("Firebase API key is not configured in Info.plist")
        }
        
        if firebaseSenderID == "YOUR_DEV_FIREBASE_SENDER_ID" || firebaseSenderID.isEmpty {
            errors.append("Firebase sender ID is not configured in Info.plist")
        }
        
        if firebaseProjectID == "YOUR_DEV_FIREBASE_PROJECT_ID" || firebaseProjectID.isEmpty {
            errors.append("Firebase project ID is not configured in Info.plist")
        }
        
        if firebaseGoogleAppID == "YOUR_DEV_FIREBASE_GOOGLE_APP_ID" || firebaseGoogleAppID.isEmpty {
            errors.append("Firebase Google App ID is not configured in Info.plist")
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
