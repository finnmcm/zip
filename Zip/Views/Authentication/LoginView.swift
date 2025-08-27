//
//  LoginView.swift
//  Zip
//

import SwiftUI
import Inject

struct LoginView: View {
    @ObserveInjection var inject
    @EnvironmentObject private var viewModel: AuthViewModel
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case firstName, lastName, email, phoneNumber, password, confirmPassword
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppMetrics.spacingLarge) {
                    LogoSection(focusedField: focusedField)
                    
                    ModeToggleView(viewModel: viewModel)
                    
                    FormSection(viewModel: viewModel, focusedField: _focusedField)
                    
                    Spacer()
                    
                    FooterSection()
                }
            }
        }
        .onTapGesture {
            focusedField = nil
        }
        .enableInjection()
    }
}

// MARK: - Logo Section
private struct LogoSection: View {
    let focusedField: LoginView.Field?
    
    var body: some View {
        VStack(spacing: AppMetrics.spacing) {
            ZStack {
                Image(AppImages.logo)
                .resizable()
                .frame(width: 100, height: 100)
                       // .clipShape(Circle())
                   // .foregroundStyle(AppColors.accent)
            }
            .scaleEffect(focusedField != nil ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: focusedField)
            
            Text("Zip")
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(AppColors.accent)
            
            Text("Rapid College Delivery - Cheaper, Faster, Smoother")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppMetrics.spacingLarge)
        }
        .padding(.top, AppMetrics.spacingLarge * 2)
    }
}

// MARK: - Mode Toggle
private struct ModeToggleView: View {
    @ObservedObject var viewModel: AuthViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: { viewModel.toggleMode() }) {
                Text("Sign In")
                    .font(.headline)
                    .foregroundStyle(viewModel.isSignUpMode ? AppColors.textSecondary : AppColors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppMetrics.spacing)
                    .background(viewModel.isSignUpMode ? AppColors.secondaryBackground : AppColors.accent.opacity(0.1))
            }
            .buttonStyle(.plain)
            
            Button(action: { viewModel.toggleMode() }) {
                Text("Sign Up")
                    .font(.headline)
                    .foregroundStyle(viewModel.isSignUpMode ? AppColors.accent : AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppMetrics.spacing)
                    .background(viewModel.isSignUpMode ? AppColors.accent.opacity(0.1) : AppColors.secondaryBackground)
            }
            .buttonStyle(.plain)
        }
        .background(AppColors.secondaryBackground)
        .cornerRadius(AppMetrics.cornerRadiusLarge)
        .padding(.horizontal, AppMetrics.spacingLarge)
    }
}

// MARK: - Form Section
private struct FormSection: View {
    @ObservedObject var viewModel: AuthViewModel
    @FocusState var focusedField: LoginView.Field?
    
    var body: some View {
        VStack(spacing: AppMetrics.spacingLarge) {
            if viewModel.isSignUpMode {
                SignUpForm(viewModel: viewModel, focusedField: _focusedField)
            } else {
                SignInForm(viewModel: viewModel, focusedField: _focusedField)
            }
            
            // Error Message
            if let message = viewModel.errorMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Action Button
            ActionButton(viewModel: viewModel)
        }
        .padding(.horizontal, AppMetrics.spacingLarge)
    }
}

// MARK: - Sign Up Form
private struct SignUpForm: View {
    @ObservedObject var viewModel: AuthViewModel
    @FocusState var focusedField: LoginView.Field?
    
    var body: some View {
        VStack(spacing: AppMetrics.spacingLarge) {
            // Name Fields
            HStack(spacing: AppMetrics.spacing) {
                FormField(
                    title: "First Name",
                    text: $viewModel.firstName,
                    placeholder: "First Name",
                    field: .firstName,
                    focusedField: _focusedField,
                    textContentType: .givenName
                )
                
                FormField(
                    title: "Last Name",
                    text: $viewModel.lastName,
                    placeholder: "Last Name",
                    field: .lastName,
                    focusedField: _focusedField,
                    textContentType: .familyName
                )
            }
            
            // Email Field
            FormField(
                title: "Email Address",
                text: $viewModel.email,
                placeholder: "yourname@u.northwestern.edu",
                field: .email,
                focusedField: _focusedField,
                textContentType: .emailAddress,
                keyboardType: .emailAddress
            )
            
            // Phone Number Field
            FormField(
                title: "Phone Number",
                text: $viewModel.phoneNumber,
                placeholder: "(123) 456-7890",
                field: .phoneNumber,
                focusedField: _focusedField,
                textContentType: .telephoneNumber,
                keyboardType: .phonePad
            )
            
            // Password Fields
            FormField(
                title: "Password",
                text: $viewModel.password,
                placeholder: "Password (min 8 characters)",
                field: .password,
                focusedField: _focusedField,
                textContentType: .newPassword,
                isSecure: true
            )
            
            FormField(
                title: "Confirm Password",
                text: $viewModel.confirmPassword,
                placeholder: "Confirm Password",
                field: .confirmPassword,
                focusedField: _focusedField,
                textContentType: .newPassword,
                isSecure: true
            )
        }
    }
}

