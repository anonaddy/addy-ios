//
//  EmailVerificationBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 12/10/2026.
//

import addy_shared
import SwiftUI

struct EmailVerificationBottomSheet: View {
    @Environment(\.dismiss) var dismiss

    let query: String
    let addKey: (String, String, Data?, String?) -> Void

    @State private var isVerifying = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    private var email: String? {
        if let components = URLComponents(string: "?\(query)"),
           let emailItem = components.queryItems?.first(where: { $0.name.lowercased() == "email" })?.value,
           !emailItem.isEmpty {
            return emailItem
        }
        return nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header section
                VStack(spacing: 12) {
                    Text(String(localized: "email_verification"))
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Capsule()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 44, height: 3)
                        .padding(.vertical, 2)

                    if let email = email {
                        Text(LocalizedStringKey(String(format: String(localized: "email_verification_prohibited_actions_intro_with_email"), email)))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 4)
                    } else {
                        Text(LocalizedStringKey(String(localized: "email_verification_prohibited_actions_intro")))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(.top, 16)

                // Prohibited actions list
                VStack(spacing: 20) {
                    prohibitedRow(
                        title: String(localized: "email_verification_no_mass_signups_title"),
                        description: String(localized: "email_verification_no_mass_signups_desc")
                    )

                    prohibitedRow(
                        title: String(localized: "email_verification_no_multiple_free_accounts_title"),
                        description: String(localized: "email_verification_no_multiple_free_accounts_desc")
                    )

                    prohibitedRow(
                        title: String(localized: "email_verification_no_marking_emails_as_spam_title"),
                        description: String(localized: "email_verification_no_marking_emails_as_spam_desc")
                    )
                }
                .padding(.vertical, 8)

                // Action button and notes
                VStack(spacing: 14) {
                    Button(action: {
                        Task {
                            await verifyAndLogin()
                        }
                    }) {
                        HStack(spacing: 8) {
                            if isVerifying {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(String(localized: "email_verification_button"))
                                .fontWeight(.semibold)
                        }
                        
                        
                    }
                    .controlSize(.large)
                    .apply { View in
                        if #available(iOS 26.0, *) {
                            View.buttonStyle(.glassProminent)
                        } else {
                            View.buttonStyle(.borderedProminent)
                        }
                    }
                    .disabled(isVerifying)

                    VStack(spacing: 6) {
                        Text(LocalizedStringKey(String(localized: "email_verification_account_deletion_note")))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 8)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Label(String(localized: "cancel", bundle: Bundle(for: SharedData.self)), systemImage: "xmark")
                }
                .disabled(isVerifying)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(String(localized: "email_verification")),
                message: Text(alertMessage),
                dismissButton: .default(Text(String(localized: "understood", bundle: Bundle(for: SharedData.self))))
            )
        }
    }

    private func prohibitedRow(title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "xmark.circle.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, Color(red: 0.92, green: 0.34, blue: 0.34))
                .font(.system(size: 20, weight: .semibold))
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func verifyAndLogin() async {
        isVerifying = true
        do {
            let apiKey = try await UserRepository.shared.verifyRegistration(query: query)
            addKey(apiKey, AddyIo.API_BASE_URL, nil, nil)
            dismiss()
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
            isVerifying = false
        }
    }
}

#Preview {
    NavigationStack {
        EmailVerificationBottomSheet(
            query: "email=hi%40example.com",
            addKey: { _, _, _, _ in }
        )
    }
}
