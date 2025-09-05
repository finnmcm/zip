//
//  ReportBugView.swift
//  Zip
//

import SwiftUI
import Inject

struct ReportBugView: View {
    @ObserveInjection var inject
    @State private var bugTitle = ""
    @State private var bugDescription = ""
    @State private var isSubmitting = false
    @State private var showSuccessAlert = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: AppMetrics.spacingLarge) {
                    // Header
                    VStack(spacing: AppMetrics.spacing) {
                        Image(systemName: "ladybug.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(AppColors.accent)
                        
                        Text("Report a Bug")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(AppColors.textPrimary)
                        
                        Text("Help us improve Zip by reporting any issues you encounter")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, AppMetrics.spacingLarge)
                    
                    // Form
                    VStack(spacing: AppMetrics.spacingLarge) {
                        // Title Field
                        VStack(alignment: .leading, spacing: AppMetrics.spacingSmall) {
                            Text("Bug Title")
                                .font(.headline)
                                .foregroundStyle(AppColors.textPrimary)
                            
                            TextField("Brief description of the issue", text: $bugTitle)
                                .textFieldStyle(.roundedBorder)
                                .font(.body)
                        }
                        
                        // Description Field
                        VStack(alignment: .leading, spacing: AppMetrics.spacingSmall) {
                            Text("Description")
                                .font(.headline)
                                .foregroundStyle(AppColors.textPrimary)
                            
                            Text("Please provide as much detail as possible about the bug:")
                                .font(.caption)
                                .foregroundStyle(AppColors.textSecondary)
                            
                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: AppMetrics.cornerRadius)
                                    .fill(AppColors.secondaryBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppMetrics.cornerRadius)
                                            .stroke(AppColors.border, lineWidth: 1)
                                    )
                                
                                TextEditor(text: $bugDescription)
                                    .padding(AppMetrics.spacingSmall)
                                    .font(.body)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)
                            }
                            .frame(minHeight: 120)
                        }
                        
                        // Additional Info
                        VStack(alignment: .leading, spacing: AppMetrics.spacingSmall) {
                            Text("Additional Information")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppColors.textPrimary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("• What were you trying to do when the bug occurred?")
                                Text("• What did you expect to happen?")
                                Text("• What actually happened instead?")
                                Text("• Any error messages you saw?")
                            }
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                        }
                        .padding()
                        .background(AppColors.secondaryBackground.opacity(0.5))
                        .cornerRadius(AppMetrics.cornerRadius)
                    }
                    .padding(.horizontal, AppMetrics.spacingLarge)
                    
                    Spacer()
                    
                    // Submit Button
                    Button(action: submitBugReport) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "paperplane.fill")
                            }
                            
                            Text(isSubmitting ? "Submitting..." : "Submit Bug Report")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSubmit ? AppColors.accent : AppColors.accent.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(AppMetrics.cornerRadiusLarge)
                    }
                    .disabled(!canSubmit || isSubmitting)
                    .buttonStyle(.plain)
                    .padding(.horizontal, AppMetrics.spacingLarge)
                    .padding(.bottom, AppMetrics.spacingLarge)
                }
            }
            .navigationTitle("Report Bug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(AppColors.accent)
                }
            }
            .alert("Bug Report Submitted", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Thank you for helping us improve Zip! We'll review your report and get back to you if needed.")
            }
        }
        .enableInjection()
    }
    
    private var canSubmit: Bool {
        !bugTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !bugDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func submitBugReport() {
        guard canSubmit else { return }
        
        isSubmitting = true
        
        // Simulate network request
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSubmitting = false
            showSuccessAlert = true
            
            // Clear form after successful submission
            bugTitle = ""
            bugDescription = ""
        }
    }
}

#Preview {
    ReportBugView()
}
