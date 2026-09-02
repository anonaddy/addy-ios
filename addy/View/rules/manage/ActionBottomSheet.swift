//
//  ActionBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 08/06/2024.
//

import addy_shared
import AVFoundation
import SwiftUI
import WrappingHStack

struct ActionBottomSheet: View {
    @Environment(\.dismiss) var dismiss

    @State private var value = ""
    @State private var valuePlaceHolder = String(localized: "enter_value")
    @State private var valuePlaceHolderValidationError: String?
    @State private var selectedActionsType = "subject"
    @State private var selectedBannerLocationOptions = "top"
    @State var selectedRecipientChip: [String]
    @State var recipientsChips: [AddyChipModel] = [AddyChipModel(chipId: "loading_recipients", label: String(localized: "loading_recipients"))]
    @State private var selectedLabel = ""
    @State private var allLabels: [AddyChipModel] = [AddyChipModel(chipId: "loading_labels", label: String(localized: "loading_labels"))]
    @State private var labelsLoaded: Bool = false
    @State private var isPresentingAddLabelBottomSheet = false

    private var actionEditObject: Action?
    private var recipients: [Recipients]
    let onAddedAction: (Action?, Action) -> Void

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
                .onChange(of: selectedActionsType) { _, newType in
                    updatePlaceholder(for: newType)
                    valuePlaceHolderValidationError = nil
                }

                if selectedActionsType == "banner" {
                    Picker(selection: $selectedBannerLocationOptions, label: Text(String(localized: "banner_location"))) {
                        ForEach(RulesOption.bannerLocationOptionName, id: \.self) {
                            let bannerLocationOptionIndex = RulesOption.bannerLocationOptionName.firstIndex(of: $0) ?? 0
                            let tag = RulesOption.bannerLocationOptions[bannerLocationOptionIndex]
                            Text($0).tag(tag)
                        }
                    }.pickerStyle(.menu)
                }

                if RulesOption.isTextAction(type: selectedActionsType) {
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

                if RulesOption.isLabelAction(type: selectedActionsType) {
                    VStack(alignment: .leading, spacing: 8) {
                        if !labelsLoaded {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else if allLabels.isEmpty {
                            Text(String(localized: "no_labels"))
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        } else {
                            WrappingHStack(alignment: .leading, horizontalSpacing: 4, verticalSpacing: 4) {
                                ForEach(allLabels) { label in
                                    ChipView(label: label.label, isSelected: selectedLabel == label.label, color: Color(hex: label.color ?? "FFFFFF"))
                                        .onTapGesture {
                                            withAnimation {
                                                if selectedLabel == label.label {
                                                    selectedLabel = ""
                                                } else {
                                                    selectedLabel = label.label
                                                }
                                            }
                                        }
                                }
                            }
                        }

                        if labelsLoaded && selectedLabel.isEmpty {
                            Text(String(localized: "select_a_label"))
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

                if RulesOption.isLabelAction(type: selectedActionsType) {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            isPresentingAddLabelBottomSheet = true
                        } label: {
                            Label(String(localized: "add_label"), systemImage: "plus")
                        }
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
            .sheet(isPresented: $isPresentingAddLabelBottomSheet) {
                NavigationStack {
                    AddLabelBottomSheet { newLabel in
                        if let newLabel = newLabel {
                            let chip = AddyChipModel(chipId: newLabel.id, label: newLabel.name, color: newLabel.colour)
                            allLabels.append(chip)
                            selectedLabel = newLabel.name
                        }
                        isPresentingAddLabelBottomSheet = false
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .task {
                await getAllLabels()
            }
            .onAppear(perform: {
                if let actionEditObject = actionEditObject {
                    self.selectedActionsType = actionEditObject.type

                    if actionEditObject.type == "banner" {
                        self.selectedBannerLocationOptions = actionEditObject.value
                    } else if RulesOption.isLabelAction(type: actionEditObject.type) {
                        self.selectedLabel = actionEditObject.value
                    }
                    self.value = actionEditObject.value
                }

                updatePlaceholder(for: selectedActionsType)

                // Load recipients

                recipientsChips = []
                for recipient in recipients {
                    if recipient.email_verified_at != nil {
                        recipientsChips.append(AddyChipModel(chipId: recipient.id, label: recipient.email))
                    }
                }
            })
    }

    private func updatePlaceholder(for actionType: String) {
        if actionType == "setAliasDescription" {
            valuePlaceHolder = String(localized: "enter_description")
        } else {
            valuePlaceHolder = String(localized: "enter_value")
        }
    }

    private func saveButton() -> some View {
        AnyView(
            Button {
                var newAction = Action(type: selectedActionsType, value: "")

                // If the type is set to set banner information location get the value from the picker and use that
                if selectedActionsType == "banner" {
                    newAction.value = selectedBannerLocationOptions
                }
                // If the type is a boolean action, send "true"
                else if RulesOption.isBooleanAction(type: selectedActionsType) {
                    newAction.value = String(true)
                }
                // If the type is set to forward to send selected recipientID
                else if selectedActionsType == "forwardTo" {
                    if selectedRecipientChip.isEmpty {
                        return
                    } else {
                        newAction.value = selectedRecipientChip.first!
                    }
                } else if RulesOption.isLabelAction(type: selectedActionsType) {
                    if selectedLabel.isEmpty {
                        return
                    }
                    newAction.value = selectedLabel
                } else if RulesOption.isTextAction(type: selectedActionsType) {
                    if self.value.trimmingCharacters(in: .whitespaces).isEmpty {
                        valuePlaceHolderValidationError = String(localized: "this_field_cannot_be_empty")
                        return
                    }
                    newAction.value = self.value.trimmingCharacters(in: .whitespaces)
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

    private func getAllLabels(forceReload: Bool = false) async {
        if !labelsLoaded || forceReload {
            let networkHelper = NetworkHelper()
            do {
                if let labels = try await networkHelper.getAllLabels()?.data {
                    self.allLabels = []
                    for label in labels {
                        self.allLabels.append(AddyChipModel(chipId: label.id, label: label.name, color: label.colour))
                    }
                    labelsLoaded = true
                }
            } catch {
                // Ignore or handle
            }
        }
    }

    init(recipients: [Recipients], actionEditObject: Action?, onAddedAction: @escaping (Action?, Action) -> Void) {
        self.onAddedAction = onAddedAction
        self.actionEditObject = actionEditObject
        self.recipients = recipients

        if actionEditObject?.type == "forwardTo" {
            _selectedRecipientChip = State(initialValue: [actionEditObject?.value ?? ""])
            _selectedLabel = State(initialValue: "")
        } else if let action = actionEditObject, RulesOption.isLabelAction(type: action.type) {
            _selectedRecipientChip = State(initialValue: [])
            _selectedLabel = State(initialValue: action.value)
        } else {
            _selectedRecipientChip = State(initialValue: [])
            _selectedLabel = State(initialValue: "")
        }
    }
}

#Preview {
    ActionBottomSheet(recipients: [], actionEditObject: nil, onAddedAction: { _, _ in
        // Dummy function for preview
    })
}
