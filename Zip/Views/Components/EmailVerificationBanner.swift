//
//  EmailVerificationBanner.swift
//  Zip
//

import SwiftUI

struct EmailVerificationBanner: View {
    @State private var isVisible = false
    let currentUser: User?
    
    init(currentUser: User? = nil) {
        self.currentUser = currentUser
    }
    
    private var shouldShowBanner: Bool {
        guard let user = currentUser else { return false }
        return !user.verified
    }
    
    private var bannerTitle: String {
        return "Email Verification Required"
    }
    
    private var bannerMessage: String {
        return "Please check your email and click the verification link to complete your account setup and enable checkout."
    }
    
    var body: some View {
        let _ = print("🔍 EmailVerificationBanner: currentUser = \(String(describing: currentUser))")
        let _ = print("🔍 EmailVerificationBanner: shouldShowBanner = \(shouldShowBanner)")
        if shouldShowBanner {
            let _ = print("🔍 EmailVerificationBanner: Showing banner for user.verified = \(currentUser?.verified ?? false)")
            HStack(spacing: AppMetrics.spacing) {
                Image(systemName: "envelope.fill")
                    .foregroundColor(.white)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(bannerTitle)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(bannerMessage)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                Button(action: {
                    // TODO: Add resend verification email functionality
                    print("Resend verification email tapped")
                }) {
                    Text("Resend")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, AppMetrics.spacing)
                        .padding(.vertical, AppMetrics.spacingSmall)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(AppMetrics.cornerRadiusSmall)
                }
            }
            .padding(.horizontal, AppMetrics.spacingLarge)
            .padding(.vertical, AppMetrics.spacing)
            .background(AppColors.warning)
            .cornerRadius(AppMetrics.cornerRadiusLarge)
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            .padding(.horizontal, AppMetrics.spacingLarge)
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .opacity(isVisible ? 1.0 : 0.0)
            .offset(y: isVisible ? 0 : -20)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isVisible)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isVisible = true
                }
            }
        } else {
            let _ = print("🔍 EmailVerificationBanner: Hiding banner - user.verified = \(currentUser?.verified ?? false), currentUser exists: \(currentUser != nil)")
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()
        
        VStack {
            EmailVerificationBanner(currentUser: User(
                id: "test-id",
                email: "test@u.northwestern.edu",
                firstName: "Test",
                lastName: "User",
                phoneNumber: "1234567890",
                verified: false
            ))
            Spacer()
        }
    }
}
