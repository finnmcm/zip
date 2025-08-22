import Foundation

/// Loads environment variables from a .env file
class EnvironmentLoader {
    static let shared = EnvironmentLoader()
    
    private var environmentVariables: [String: String] = [:]
    
    private init() {
        loadEnvironmentFile()
    }
    
    /// Loads environment variables from .env file
    private func loadEnvironmentFile() {
        guard let path = Bundle.main.path(forResource: ".env", ofType: nil) else {
            print("⚠️ .env file not found in bundle")
            return
        }
        
        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            parseEnvironmentContent(content)
        } catch {
            print("❌ Error reading .env file: \(error)")
        }
    }
    
    /// Parses the content of the .env file
    private func parseEnvironmentContent(_ content: String) {
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty lines and comments
            if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
                continue
            }
            
            // Parse key=value format
            if let separatorIndex = trimmedLine.firstIndex(of: "=") {
                let key = String(trimmedLine[..<separatorIndex]).trimmingCharacters(in: .whitespaces)
                let value = String(trimmedLine[trimmedLine.index(after: separatorIndex)...]).trimmingCharacters(in: .whitespaces)
                
                // Remove quotes if present
                let cleanValue = value.replacingOccurrences(of: "\"", with: "")
                    .replacingOccurrences(of: "'", with: "")
                
                environmentVariables[key] = cleanValue
                print("🔧 Loaded environment variable: \(key) = \(cleanValue.isEmpty ? "empty" : "set")")
            }
        }
    }
    
    /// Gets a value from the .env file
    func getValue(for key: String) -> String? {
        return environmentVariables[key]
    }
    
    /// Gets a value from the .env file with a fallback
    func getValue(for key: String, fallback: String) -> String {
        return environmentVariables[key] ?? fallback
    }
    
    /// Checks if a key exists in the .env file
    func hasKey(_ key: String) -> Bool {
        return environmentVariables[key] != nil
    }
    
    /// Gets all loaded environment variables
    func getAllVariables() -> [String: String] {
        return environmentVariables
    }
    
    /// Debug: Print all loaded variables
    func debugPrint() {
        print("🔍 Environment Variables from .env file:")
        for (key, value) in environmentVariables {
            let displayValue = key.contains("KEY") ? "Set (length: \(value.count))" : value
            print("  \(key): \(displayValue)")
        }
    }
}
