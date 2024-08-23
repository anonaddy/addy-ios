//
//  AddUsernameBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 01/06/2024.
//

import SwiftUI


import SwiftUI
import AVFoundation
import addy_shared

struct AddUsernameBottomSheet: View {
    @State var username: String = ""
    @State var usernameLimit: Int
    @State var usernamePlaceHolder: String = String(localized: "username")
    let onAdded: () -> Void

    init(usernameLimit: Int, onAdded: @escaping () -> Void) {
        self.usernameLimit = usernameLimit
        self.onAdded = onAdded
    }
    
    @State private var usernameValidationError:String?
    @State private var usernameRequestError:String?

    @State var IsLoadingAddButton: Bool = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
            Form {
                
                Section{
                    ValidatingTextField(value: self.$username, placeholder: self.$usernamePlaceHolder, fieldType: .text, error: $usernameValidationError)
                    
                } header: {
                    VStack(alignment: .leading){
                        let formattedString = String.localizedStringWithFormat(NSLocalizedString("add_username_desc", comment: ""), String(usernameLimit))
                        Text(LocalizedStringKey(formattedString))
                            .multilineTextAlignment(.center)
                            .padding(.bottom)
                    }.frame(maxWidth: .infinity, alignment: .center)
                } footer: {
                    if let error = usernameRequestError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.system(size: 15))
                            .multilineTextAlignment(.leading)
                            .padding([.horizontal], 0)
                            .onAppear{
                                HapticHelper.playHapticFeedback(hapticType: .error)
                            }
                    }
                
                }.textCase(nil)
                
                Section{
                    AddyLoadingButton(action: {
                        // Since the ValidatingTextField is also handling validationErrors (and resetting these errors on every change)
                        // We should not allow any saving until the validationErrors are nil
                        if (usernameValidationError == nil){
                            IsLoadingAddButton = true;
                            
                            Task {
                                await self.addUsernameToAccount(username: self.username)
                            }
                        } else {
                                IsLoadingAddButton = false
                        }
                    }, isLoading: $IsLoadingAddButton) {
                        Text(String(localized: "add")).foregroundColor(Color.white)
                    }.frame(minHeight: 56)
                }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())
                
                
                
                
            }.navigationTitle(String(localized: "add_username")).pickerStyle(.navigationLink)
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
    
    
    private func addUsernameToAccount(username: String) async {
        usernameRequestError = nil
        let networkHelper = NetworkHelper()
        do {
            _ = try await networkHelper.addUsername(username: username)
            self.onAdded()
        } catch {
            IsLoadingAddButton = false
            usernameRequestError = error.localizedDescription
        }
    }

}

#Preview {
    AddUsernameBottomSheet(usernameLimit: 10) {
        // Dummy function for preview
    }
}
