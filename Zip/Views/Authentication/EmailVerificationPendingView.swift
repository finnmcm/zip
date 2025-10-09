//
//  EmailVerificationPendingView.swift
//  Zip
//

import SwiftUI

struct EmailVerificationPendingView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var isCheckingVerification = false
    @State private var checkCount = 0
    @State private var animationAmount = 1.0
    
    let email: String
    let password: String
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: AppMetrics.spacingLarge * 2) {
                Spacer()
                
                // Logo with pulse animation
                VStack(spacing: AppMetrics.spacingLarge) {
                    Image(systemName: "envelope.circle.fill")
                        .resizable()
                        .frame(width: 120, height: 120)
                        .foregroundStyle(AppColors.accent)
                        .scaleEffect(animationAmount)
                        .animation(
                            .easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                            value: animationAmount
                        )
                        .onAppear {
                            animationAmount = 1.2
                        }
                    
                    Text("Check Your Email")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    VStack(spacing: AppMetrics.spacing) {
                        Text("We sent a verification link to:")
                            .font(.body)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                        
                        Text(email)
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.accent)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                
                // Status indicator
                VStack(spacing: AppMetrics.spacing) {
                    HStack(spacing: AppMetrics.spacing) {
                        ProgressView()
                            .tint(AppColors.accent)
                        
                        Text(isCheckingVerification ? "Checking verification status..." : "Waiting for verification...")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Text("Once you verify your email, you'll be automatically logged in")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppMetrics.spacingLarge)
                }
                .padding()
                .background(AppColors.secondaryBackground)
                .cornerRadius(AppMetrics.cornerRadiusLarge)
                .padding(.horizontal, AppMetrics.spacingLarge)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: AppMetrics.spacing) {
                    // Resend verification button
                    Button(action: {
                        Task {
                            await authViewModel.resendVerificationEmail()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .font(.headline)
                            Text("Resend Verification Email")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.accent.opacity(0.1))
                        .foregroundColor(AppColors.accent)
                        .cornerRadius(AppMetrics.cornerRadiusLarge)
                    }
                    .buttonStyle(.plain)
                    .disabled(authViewModel.isLoading)
                    
                    // Manual check button
                    Button(action: {
                        Task {
                            isCheckingVerification = true
                            checkCount += 1
                            await checkVerificationAndLogin()
                            isCheckingVerification = false
                        }
                    }) {
                        HStack {
                            if isCheckingVerification {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark.circle")
                                    .font(.headline)
                            }
                            Text(isCheckingVerification ? "Checking..." : "I've Verified My Email")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.accent)
                        .foregroundColor(.white)
                        .cornerRadius(AppMetrics.cornerRadiusLarge)
                    }
                    .buttonStyle(.plain)
                    .disabled(isCheckingVerification)
                    
                    // Back to login
                    Button(action: {
                        Task {
                            // Sign out to go back to login
                            await authViewModel.logout()
                        }
                    }) {
                        Text("Back to Login")
                            .font(.footnote)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AppMetrics.spacingLarge)
                .padding(.bottom, AppMetrics.spacingLarge)
                
                // Error message
                if let errorMessage = authViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(errorMessage.contains("✅") ? .green : .red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppMetrics.spacingLarge)
                        .padding(.bottom, AppMetrics.spacing)
                }
            }
        }
        .onAppear {
            // Start auto-checking verification status
            startAutoVerificationCheck()
        }
    }
    
    // MARK: - Verification Logic
    
    /// Automatically checks verification status every 5 seconds
    private func startAutoVerificationCheck() {
        Task {
            // Initial delay
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            // Check every 5 seconds
            while !Task.isCancelled {
                await checkVerificationAndLogin()
                
                // If verified, stop checking (will be handled by login)
                if authViewModel.isAuthenticated {
                    break
                }
                
                // Wait 5 seconds before next check
                try? await Task.sleep(nanoseconds: 5_000_000_000)
            }
        }
    }
    
    /// Checks verification status and logs in if verified
    private func checkVerificationAndLogin() async {
        do {
            print("🔍 Checking verification status for: \(email)")
            let isVerified = try await AuthenticationService.shared.checkVerificationStatus(email: email)
            
            if isVerified {
                print("✅ Email verified! Logging in...")
                // User is verified, now sign them in
                authViewModel.email = email
                authViewModel.password = password
                await authViewModel.login()
            } else {
                print("⏳ Email not verified yet, will check again...")
            }
        } catch {
            print("❌ Error checking verification: \(error)")
            // Don't show error for failed checks, just retry
        }
    }
}

#Preview {
    EmailVerificationPendingView(
        email: "test@u.northwestern.edu",
        password: "testpass123"
    )
    .environmentObject(AuthViewModel())
}

