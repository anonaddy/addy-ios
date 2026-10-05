//
//  EditAliasRecipientsBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 12/05/2024.
//

import addy_shared
import SwiftUI

struct EditAliasRecipientsBottomSheet: View {
    @Environment(\.dismiss) var dismiss

    @State var recipientsLoaded: Bool = false
    @State var selectedChips: [String] = []
    @State var recipientsChips: [AddyChipModel] = [AddyChipModel(chipId: "loading_recipients", label: String(localized: "loading_recipients"))]
    @State private var recipientsRequestError: String? = ""
    @State var isLoadingSaveButton: Bool = false

    let aliasId: String
    let recipientsEdited: (Aliases) -> Void

    init(aliasId: String, selectedRecipientsIds: [String]?, recipientsEdited: @escaping (Aliases) -> Void) {
        self.aliasId = aliasId
        self._selectedChips = State(initialValue: selectedRecipientsIds ?? [])
        self.recipientsEdited = recipientsEdited
    }

    var body: some View {
        #if DEBUG
            let _ = Self._printChanges()
        #endif
        Form {
            Section {
                AddyMultiSelectChipView(chips: $recipientsChips, selectedChips: $selectedChips, singleLine: false) { onTappedChip in
                    withAnimation {
                        if selectedChips.contains(onTappedChip.chipId) {
                            if let index = selectedChips.firstIndex(of: onTappedChip.chipId) {
                                selectedChips.remove(at: index)
                            }
                        } else {
                            selectedChips.append(onTappedChip.chipId)
                        }
                    }

                }.disabled(!recipientsLoaded)

            } header: {
                VStack(alignment: .leading) {
                    Text(String(localized: "alias_edit_recipients_desc"))
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
            let alias = try await AliasRepository.shared.updateRecipients(aliasId: aliasId, recipients: selectedChips)
            recipientsEdited(alias)
        } catch {
            isLoadingSaveButton = false
            recipientsRequestError = error.localizedDescription
        }
    }
}

#Preview {
    EditAliasRecipientsBottomSheet(aliasId: "000", selectedRecipientsIds: ["TEST"], recipientsEdited: { _ in
        // Dummy function for preview
    })
}
