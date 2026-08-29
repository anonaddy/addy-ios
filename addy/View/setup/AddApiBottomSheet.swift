//
//  AddApiBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 07/05/2024.
//

import addy_shared
import AVFoundation
import CodeScanner
import SwiftUI

struct AddApiBottomSheet: View {
    @EnvironmentObject var mainViewState: MainViewState

    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    @Environment(\.scenePhase) var scenePhase

    @State private var showInvalidQrAlert = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var instanceError: String?
    @State private var apiKeyError: String?
    @State private var instance: String
    @State private var apiKey: String
    @State private var cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var loginType: String = "login" // login or api
    @State private var apiExpiration: String = "never" // day, week, month, year or nil (never)
    @State private var usernameValidationError: String?
    @State private var username: String = ""
    @State private var otpValidationError: String?
    @State private var otp: String = ""
    @State private var passwordValidationError: String?
    @State private var password: String = ""
    @State var isLoadingSignIn: Bool = false
    @State private var certificateData: Data?
    @State private var certificatePass: String?
    @State private var showCertificatePasswordSheet = false
    @State private var showCertificatePicker = false

    let apiBaseUrl: String?
    let addKey: (String, String, Data?, String?) -> Void
    @State private var otpMfaObject: LoginMfaRequired?

    var body: some View {
        #if DEBUG
            let _ = Self._printChanges()
        #endif
        Form {
            Section {
                ZStack(alignment: .center) {
                    CodeScannerView(codeTypes: [.qr], scanMode: .continuous) { response in
                        if case let .success(result) = response {
                            if isQrCodeFormattedCorrect(text: result.string) {
                                self.loginType = "api"

                                // if apiBaseUrl set, do not set the baseURL using QR
                                if apiBaseUrl == nil {
                                    // Get the string part before the | delimiter
                                    instance = result.string.components(separatedBy: "|").first ?? ""
                                }
                                // Get the string part after the | delimiter
                                apiKey = result.string.components(separatedBy: "|").last ?? ""

                                isLoadingSignIn = true
                                // Call back to SetupView
                                Task {
                                    await self.verifyApiKey(apiKey: apiKey, baseUrl: instance)
                                }
                            } else {
                                self.showInvalidQrAlert = true
                            }
                        }
                    }.onTapGesture {
                        if cameraAuthorizationStatus != .authorized {
                            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                        }
                    }.frame(maxHeight: .infinity)
                        .alert(isPresented: $showInvalidQrAlert, content: {
                            Alert(title: Text(String(localized: "api_setup_qr_code_scan_wrong")), message: Text(String(localized: "api_setup_qr_code_scan_wrong_desc")), dismissButton: .default(Text(String(localized: "understood", bundle: Bundle(for: SharedData.self)))))
                        })

                }.frame(height: 200).listRowInsets(EdgeInsets())

            } header: {
                VStack(alignment: .leading) {
                    Text(String(localized: "qr_code_setup"))
                }
            } footer: {
                if cameraAuthorizationStatus == .authorized {
                    Text(String(localized: "api_setup_qr_code_scan_desc"))
                } else {
                    Text(String(localized: "qr_permissions_required"))
                        .foregroundStyle(.red)
                }

            }.textCase(nil)

            Section {
                Picker(selection: $loginType, label: Text(String(localized: "login_type"))) {
                    Text(String(localized: "login_username")).tag("login")
                    Text(String(localized: "login_api")).tag("api")
                }.pickerStyle(.segmented)
                
                HStack {
                    ValidatingTextField(value: $instance, placeholder: String(localized: "addyio_instance"), fieldType: .url, error: $instanceError).disabled(apiBaseUrl != nil)
                    if certificateData != nil {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.green)
                    }
                }

                if loginType == "api" {
                    ValidatingTextField(value: $apiKey, placeholder: String(localized: "APIKey_desc"), fieldType: .bigText, error: $apiKeyError)
                } else {
                    ValidatingTextField(value: self.$username, placeholder: String(localized: "registration_username"), fieldType: .text, error: $usernameValidationError).onAppear {
                        if apiBaseUrl != nil {
                            self.username = mainViewState.userResource?.username ?? ""
                        }
                    }.disabled(apiBaseUrl != nil)

                    ValidatingTextField(value: self.$password, placeholder: String(localized: "registration_password"), fieldType: .password, error: $passwordValidationError)

                    if otpMfaObject != nil {
                        ValidatingTextField(value: self.$otp, placeholder: String(localized: "registration_otp"), fieldType: .otp, error: $otpValidationError)
                    }

                    Picker(selection: $apiExpiration, label: Text(String(localized: "login_expiration"))) {
                        Text(String(localized: "login_expiration_day")).tag("day")
                        Text(String(localized: "login_expiration_week")).tag("week")
                        Text(String(localized: "login_expiration_month")).tag("month")
                        Text(String(localized: "login_expiration_year")).tag("year")
                        Text(String(localized: "login_expiration_never")).tag("never")
                    }.pickerStyle(.navigationLink)
                }

            } header: {
                VStack(alignment: .leading) {
                    Text(String(localized: "credentials"))
                }
            } footer: {
                if loginType == "api" {
                    Text(String(localized: "api_obtain_desc"))
                } else {
                    Text(String(localized: "login_desc"))
                }
            }.textCase(nil)
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(String(localized: "login")), message: Text(alertMessage))
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
            }
        }
        .fileImporter(
            isPresented: $showCertificatePicker,
            allowedContentTypes: [.pkcs12]
        ) { result in
            switch result {
            case .success(let url):
                guard url.startAccessingSecurityScopedResource() else { return }
                defer { url.stopAccessingSecurityScopedResource() }
                do {
                    certificateData = try Data(contentsOf: url)
                    showCertificatePasswordSheet = true
                } catch {
                    print("Error reading certificate data: \(error)")
                }
            case .failure(let error):
                print("Error selecting certificate: \(error)")
            }
        }
        .sheet(isPresented: $showCertificatePasswordSheet) {
            CertificatePasswordView(certificateData: $certificateData, certificatePass: $certificatePass)
                .presentationDetents([.medium])
        }
        .navigationTitle(String(localized: "login"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            ToolbarItem(placement: .confirmationAction) {
                if #available(iOS 26.0, *) {
                    signInButton().buttonStyle(.glassProminent)
                } else {
                    signInButton()
                }
            }

            ToolbarItem(placement: .cancellationAction) {
                Menu(content: {
                    Button(String(localized: "get_my_key")) {
                        openURL(URL(string: "\(instance)/settings/api")!)
                    }
                    if certificateData == nil {
                        Button(String(localized: "select_certificate")) {
                            showCertificatePicker = true
                        }
                    } else {
                        Button(String(localized: "remove_certificate"), role: .destructive) {
                            certificateData = nil
                            certificatePass = nil
                        }
                    }
                    Button(String(localized: "cancel", bundle: Bundle(for: SharedData.self))) {
                        dismiss()
                    }
                }, label: {
                    Label(String(localized: "menu"), systemImage: "ellipsis.circle")
                })
            }

        })
    }

    private func signInButton() -> some View {
        Group {
            if isLoadingSignIn {
                ProgressView().progressViewStyle(.circular)
            } else {
                Button {
                    withAnimation {
                        isLoadingSignIn = true
                    }
                    if loginType == "api" {
                        if apiKeyError == nil && instanceError == nil {
                            Task {
                                await self.verifyApiKey(apiKey: apiKey, baseUrl: instance)
                            }
                        } else {
                            resetSignInButton()
                        }
                    } else {
                        if usernameValidationError == nil && passwordValidationError == nil && (otpMfaObject == nil || otpValidationError == nil) {
                            Task {
                                await self.verifyLogin(username: self.username, password: self.password, otp: self.otp, baseUrl: instance)
                            }
                        } else {
                            resetSignInButton()
                        }
                    }
                } label: {
                    Text(String(localized: "sign_in"))
                }
            }
        }
    }

    init(apiBaseUrl: String?, addKey: @escaping (String, String, Data?, String?) -> Void) {
        self.apiBaseUrl = apiBaseUrl
        self.addKey = addKey
        instance = apiBaseUrl ?? String(localized: "default_base_url")
        apiKey = ""
    }

    private func verifyApiKey(apiKey: String, baseUrl: String = AddyIo.API_BASE_URL) async {
        let cleanApiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        var cleanBaseUrl = baseUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanBaseUrl.hasSuffix("/") {
            cleanBaseUrl.removeLast()
        }
        let userRepo = UserRepository(apiClient: APIClient(p12: certificateData, p12Password: certificatePass))
        do {
            let result = try await userRepo.verifyApiKey(baseUrl: cleanBaseUrl, apiKey: cleanApiKey)
            if result != nil {
                // APIKey is verified if the API_KEY is currently nil (aka empty)
                // Or
                // UserResource ids are the same
                if SettingsManager(encrypted: true).getSettingsString(key: .apiKey) == nil ||
                    mainViewState.userResource?.id == result?.id
                {
                    addKey(cleanApiKey, cleanBaseUrl, certificateData, certificatePass)
                } else {
                    resetSignInButton()
                    apiKeyError = String(localized: "api_belongs_other_account")
                }
            } else {
                resetSignInButton()
                apiKeyError = String(localized: "api_invalid")
            }
        } catch {
            resetSignInButton()
            apiKeyError = "\(error)"
        }
    }

    private func verifyLogin(username: String, password: String, otp: String, baseUrl: String = AddyIo.API_BASE_URL) async {
        usernameValidationError = nil
        passwordValidationError = nil
        otpValidationError = nil

        if username.isEmpty {
            usernameValidationError = String(localized: "registration_username_empty")
            resetSignInButton()
            return
        }

        if password.isEmpty {
            passwordValidationError = String(localized: "registration_password_empty")
            resetSignInButton()
            return
        }
        
        var cleanBaseUrl = baseUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanBaseUrl.hasSuffix("/") {
            cleanBaseUrl.removeLast()
        }

        let userRepo = UserRepository(apiClient: APIClient(p12: certificateData, p12Password: certificatePass))

        if let otpMfaObject = otpMfaObject {
            if otp.isEmpty {
                otpValidationError = String(localized: "otp_required")
                resetSignInButton()
                return
            }

            // OTP has been entered, do the call to the /api/auth/mfa endpoint
            do {
                let login = try await userRepo.loginMfa(baseUrl: cleanBaseUrl, mfaKey: otpMfaObject.mfa_key, otp: self.otp, apiExpiration: apiExpiration)
                self.addKey(login.api_key, cleanBaseUrl, certificateData, certificatePass)
            } catch {
                withAnimation {
                    self.otpMfaObject = nil
                    self.otp = ""
                    self.otpValidationError = nil
                }

                self.alertMessage = error.localizedDescription
                self.showAlert = true
                resetSignInButton()
            }
        } else {
            do {
                let result = try await userRepo.login(baseUrl: cleanBaseUrl, username: username, password: password, apiExpiration: apiExpiration)
                switch result {
                case .success(let login):
                    self.addKey(login.api_key, cleanBaseUrl, certificateData, certificatePass)
                case .mfaRequired(let loginMfaRequired):
                    withAnimation {
                        self.otpMfaObject = loginMfaRequired
                    }
                    resetSignInButton()
                }
            } catch {
                self.alertMessage = error.localizedDescription
                self.showAlert = true
                resetSignInButton()
            }
        }
    }

    private func resetSignInButton() {
        isLoadingSignIn = false
    }

    private func isQrCodeFormattedCorrect(text: String) -> Bool {
        return text.contains("|") && text.contains("http")
    }
}

#Preview {
    AddApiBottomSheet(apiBaseUrl: "TEST", addKey: { _, _, _, _ in
        // Dummy function for preview
    })
}
