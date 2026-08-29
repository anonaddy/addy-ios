//
//  RegistrationFormBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 24/09/2024.
//

import addy_shared
import SwiftUI

struct RegistrationFormBottomSheet: View {
    @Environment(\.openURL) var openURL
    @Environment(\.dismiss) var dismiss

    @State private var passwordValidationError: String?
    @State private var password: String = ""
    @State private var passwordConfirmValidationError: String?
    @State private var passwordConfirm: String = ""
    @State private var showAlert = false
    @State private var isLoadingRegister = false
    @State private var alertMessage = ""
    @State private var addressValidationError: String?
    @State private var address: String = ""
    @State private var addressConfirmValidationError: String?
    @State private var addressConfirm: String = ""
    @State private var usernameValidationError: String?
    @State private var username: String = ""
    @State private var activeAlert: ActiveAlert = .error
    @State private var apiExpiration: String = "never" // day, week, month, year or nil (never)
    @Binding var showOnboarding: Bool

    enum ActiveAlert {
        case error, completionMessage
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ValidatingTextField(value: self.$username, placeholder: String(localized: "registration_username"), fieldType: .text, error: $usernameValidationError)
                } header: {
                    Text(String(localized: "registration_username_header"))
                } footer: {
                    Text(LocalizedStringKey(String(localized: "registration_username_footer")))
                }.textCase(nil)

                Section {
                    ValidatingTextField(value: self.$address, placeholder: String(localized: "registration_email"), fieldType: .email, error: $addressValidationError)
                    ValidatingTextField(value: self.$addressConfirm, placeholder: String(localized: "registration_email_confirm"), fieldType: .email, error: $addressConfirmValidationError)
                } header: {
                    Text(String(localized: "registration_email_header"))
                } footer: {
                    Text(String(localized: "registration_email_footer"))
                }.textCase(nil)

                Section {
                    ValidatingTextField(value: self.$password, placeholder: String(localized: "registration_password"), fieldType: .password, error: $passwordValidationError)

                    ValidatingTextField(value: self.$passwordConfirm, placeholder: String(localized: "registration_password_confirm"), fieldType: .password, error: $passwordConfirmValidationError)

                    Picker(selection: $apiExpiration, label: Text(String(localized: "login_expiration"))) {
                        Text(String(localized: "login_expiration_day")).tag("day")
                        Text(String(localized: "login_expiration_week")).tag("week")
                        Text(String(localized: "login_expiration_month")).tag("month")
                        Text(String(localized: "login_expiration_year")).tag("year")
                        Text(String(localized: "login_expiration_never")).tag("never")
                    }.pickerStyle(.navigationLink)

                } header: {
                    Text(String(localized: "registration_password_header"))
                } footer: {
                    Text(String(localized: "registration_password_footer"))
                }.textCase(nil)

                Section {} footer: {
                    Text(String(localized: "registration_disclaimer")).frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center).padding(.top)
                }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())

                HStack {
                    Spacer()

                    Button(action: {
                        openURL(URL(string: "https://addy.io/privacy?ref=appstore")!)
                    }) {
                        Text(String(localized: "privacy_policy"))
                    }

                    Spacer()

                    Button(action: {
                        openURL(URL(string: "https://addy.io/terms?ref=appstore")!)
                    }) {
                        Text(String(localized: "terms_of_service"))
                    }
                    Spacer()

                }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())
            }
            .navigationTitle(String(localized: "registration_register"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .confirmationAction) {
                    if #available(iOS 26.0, *) {
                        registerButton().buttonStyle(.glassProminent)
                    } else {
                        registerButton()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Label(String(localized: "cancel", bundle: Bundle(for: SharedData.self)), systemImage: "xmark")
                    }
                }
            })
        }
        .alert(isPresented: $showAlert) {
            switch activeAlert {
            case .error:
                return Alert(title: Text(String(localized: "registration_register")), message: Text(alertMessage))
            case .completionMessage:
                return Alert(title: Text(String(localized: "registration_register")), message: Text(alertMessage), dismissButton: .default(Text(String(localized: "understood", bundle: Bundle(for: SharedData.self)))) {
                    self.dismiss()
                    showOnboarding = false
                })
            }
        }
    }

    private func registerButton() -> some View {
        Group {
            if isLoadingRegister {
                ProgressView().progressViewStyle(.circular)
            } else {
                Button {
                    // First check for existing validation errors
                    if usernameValidationError == nil &&
                        addressValidationError == nil &&
                        addressConfirmValidationError == nil &&
                        passwordValidationError == nil &&
                        passwordConfirmValidationError == nil
                    {
                        Task {
                            isLoadingRegister = true
                            await registerUser()
                        }
                    } else {
                        resetButton()
                    }
                } label: {
                    Text(String(localized: "registration_register"))
                }
            }
        }
    }

    func registerUser() async {
        usernameValidationError = nil
        addressValidationError = nil
        addressConfirmValidationError = nil
        passwordValidationError = nil
        passwordConfirmValidationError = nil

        if username.isEmpty {
            usernameValidationError = String(localized: "registration_username_empty")
            resetButton()
            return
        }

        if address.isEmpty {
            addressValidationError = String(localized: "registration_address_empty")
            resetButton()
            return
        }

        if addressConfirm.isEmpty {
            addressConfirmValidationError = String(localized: "registration_address_empty")
            resetButton()
            return
        }

        if password.isEmpty {
            passwordValidationError = String(localized: "registration_password_empty")
            resetButton()
            return
        }

        if passwordConfirm.isEmpty {
            passwordConfirmValidationError = String(localized: "registration_password_confirm_empty")
            resetButton()
            return
        }

        if address != addressConfirm {
            addressConfirmValidationError = String(localized: "registration_email_confirm_mismatch")
            resetButton()
            return
        }

        if password != passwordConfirm {
            passwordConfirmValidationError = String(localized: "registration_password_confirm_mismatch")
            resetButton()
            return
        }

        do {
            try await UserRepository.shared.registration(username: username, email: address, password: password, apiExpiration: apiExpiration)
            // Registration success
            self.alertMessage = String(localized: "registration_success_verification_required")
            self.activeAlert = .completionMessage
            self.showAlert = true
        } catch {
            self.alertMessage = error.localizedDescription
            self.activeAlert = .error
            self.showAlert = true
            resetButton()
        }
    }

    private func resetButton() {
        isLoadingRegister = false
    }
}

struct RegistrationFormBottomSheet_Previews: PreviewProvider {
    static var previews: some View {
        RegistrationFormBottomSheet(showOnboarding: .constant(false))
    }
}
