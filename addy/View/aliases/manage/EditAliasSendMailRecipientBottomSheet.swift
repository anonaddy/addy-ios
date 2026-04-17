//
//  EditAliasSendMailRecipientBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 12/05/2024.
//

import AVFoundation
import SwiftUI
import addy_shared

struct EditAliasSendMailRecipientBottomSheet: View {
    @Environment(\.dismiss) var dismiss

    @State private var aliasEmail: String
    @State private var addressesValidationError: String?
    @State private var addresses: String = ""
    @State private var addressesPlaceholder: String = .init(localized: "addresses")

    let onPressSend: (String) -> Void
    let onPressCopy: (String) -> Void

    var body: some View {
        #if DEBUG
            let _ = Self._printChanges()
        #endif
        Form {
            Section {
                ValidatingTextField(value: self.$addresses, placeholder: $addressesPlaceholder, fieldType: .commaSeperatedEmails, error: $addressesValidationError)

            } header: {
                let formattedString = String.localizedStringWithFormat(NSLocalizedString("send_mail_from_alias_desc", comment: ""), aliasEmail)
                // Use Text with markdown to display the formatted string
                Text(LocalizedStringKey(formattedString))
                    .multilineTextAlignment(.center).padding(.bottom)
            }.textCase(nil).frame(maxWidth: .infinity, alignment: .center)

        }.navigationTitle(String(localized: "send_mail")).pickerStyle(.navigationLink)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem() {
                    Button {
                        // Only perform the action whent the addresses are valid
                        if addressesValidationError == nil {
                            self.onPressCopy(self.addresses)
                        }
                    } label: {
                        Image(systemName: "clipboard")
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    if #available(iOS 26.0, *) {
                        sendButton().buttonStyle(.glassProminent)
                    } else {
                        sendButton()
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

    private func sendButton() -> some View {
        Button {
            // Only perform the action whent the addresses are valid
            if addressesValidationError == nil {
                self.onPressSend(self.addresses)
            }
        } label: {
            Text(String(localized: "send"))
        }
    }

    init(aliasEmail: String, onPressSend: @escaping (String) -> Void, onPressCopy: @escaping (String) -> Void) {
        self.aliasEmail = aliasEmail
        self.onPressSend = onPressSend
        self.onPressCopy = onPressCopy
    }
}

#Preview {
    EditAliasSendMailRecipientBottomSheet(aliasEmail: "TEST", onPressSend: { _ in
        print("SEND")
    }, onPressCopy: { _ in
        print("COPY")
    })
}
