//
//  EditAliasSendMailRecipientBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 12/05/2024.
//


import SwiftUI
import AVFoundation
import CodeScanner

struct EditAliasSendMailRecipientBottomSheet: View {
    @State private var aliasEmail: String
    let onPressSend: (String) -> Void

    init(aliasEmail: String, onPressSend: @escaping (String) -> Void) {
        self.aliasEmail = aliasEmail
        self.onPressSend = onPressSend
    }
    
    @State private var addressesValidationError:String?
    @State private var addresses:String = ""
    @State private var addressesPlaceholder:String = String(localized: "addresses")

    
    @Environment(\.dismiss) var dismiss
    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
        Form{
            
        
            Section {

                ValidatingTextField(value: self.$addresses, placeholder: $addressesPlaceholder, fieldType: .commaSeperatedEmails, error: $addressesValidationError)

            } header: {
                let formattedString = String.localizedStringWithFormat(NSLocalizedString("send_mail_from_alias_desc", comment: ""), aliasEmail)
                // Use Text with markdown to display the formatted string
                Text(LocalizedStringKey(formattedString))
                    .multilineTextAlignment(.center).padding(.bottom)
            }.textCase(nil).frame(maxWidth: .infinity, alignment: .center)
            
            Section {
                
                AddyButton(action: {
                    // Only perform the action whent the addresses are valid
                    if (addressesValidationError == nil){
                        self.onPressSend(self.addresses)
                    }
                }) {
                    Text(String(localized: "send")).foregroundColor(Color.white)
                }.frame(minHeight: 56)

            }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())
            
        }.navigationTitle(String(localized: "send_mail")).pickerStyle(.navigationLink)
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
}

#Preview {
    EditAliasSendMailRecipientBottomSheet(aliasEmail: "TEST", onPressSend: { alias in
        // Dummy function for preview
    })
}
