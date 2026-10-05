//
//  EditUsernameRecipientsBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 01/06/2024.
//

import addy_shared
import SwiftUI

struct EditUsernameRecipientsBottomSheet: View {
    @Environment(\.dismiss) var dismiss

    @State var recipientsLoaded: Bool = false
    @State var selectedRecipientChip: [String]
    @State var recipientsChips: [AddyChipModel] = [AddyChipModel(chipId: "loading_recipients", label: String(localized: "loading_recipients"))]
    @State private var recipientsRequestError: String? = ""
    @State var isLoadingSaveButton: Bool = false

    let usernameId: String
    let recipientsEdited: (Usernames) -> Void

    init(usernameId: String, selectedRecipientId: String?, recipientsEdited: @escaping (Usernames) -> Void) {
        self.usernameId = usernameId
        self._selectedRecipientChip = State(initialValue: selectedRecipientId != nil ? [selectedRecipientId!] : [])
        self.recipientsEdited = recipientsEdited
    }

    var body: some View {
        #if DEBUG
            let _ = Self._printChanges()
        #endif
        Form {
            Section {
                AddyMultiSelectChipView(chips: $recipientsChips, selectedChips: $selectedRecipientChip, singleLine: false) { onTappedChip in
                    withAnimation {
                        if selectedRecipientChip.contains(onTappedChip.chipId) {
                            // If the chip is already selected, remove all
                            selectedRecipientChip.removeAll()
                        } else {
                            // Else Remove all and select the tapped chip
                            selectedRecipientChip.removeAll()
                            selectedRecipientChip.append(onTappedChip.chipId)
                        }
                    }

                }.disabled(!recipientsLoaded)

            } header: {
                VStack(alignment: .leading) {
                    Text(String(localized: "username_edit_recipient_desc"))
                        .multilineTextAlignment(.center)
                        .padding(.bottom)

                }.frame(maxWidth: .infinity, alignment: .center)
            } footer: {
                if let error = recipientsRequestError {
                    if !error.isEmpty {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.system(size: 15))
                            .multilineTextAlignment(.leading)
                            .padding([.horizontal], 0)
                            .onAppear {
                                HapticHelper.playHapticFeedback(hapticType: .error)
                            }
                    }
                }
            }.textCase(nil).listRowInsets(EdgeInsets()).padding(.horizontal, 8).padding(.vertical, 8)

        }
        .navigationTitle(String(localized: "edit_recipients"))
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
        .task {
            await getAllRecipients()
        }
    }

    private func saveButton() -> some View {
        Group {
            if isLoadingSaveButton {
                ProgressView().progressViewStyle(.circular)
            } else {
                Button {
                    isLoadingSaveButton = true

                    Task {
                        await self.editRecipients()
                    }
                } label: {
                    Text(String(localized: "save"))
                }.disabled(!recipientsLoaded)
            }
        }
    }

    private func getAllRecipients() async {
        recipientsRequestError = nil
        do {
            let recipients = try await RecipientRepository.shared.getRecipients(verifiedOnly: true)
            recipientsChips = []
            recipientsLoaded = true
            withAnimation {
                for recipient in recipients {
                    recipientsChips.append(AddyChipModel(chipId: recipient.id, label: recipient.email))
                }
            }
        } catch {
            recipientsRequestError = error.localizedDescription
        }
    }

    private func editRecipients() async {
        recipientsRequestError = nil
        do {
            let username = try await UsernameRepository.shared.updateDefaultRecipient(usernameId: usernameId, recipientId: selectedRecipientChip.first)
            recipientsEdited(username)
        } catch {
            isLoadingSaveButton = false
            recipientsRequestError = error.localizedDescription
        }
    }
}

#Preview {
    EditUsernameRecipientsBottomSheet(usernameId: "000", selectedRecipientId: nil, recipientsEdited: { _ in
        // Dummy function for preview
    })
}
