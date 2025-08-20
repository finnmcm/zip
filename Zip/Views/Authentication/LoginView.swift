//
//  LoginView.swift
//  Zip
//

import SwiftUI
import Inject

struct LoginView: View {
    @ObserveInjection var inject
    @EnvironmentObject private var viewModel: AuthViewModel
    @FocusState private var isEmailFieldFocused: Bool
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: AppMetrics.spacingLarge) {
                // Logo and Title Section
                VStack(spacing: AppMetrics.spacing) {
                    ZStack {
                        Circle()
                            .fill(AppColors.accent.opacity(0.1))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(AppColors.accent)
                    }
                    .scaleEffect(isEmailFieldFocused ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: isEmailFieldFocused)
                    
                    Text("Zip")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(AppColors.accent)
                    
                    Text("Fast campus delivery for Northwestern")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppMetrics.spacingLarge)
                }
                .padding(.top, AppMetrics.spacingLarge * 2)

                // Login Form
                VStack(spacing: AppMetrics.spacingLarge) {
                    VStack(alignment: .leading, spacing: AppMetrics.spacing) {
                        Text("Email Address")
                            .font(.headline)
                            .foregroundStyle(AppColors.textPrimary)
                        
                        TextField("yourname@u.northwestern.edu", text: $viewModel.email)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .focused($isEmailFieldFocused)
                            .padding()
                            .background(AppColors.secondaryBackground)
                            .cornerRadius(AppMetrics.cornerRadiusLarge)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppMetrics.cornerRadiusLarge)
                                    .stroke(isEmailFieldFocused ? AppColors.accent : Color.clear, lineWidth: 2)
                            )
                            .animation(.easeInOut(duration: 0.2), value: isEmailFieldFocused)

                        if let message = viewModel.errorMessage {
                            Text(message)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }

                    Button(action: {
                        Task { await viewModel.login() }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.right")
                                    .font(.headline)
                            }
                            Text(viewModel.isLoading ? "Signing In..." : "Continue")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isValidEmail ? AppColors.accent : .gray.opacity(0.3))
                        .foregroundColor(viewModel.isValidEmail ? .white : .gray)
                        .cornerRadius(AppMetrics.cornerRadiusLarge)
                        .scaleEffect(viewModel.isValidEmail ? 1.0 : 0.98)
                        .animation(.easeInOut(duration: 0.1), value: viewModel.isValidEmail)
                    }
                    .disabled(!viewModel.isValidEmail || viewModel.isLoading)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AppMetrics.spacingLarge)

                Spacer()

                // Footer
                VStack(spacing: AppMetrics.spacing) {
                    Text("Use your Northwestern email")
                        .font(.footnote)
                        .foregroundStyle(AppColors.textSecondary)
                    
                    Text("Secure • Fast • Student-focused")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary.opacity(0.7))
                }
                .padding(.bottom, AppMetrics.spacingLarge)
            }
        }
        .onTapGesture {
            isEmailFieldFocused = false
        }
        .enableInjection()
    }
}


