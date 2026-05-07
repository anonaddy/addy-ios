//
//  EditUsernameAutoCreateRegexBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 26/07/2024.
//

import addy_shared
import AVFoundation
import SwiftUI

struct EditUsernameAutoCreateRegexBottomSheet: View {
    @Environment(\.dismiss) var dismiss

    @State var autoCreateRegex: String
    @State var autoCreateRegexPlaceholder: String = .init(localized: "auto_create_regex_hint")
    @State private var autoCreateRegexValidationError: String?
    @State private var autoCreateRegexRequestError: String?
    @State var IsLoadingSaveButton: Bool = false

    let usernameId: String
    let username: String
    let autoCreateRegexEdited: (Usernames) -> Void

    var body: some View {
        #if DEBUG
            let _ = Self._printChanges()
        #endif
        Form {
            Section {
                ValidatingTextField(value: self.$autoCreateRegex, placeholder: self.$autoCreateRegexPlaceholder, fieldType: .text, error: $autoCreateRegexValidationError)

            } header: {
                VStack(alignment: .leading) {
                    let formattedString = String.localizedStringWithFormat(NSLocalizedString("edit_auto_create_regex_desc", comment: ""), username)
                    Text(LocalizedStringKey(formattedString))
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                }.frame(maxWidth: .infinity, alignment: .center)
            } footer: {
                if let error = autoCreateRegexRequestError {
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
        }.navigationTitle(String(localized: "edit_auto_create_regex")).pickerStyle(.navigationLink)
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
                        Label(String(localized: "cancel", bundle: Bundle(for: SharedData.self)), systemImage: "xmark")
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
                        if autoCreateRegexValidationError == nil {
                            IsLoadingSaveButton = true

                            Task {
                                await self.editautoCreateRegex(autoCreateRegex: self.autoCreateRegex)
                            }
                        } else {
                            IsLoadingSaveButton = false
                        }
                    } label: {
                        Text(String(localized: "save"))
                    }
                )
            }
        }
    }

    init(usernameId: String, username: String, autoCreateRegex: String?, autoCreateRegexEdited: @escaping (Usernames) -> Void) {
        self.usernameId = usernameId
        self.username = username
        self.autoCreateRegex = autoCreateRegex ?? ""
        self.autoCreateRegexEdited = autoCreateRegexEdited
    }

    private func editautoCreateRegex(autoCreateRegex: String?) async {
        autoCreateRegexRequestError = nil
        let networkHelper = NetworkHelper()
        do {
            if let username = try await networkHelper.updateAutoCreateRegexSpecificUsername(usernameId: usernameId, autoCreateRegex: autoCreateRegex) {
                autoCreateRegexEdited(username)
            }
        } catch {
            IsLoadingSaveButton = false
            autoCreateRegexRequestError = error.localizedDescription
        }
    }
}

#Preview {
    EditUsernameAutoCreateRegexBottomSheet(usernameId: "000", username: "TEST", autoCreateRegex: "NICE", autoCreateRegexEdited: { _ in
        // Dummy function for preview
    })
}
