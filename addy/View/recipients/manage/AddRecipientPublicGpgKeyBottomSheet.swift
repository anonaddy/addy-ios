//
//  AddRecipientPublicGpgKeyBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 27/05/2024.
//

import SwiftUI
import AVFoundation
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
#if DEBUG
        let _ = Self._printChanges()
#endif
        Form{
            
            Section {
                
                ValidatingTextField(value: self.$publicGpgKey, placeholder: self.$publicGpgKeyPlaceholder, fieldType: .bigText, error: $publicGpgKeyValidationError)
                
            } header: {
                VStack(alignment: .leading){
                    Text(String(localized: "add_public_gpg_key_desc"))
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                    
                }.frame(maxWidth: .infinity, alignment: .center)
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
            }.textCase(nil)
        }.navigationTitle(String(localized: "add_public_gpg_key")).pickerStyle(.navigationLink)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .confirmationAction) {
                    if #available(iOS 26.0, *) {
                        saveButton().buttonStyle(.glassProminent)
                    } else {
                        saveButton()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Label(String(localized: "cancel"), systemImage: "xmark")
                    }
                    
                }
            })
    }
    
    private func saveButton() -> some View {
        Group {
            if IsLoadingSaveButton {
                AnyView(ProgressView().progressViewStyle(.circular))
            } else {
                AnyView(
                    Button {
                        // Since the ValidatingTextField is also handling validationErrors (and resetting these errors on every change)
                        // We should not allow any saving until the validationErrors are nil
                        if (publicGpgKeyValidationError == nil){
                            IsLoadingSaveButton = true
                            
                            Task {
                                await self.addGpgKeyHttp(publicGpgKey: self.publicGpgKey)
                            }
                        } else {
                            IsLoadingSaveButton = false
                            
                        }
                    } label: {
                        Text(String(localized: "add"))
                    }
                )
            }
        }
        
    }
    
    
    private func addGpgKeyHttp(publicGpgKey: String) async {
        publicGpgKeyRequestError = nil
        let networkHelper = NetworkHelper()
        do {
            if let recipient = try await networkHelper.addEncryptionKeyRecipient(recipientId: self.recipientId, keyData: publicGpgKey){
                self.onKeyAdded(recipient)
            }
        } catch {
            IsLoadingSaveButton = false
            publicGpgKeyRequestError = error.localizedDescription
        }
    }
    
}

#Preview {
    EditAliasDescriptionBottomSheet(aliasId: "000", description: "TEST", descriptionEdited: { alias in
        // Dummy function for preview
    })
}
