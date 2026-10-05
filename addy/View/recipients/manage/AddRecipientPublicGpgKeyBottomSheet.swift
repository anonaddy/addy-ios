//
//  AddRecipientPublicGpgKeyBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 27/05/2024.
//

import addy_shared
import SwiftUI

struct AddRecipientPublicGpgKeyBottomSheet: View {
    @Environment(\.dismiss) var dismiss

    @State private var publicGpgKey: String = ""
    @State private var publicGpgKeyValidationError: String?
    @State private var publicGpgKeyRequestError: String?
    @State var isLoadingSaveButton: Bool = false

    let recipientId: String
    let onKeyAdded: (Recipients) -> Void

    init(recipientId: String, onKeyAdded: @escaping (Recipients) -> Void) {
        self.recipientId = recipientId
        self.onKeyAdded = onKeyAdded
    }

    var body: some View {
        #if DEBUG
            let _ = Self._printChanges()
        #endif
        Form {
            Section {
                ValidatingTextField(value: self.$publicGpgKey, placeholder: String(localized: "public_key_placeholder"), fieldType: .bigText, error: $publicGpgKeyValidationError)

            } header: {
                VStack(alignment: .leading) {
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
                        .onAppear {
                            HapticHelper.playHapticFeedback(hapticType: .error)
                        }
                }
            }.textCase(nil)
        }
        .navigationTitle(String(localized: "add_public_gpg_key"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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
                    Label(String(localized: "cancel", bundle: Bundle(for: SharedData.self)), systemImage: "xmark")
                }
            }
        }
    }

    private func saveButton() -> some View {
        Group {
            if isLoadingSaveButton {
                ProgressView().progressViewStyle(.circular)
            } else {
                Button {
                    // Since the ValidatingTextField is also handling validationErrors (and resetting these errors on every change)
                    // We should not allow any saving until the validationErrors are nil
                    if publicGpgKeyValidationError == nil {
                        isLoadingSaveButton = true

                        Task {
                            await self.addGpgKeyHttp(publicGpgKey: self.publicGpgKey)
                        }
                    } else {
                        isLoadingSaveButton = false
                    }
                } label: {
                    Text(String(localized: "add"))
                }
            }
        }
    }

    private func addGpgKeyHttp(publicGpgKey: String) async {
        publicGpgKeyRequestError = nil
        do {
            let recipient = try await RecipientRepository.shared.addEncryptionKey(recipientId: recipientId, keyData: publicGpgKey)
            onKeyAdded(recipient)
        } catch {
            isLoadingSaveButton = false
            publicGpgKeyRequestError = error.localizedDescription
        }
    }
}

#Preview {
    AddRecipientPublicGpgKeyBottomSheet(recipientId: "000", onKeyAdded: { _ in
        // Dummy function for preview
    })
}
