//
//  EditUsernameDescriptionBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 01/06/2024.
//

import SwiftUI
import AVFoundation
import CodeScanner
import addy_shared

struct EditUsernameDescriptionBottomSheet: View {
    let usernameId: String
    @State private var description: String
    @State private var descriptionPlaceholder: String = String(localized: "description")
    let descriptionEdited: (Usernames) -> Void

    init(usernameId: String, description: String, descriptionEdited: @escaping (Usernames) -> Void) {
        self.usernameId = usernameId
        self.description = description
        self.descriptionEdited = descriptionEdited
    }
    
    @State private var descriptionValidationError:String?
    @State private var descriptionRequestError:String?

    @State var IsLoadingSaveButton: Bool = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Form{

            Section {

                
                ValidatingTextField(value: self.$description, placeholder: self.$descriptionPlaceholder, fieldType: .bigText, error: $descriptionValidationError)

                

                
                
            } header: {
                VStack(alignment: .leading){
                    Text(String(localized: "edit_desc_username_desc"))
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                    
                }.textCase(nil).frame(maxWidth: .infinity, alignment: .center)
            } footer: {
                if let error = descriptionRequestError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.system(size: 15))
                        .multilineTextAlignment(.leading)
                        .padding([.horizontal], 0)
                        .onAppear{
                            HapticHelper.playHapticFeedback(hapticType: .error)
                                                        }
                }
            }
            
            Section {
                AddyLoadingButton(action: {
                    // Since the ValidatingTextField is also handling validationErrors (and resetting these errors on every change)
                    // We should not allow any saving until the validationErrors are nil
                    if (descriptionValidationError == nil){
                        IsLoadingSaveButton = true;
                        
                        DispatchQueue.global(qos: .background).async {
                            self.editDescription(description: self.description)
                        }
                    } else {
                        DispatchQueue.main.async {
                            IsLoadingSaveButton = false
                        }
                    }
                }, isLoading: $IsLoadingSaveButton) {
                    Text(String(localized: "save")).foregroundColor(Color.white)
                }.frame(minHeight: 56)
            }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())
            
            }.navigationTitle(String(localized: "edit_description")).pickerStyle(.navigationLink)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text(String(localized: "cancel"))
                    }
                    
                }
            })
        
        
    }
    
    
    private func editDescription(description:String?) {
        descriptionRequestError = nil
        
        let networkHelper = NetworkHelper()
        networkHelper.updateDescriptionSpecificUsername(completion: { username, error in
            DispatchQueue.main.async {
                if let username = username {
                    self.descriptionEdited(username)
                } else {
                    IsLoadingSaveButton = false
                    descriptionRequestError = error
                }
            }
        }, usernameId: self.usernameId, description: description)
    }
}

#Preview {
    EditUsernameDescriptionBottomSheet(usernameId: "000", description: "TEST", descriptionEdited: { username in
        // Dummy function for preview
    })
}
