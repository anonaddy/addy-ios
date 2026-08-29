//
//  EditDomainRecipientsBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 03/06/2024.
//

import addy_shared
import SwiftUI

struct EditDomainRecipientsBottomSheet: View {
    @Environment(\.dismiss) var dismiss

    @State var recipientsLoaded: Bool = false
    @State var selectedRecipientChip: [String]
    @State var recipientsChips: [AddyChipModel] = [AddyChipModel(chipId: "loading_recipients", label: String(localized: "loading_recipients"))]
    @State private var recipientsRequestError: String? = ""
    @State var isLoadingSaveButton: Bool = false

    let domainId: String
    let recipientsEdited: (Domains) -> Void

    init(domainId: String, selectedRecipientId: String?, recipientsEdited: @escaping (Domains) -> Void) {
        self.domainId = domainId
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
                VStack {
                    Text(String(localized: "domain_edit_recipient_desc"))
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
            let domain = try await DomainRepository.shared.updateDefaultRecipient(domainId: domainId, recipientId: selectedRecipientChip.first)
            recipientsEdited(domain)
        } catch {
            isLoadingSaveButton = false
            recipientsRequestError = error.localizedDescription
        }
    }
}

#Preview {
    EditDomainRecipientsBottomSheet(domainId: "000", selectedRecipientId: nil, recipientsEdited: { _ in
        // Dummy function for preview
    })
}
