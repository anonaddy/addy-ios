//
//  EditUsernameFromNameBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 01/06/2024.
//

import addy_shared
import AVFoundation
import SwiftUI

struct EditUsernameFromNameBottomSheet: View {
    @Environment(\.dismiss) var dismiss

    @State var fromName: String
    @State var fromNamePlaceholder: String = .init(localized: "from_name")
    @State private var fromNameValidationError: String?
    @State private var fromNameRequestError: String?
    @State var IsLoadingSaveButton: Bool = false

    let usernameId: String
    let username: String
    let fromNameEdited: (Usernames) -> Void

    var body: some View {
        #if DEBUG
            let _ = Self._printChanges()
        #endif
        Form {
            Section {
                ValidatingTextField(value: self.$fromName, placeholder: self.$fromNamePlaceholder, fieldType: .text, error: $fromNameValidationError)

            } header: {
                VStack(alignment: .leading) {
                    let formattedString = String.localizedStringWithFormat(NSLocalizedString("edit_from_name_username_desc", comment: ""), username)
                    Text(LocalizedStringKey(formattedString))
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                }.frame(maxWidth: .infinity, alignment: .center)
            } footer: {
                if let error = fromNameRequestError {
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
        }.navigationTitle(String(localized: "edit_from_name")).pickerStyle(.navigationLink)
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
                        if fromNameValidationError == nil {
                            IsLoadingSaveButton = true

                            Task {
                                await self.editFromName(fromName: self.fromName)
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

    init(usernameId: String, username: String, fromName: String?, fromNameEdited: @escaping (Usernames) -> Void) {
        self.usernameId = usernameId
        self.username = username
        self.fromName = fromName ?? ""
        self.fromNameEdited = fromNameEdited
    }

    private func editFromName(fromName: String?) async {
        fromNameRequestError = nil
        let networkHelper = NetworkHelper()
        do {
            if let username = try await networkHelper.updateFromNameSpecificUsername(usernameId: usernameId, fromName: fromName) {
                fromNameEdited(username)
            }
        } catch {
            IsLoadingSaveButton = false
            fromNameRequestError = error.localizedDescription
        }
    }
}

#Preview {
    EditUsernameFromNameBottomSheet(usernameId: "000", username: "TEST", fromName: "NICE", fromNameEdited: { _ in
        // Dummy function for preview
    })
}
