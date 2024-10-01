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
    
    enum ActiveAlert {
        case error, completionMessage
    }
    @State private var activeAlert: ActiveAlert = .error

    @State private var apiExpiration: String = "never" // day, week, month, year or nil (never)
    
    @Binding var showOnboarding: Bool


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
                    
                    Picker(selection: $apiExpiration, label: Text(String(localized:"login_expiration"))) {
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
                }
                
                Section {
                    AddyLoadingButton(action: {
                        
                        // First check for existing validation errors
                        if (usernameValidationError == nil &&
                            addressValidationError == nil &&
                            addressConfirmValidationError == nil &&
                            passwordValidationError == nil &&
                            passwordConfirmValidationError == nil){
                            
                            Task {
                                await registerUser()
                            }
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
                        openURL(URL(string: "https://addy.io/privacy?ref=appstore")!)
                    }) {
                        Text(String(localized:"privacy_policy"))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        openURL(URL(string: "https://addy.io/terms?ref=appstore")!)
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
            switch activeAlert {
            case .error:
                return Alert(title: Text(String(localized: "registration_register")), message: Text(alertMessage))
            case .completionMessage:
                return Alert(title: Text(String(localized: "registration_register")), message: Text(alertMessage), dismissButton: .default(Text(String(localized: "understood"))) {
                    self.dismiss()
                    showOnboarding = false
                })

            }
        }
    }

    func registerUser() async {
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
        

        
        let networkHelper = NetworkHelper()
        await networkHelper.registration(username: self.username, email: self.address, password: self.password, apiExpiration: apiExpiration, completion: { error in
            if error == nil {
                // Registration success
                self.alertMessage = String(localized: "registration_success_verification_required")
                self.activeAlert = .completionMessage
                self.showAlert = true
            } else {
                // Show error
                self.alertMessage = error!
                self.activeAlert = .error
                self.showAlert = true
                
                resetButton()
            }
        })

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
        RegistrationFormBottomSheet(showOnboarding: .constant(false))
    }
}
