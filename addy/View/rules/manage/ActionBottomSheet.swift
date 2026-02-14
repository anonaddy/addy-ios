//
//  ActionBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 08/06/2024.
//

import addy_shared
import AVFoundation
import SwiftUI

struct ActionBottomSheet: View {
    @State private var value = ""
    @State private var valuePlaceHolder = String(localized: "enter_value")
    @State private var valuePlaceHolderValidationError: String?

    @State private var selectedActionsType = "subject"
    @State private var selectedBannerLocationOptions = "top"

    @State var selectedRecipientChip: [String]
    @State var recipientsChips: [AddyChipModel] = [AddyChipModel(chipId: "loading_recipients", label: String(localized: "loading_recipients"))]

    private var actionEditObject: Action?
    private var recipients: [Recipients]

    let onAddedAction: (Action?, Action) -> Void

    init(recipients: [Recipients], actionEditObject: Action?, onAddedAction: @escaping (Action?, Action) -> Void) {
        self.onAddedAction = onAddedAction
        self.actionEditObject = actionEditObject
        self.recipients = recipients

        if actionEditObject?.type == "forwardTo" {
            selectedRecipientChip = [actionEditObject?.value ?? ""]
        } else {
            selectedRecipientChip = []
        }
    }

    @Environment(\.dismiss) var dismiss

    var body: some View {
        #if DEBUG
            let _ = Self._printChanges()
        #endif
        Form {
            Section {
                Picker(selection: $selectedActionsType, label: Text(String(localized: "select"))) {
                    ForEach(RulesOption.actionsTypeName, id: \.self) {
                        let typeIndex = RulesOption.actionsTypeName.firstIndex(of: $0) ?? 0
                        let tag = RulesOption.actionsType[typeIndex]
                        Text($0).tag(tag)
                    }
                }.pickerStyle(.menu)

                if selectedActionsType == "banner" {
                    Picker(selection: $selectedBannerLocationOptions, label: Text(String(localized: "banner_location"))) {
                        ForEach(RulesOption.bannerLocationOptionName, id: \.self) {
                            let bannerLocationOptionIndex = RulesOption.bannerLocationOptionName.firstIndex(of: $0) ?? 0
                            let tag = RulesOption.bannerLocationOptions[bannerLocationOptionIndex]
                            Text($0).tag(tag)
                        }
                    }.pickerStyle(.menu)
                }

                if selectedActionsType == "subject" ||
                    selectedActionsType == "displayFrom"
                {
                    ValidatingTextField(value: self.$value, placeholder: self.$valuePlaceHolder, fieldType: .text, error: $valuePlaceHolderValidationError)
                    
                }

                if selectedActionsType == "forwardTo" {
                    VStack(alignment: .leading) {
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
                        }

                        if selectedRecipientChip.isEmpty {
                            Text(String(localized: "select_a_recipient"))
                                .foregroundColor(.red)
                                .font(.system(size: 15))
                                .multilineTextAlignment(.leading)
                                .padding([.horizontal], 0)
                                .onAppear {
                                    HapticHelper.playHapticFeedback(hapticType: .error)
                                }
                        }
                    }
                }

            } header: {
                VStack {
                    Text(String(localized: "add_action_desc"))
                        .multilineTextAlignment(.center)
                        .padding(.bottom)

                }.frame(maxWidth: .infinity, alignment: .center)
            } footer: {
                if selectedActionsType == "subject" {
                    Text(String(localized: "add_action_subject_info"))
              }
            }.textCase(nil)

        }.navigationTitle(String(localized: "add_action")).pickerStyle(.navigationLink)
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
            .onAppear(perform: {
                if let actionEditObject = actionEditObject {
                    self.selectedActionsType = actionEditObject.type

                    if actionEditObject.type == "banner" {
                        self.selectedBannerLocationOptions = actionEditObject.value
                    }
                    self.value = actionEditObject.value
                }

                // Load recipients

                recipientsChips = []
                for recipient in recipients {
                    if recipient.email_verified_at != nil {
                        recipientsChips.append(AddyChipModel(chipId: recipient.id, label: recipient.email))
                    }
                }
            })
    }

    private func saveButton() -> some View {
        AnyView(
            Button {
                var newAction = Action(type: selectedActionsType, value: "")

                // If the type is set to set banner information location get the value from the picker and use that
                if selectedActionsType == "banner" {
                    newAction.value = selectedBannerLocationOptions
                }
                // If the type is set to block email send a true
                else if selectedActionsType == "block" {
                    newAction.value = String(true)
                }
                // If the type is set to turn off PGP send a true
                else if selectedActionsType == "encryption" {
                    newAction.value = String(true)
                }
                // If the type is set to remove attachments send a true
                else if selectedActionsType == "removeAttachments" {
                    newAction.value = String(true)
                }
                // If the type is set to forward to send selected recipientID
                else if selectedActionsType == "forwardTo" {
                    if selectedRecipientChip.isEmpty {
                        return
                    } else {
                        newAction.value = selectedRecipientChip.first!
                    }
                } else {
                    // Else just get the textfield value
                    newAction.value = self.value
                }

                self.onAddedAction(actionEditObject, newAction)
            } label: {
                if actionEditObject != nil {
                    Text(String(localized: "save"))
                } else {
                    Text(String(localized: "add"))
                }
            }
        )
    }
}

#Preview {
    ActionBottomSheet(recipients: [], actionEditObject: nil, onAddedAction: { _, _ in
        // Dummy function for preview
    })
}
