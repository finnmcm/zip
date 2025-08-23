//
//  String+Validation.swift
//  Zip
//

import Foundation

extension String {
    
    // MARK: - Email Validation
    var isValidNorthwesternEmail: Bool {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.lowercased().hasSuffix("@u.northwestern.edu") || 
               trimmed.lowercased().hasSuffix("@northwestern.edu")
    }
    
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    // MARK: - Password Validation
    var isValidPassword: Bool {
        // At least 8 characters
        guard self.count >= 8 else { return false }
        
        // Contains at least one letter and one number
        let hasLetter = self.rangeOfCharacter(from: .letters) != nil
        let hasNumber = self.rangeOfCharacter(from: .decimalDigits) != nil
        
        return hasLetter && hasNumber
    }
    
    // MARK: - Phone Number Validation
    var isValidPhoneNumber: Bool {
        let digits = self.filter { $0.isNumber }
        return digits.count >= 10 && digits.count <= 15
    }
    
    // MARK: - Name Validation
    var isValidName: Bool {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 2 && trimmed.count <= 50
    }
    
    // MARK: - Utility
    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var isEmptyOrWhitespace: Bool {
        return self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
