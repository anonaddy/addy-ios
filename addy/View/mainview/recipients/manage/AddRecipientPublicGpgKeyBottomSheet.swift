//
//  AddRecipientPublicGpgKeyBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 27/05/2024.
//

import SwiftUI
import AVFoundation
import CodeScanner
import addy_shared

struct AddRecipientPublicGpgKeyBottomSheet: View {
    let recipientId: String
    @State private var publicGpgKey: String = ""

    @State private var publicGpgKeyPlaceholder: String = String(localized: "public_key_placeholder")
    let onKeyAdded: (Recipients) -> Void

    init(recipientId: String, onKeyAdded: @escaping (Recipients) -> Void) {
        self.recipientId = recipientId
        self.onKeyAdded = onKeyAdded
    }
    
    @State private var publicGpgKeyValidationError:String?
    @State private var publicGpgKeyRequestError:String?

    @State var IsLoadingSaveButton: Bool = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Form{

            Section {

                ValidatingTextField(value: self.$publicGpgKey, placeholder: self.$publicGpgKeyPlaceholder, fieldType: .bigText, error: $publicGpgKeyValidationError)

            } header: {
                VStack(alignment: .leading){
                    Text(String(localized: "add_public_gpg_key_desc"))
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                    
                }.textCase(nil).frame(maxWidth: .infinity, alignment: .center)
            } footer: {
                if let error = publicGpgKeyRequestError {
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
                    if (publicGpgKeyValidationError == nil){
                        IsLoadingSaveButton = true;
                        
                        DispatchQueue.global(qos: .background).async {
                            self.addGpgKeyHttp(publicGpgKey: self.publicGpgKey)
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
            
            }.navigationTitle(String(localized: "add_public_gpg_key")).pickerStyle(.navigationLink)
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
    
    
    private func addGpgKeyHttp(publicGpgKey:String) {
        publicGpgKeyRequestError = nil
        
        let networkHelper = NetworkHelper()
        networkHelper.addEncryptionKeyRecipient(completion: { recipient, error in
            DispatchQueue.main.async {
                if let recipient = recipient {
                    self.onKeyAdded(recipient)
                } else {
                    IsLoadingSaveButton = false
                    publicGpgKeyRequestError = error
                }
            }
        }, recipientId: self.recipientId, keyData: publicGpgKey)
    }
}

#Preview {
    EditAliasDescriptionBottomSheet(aliasId: "000", description: "TEST", descriptionEdited: { alias in
        // Dummy function for preview
    })
}