// MARK: - Sign In Form
private struct SignInForm: View {
    @ObservedObject var viewModel: AuthViewModel
    @FocusState var focusedField: LoginView.Field?
    
    var body: some View {
        VStack(spacing: AppMetrics.spacingLarge) {
            FormField(
                title: "Email Address",
                text: $viewModel.email,
                placeholder: "yourname@u.northwestern.edu",
                field: .email,
                focusedField: _focusedField,
                textContentType: .emailAddress,
                keyboardType: .emailAddress
            )
            
            FormField(
                title: "Password",
                text: $viewModel.password,
                placeholder: "Password",
                field: .password,
                focusedField: _focusedField,
                textContentType: .password,
                isSecure: true
            )
            
            // Forgot Password Button
            HStack {
                Spacer()
                Button("Forgot Password?") {
                    Task {
                        await viewModel.resetPassword()
                    }
                }
                .font(.footnote)
                .foregroundStyle(AppColors.accent)
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Form Field
private struct FormField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let field: LoginView.Field
    @FocusState var focusedField: LoginView.Field?
    let textContentType: UITextContentType?
    let keyboardType: UIKeyboardType?
    let isSecure: Bool
    
    init(
        title: String,
        text: Binding<String>,
        placeholder: String,
        field: LoginView.Field,
        focusedField: FocusState<LoginView.Field?>,
        textContentType: UITextContentType? = nil,
        keyboardType: UIKeyboardType? = nil,
        isSecure: Bool = false
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.field = field
        self._focusedField = focusedField
        self.textContentType = textContentType
        self.keyboardType = keyboardType
        self.isSecure = isSecure
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacingSmall) {
            Text(title)
                .font(.headline)
                .foregroundStyle(AppColors.textPrimary)
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .textInputAutocapitalization(isSecure ? .never : .words)
            .autocorrectionDisabled()
            .textContentType(textContentType)
            .keyboardType(keyboardType ?? .default)
            .focused($focusedField, equals: field)
            .padding()
            .background(AppColors.secondaryBackground)
            .cornerRadius(AppMetrics.cornerRadiusLarge)
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.cornerRadiusLarge)
                    .stroke(focusedField == field ? AppColors.accent : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Action Button
private struct ActionButton: View {
    @ObservedObject var viewModel: AuthViewModel
    
    var body: some View {
        Button(action: {
            Task {
                if viewModel.isSignUpMode {
                    await viewModel.signUp()
                } else {
                    await viewModel.login()
                }
            }
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: viewModel.isSignUpMode ? "person.badge.plus" : "arrow.right")
                        .font(.headline)
                }
                Text(viewModel.isLoading ? (viewModel.isSignUpMode ? "Creating Account..." : "Signing In...") : (viewModel.isSignUpMode ? "Create Account" : "Sign In"))
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(buttonBackgroundColor)
            .foregroundColor(buttonForegroundColor)
            .cornerRadius(AppMetrics.cornerRadiusLarge)
            .scaleEffect(buttonScale)
            .animation(.easeInOut(duration: 0.1), value: viewModel.isSignUpMode)
        }
        .disabled(viewModel.isSignUpMode ? !viewModel.isValidSignUp : !viewModel.isValidLogin || viewModel.isLoading)
        .buttonStyle(.plain)
    }
    
    private var buttonBackgroundColor: Color {
        if viewModel.isSignUpMode {
            return viewModel.isValidSignUp ? AppColors.accent : .gray.opacity(0.3)
        } else {
            return viewModel.isValidLogin ? AppColors.accent : .gray.opacity(0.3)
        }
    }
    
    private var buttonForegroundColor: Color {
        if viewModel.isSignUpMode {
            return viewModel.isValidSignUp ? .white : .gray
        } else {
            return viewModel.isValidLogin ? .white : .gray
        }
    }
    
    private var buttonScale: CGFloat {
        if viewModel.isSignUpMode {
            return viewModel.isValidSignUp ? 1.0 : 0.98
        } else {
            return viewModel.isValidLogin ? 1.0 : 0.98
        }
    }
}

// MARK: - Footer Section
private struct FooterSection: View {
    var body: some View {
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


