//
//  RegistrationFormBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 24/09/2024.
//


import SwiftUI
import addy_shared

struct RegistrationFormBottomSheet: View {
    
    @State private var passwordPlaceholder:String = String(localized: "registration_password")
    @State private var passwordValidationError:String?
    @State private var password:String = ""
    
    @State private var passwordConfirmPlaceholder:String = String(localized: "registration_password_confirm")
    @State private var passwordConfirmValidationError:String?
    @State private var passwordConfirm:String = ""
    
    @State private var showAlert = false
    @State private var isLoadingRegister = false
    @State private var alertMessage = ""
    
    @State private var addressPlaceholder:String = String(localized: "registration_email")
    @State private var addressValidationError:String?
    @State private var address:String = ""
    
    @State private var addressConfirmPlaceholder:String = String(localized: "registration_email_confirm")
    @State private var addressConfirmValidationError:String?
    @State private var addressConfirm:String = ""
    
    @State private var usernamePlaceholder:String = String(localized: "registration_username")
    @State private var usernameValidationError:String?
    @State private var username:String = ""
    
    @EnvironmentObject var appState: AppState

    @Environment(\.openURL) var openURL
    @Environment(\.dismiss) var dismiss


    var body: some View {
        NavigationView {
            List {
                Section {
                    ValidatingTextField(value: self.$username, placeholder: $usernamePlaceholder, fieldType: .text, error: $usernameValidationError)
                } header: {
                    Text(String(localized: "registration_username_header"))
                } footer: {
                    Text(LocalizedStringKey(String(localized: "registration_username_footer")))
                }

                Section {
                    ValidatingTextField(value: self.$address, placeholder: $addressPlaceholder, fieldType: .email, error: $addressValidationError)
                    ValidatingTextField(value: self.$addressConfirm, placeholder: $addressConfirmPlaceholder, fieldType: .email, error: $addressConfirmValidationError)
                                    } header: {
                    Text(String(localized: "registration_email_header"))
                } footer: {
                    Text(String(localized: "registration_email_footer"))
                }
                               
                
                Section {
                    
                    ValidatingTextField(value: self.$password, placeholder: $passwordPlaceholder, fieldType: .password, error: $passwordValidationError)
                    
                    ValidatingTextField(value: self.$passwordConfirm, placeholder: $passwordConfirmPlaceholder, fieldType: .password, error: $passwordConfirmValidationError)
                    
                    
                } header: {
                    Text(String(localized: "registration_password_header"))
                } footer: {
                    Text(String(localized: "registration_password_footer"))
                }
                
                Section {
                    AddyLoadingButton(action: {
                        
                        // First check for existing validation errors
                        if (usernameValidationError == nil &&
                            addressValidationError == nil &&
                            addressConfirmValidationError == nil &&
                            passwordValidationError == nil &&
                            passwordConfirmValidationError == nil){
                            registerUser()
                        } else {
                            resetButton()
                        }

                        
                    }, isLoading: $isLoadingRegister) {
                        Text(String(localized: "registration_register")).foregroundColor(Color.white)
                    }.frame(minHeight: 56)
                } footer: {
                    Text(String(localized: "registration_disclaimer")).frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center).padding(.top)
                }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())
                
                HStack {
                    Spacer()
                    
                    Button(action: {
                        openURL(URL(string: "https://github.com/anonaddy/legal/blob/main/Privacy%20Policy.md")!)
                    }) {
                        Text(String(localized:"privacy_policy"))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        openURL(URL(string: "https://github.com/anonaddy/legal/blob/main/Terms%20Of%20Service.md")!)
                    }) {
                        Text(String(localized:"terms_of_service"))
                    }
                    Spacer()
                    
                }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())
                
            }
            .navigationTitle(String(localized: "registration_register"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text(String(localized: "cancel"))
                    }
                    
                }
            })
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(String(localized: "registration_register")), message: Text(alertMessage))
        }
    }

    func registerUser() {
        usernameValidationError = nil
        addressValidationError = nil
        addressConfirmValidationError = nil
        passwordValidationError = nil
        passwordConfirmValidationError = nil
        
        if username.isEmpty{
            usernameValidationError = String(localized: "registration_username_empty")
            resetButton()
            return
        }
            
        if address.isEmpty{
            addressValidationError = String(localized: "registration_address_empty")
            resetButton()
            return
        }
        
        if addressConfirm.isEmpty{
            addressConfirmValidationError = String(localized: "registration_address_empty")
            resetButton()
            return
        }
        
        if password.isEmpty{
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
        
        if password != passwordConfirm{
            passwordConfirmValidationError = String(localized: "registration_password_confirm_mismatch")
            resetButton()
            return
        }
        

        
        //TODO: register
        
//        let networkHelper = NetworkHelper()
//        do {
//            if let domain = try await networkHelper.updateAutoCreateRegexSpecificDomain(domainId: self.domainId, autoCreateRegex: autoCreateRegex) {
//                self.autoCreateRegexEdited(domain)
//            }
//        } catch {
//            IsLoadingSaveButton = false
//            autoCreateRegexRequestError = error.localizedDescription
//        }

    }
    
    private func addKey(apiKey: String) {
        let encryptedSettingsManager = SettingsManager(encrypted: true)
        encryptedSettingsManager.putSettingsString(key: SettingsManager.Prefs.apiKey, string: apiKey)
        encryptedSettingsManager.putSettingsString(key: SettingsManager.Prefs.baseUrl, string: String(localized: "default_base_url"))
        dismiss()
        appState.apiKey = apiKey
    }
    
    private func resetButton(){
        // TODO: workaround, fix
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoadingRegister = false
        }
    }
}

struct RegistrationFormBottomSheet_Previews: PreviewProvider {
    static var previews: some View {
        RegistrationFormBottomSheet()
    }
}
