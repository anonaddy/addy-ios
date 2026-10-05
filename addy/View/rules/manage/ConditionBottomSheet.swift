//
//  ConditionBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 08/06/2024.
//

import addy_shared
import SwiftUI

struct ConditionBottomSheet: View {
    @Environment(\.dismiss) var dismiss

    @State private var value = ""
    @State private var valuePlaceHolder = String(localized: "enter_values_comma_separated")
    @State private var valuePlaceHolderValidationError: String?
    @State private var selectedConditionType = "sender"
    @State private var selectedConditionMatch = "contains"

    private var conditionEditObject: Condition?
    let onAddedCondition: (Condition?, Condition) -> Void

    var body: some View {
        #if DEBUG
            let _ = Self._printChanges()
        #endif
        Form {
            Section {
                Picker(selection: $selectedConditionType, label: Text(String(localized: "select"))) {
                    ForEach(RulesOption.conditionsTypeName, id: \.self) {
                        let typeIndex = RulesOption.conditionsTypeName.firstIndex(of: $0) ?? 0
                        let tag = RulesOption.conditionsType[typeIndex]
                        Text($0).tag(tag)
                    }
                }.pickerStyle(.menu)
                .onChange(of: selectedConditionType) { _, newType in
                    let availableMatches = RulesOption.matches(for: newType)
                    if !availableMatches.contains(selectedConditionMatch) {
                        selectedConditionMatch = availableMatches.first ?? ""
                    }
                    updatePlaceholder(for: newType)
                    valuePlaceHolderValidationError = nil
                }

                if !RulesOption.isBooleanCondition(type: selectedConditionType) {
                    let matches = RulesOption.matches(for: selectedConditionType)
                    let matchNames = RulesOption.matchNames(for: selectedConditionType)
                    Picker(selection: $selectedConditionMatch, label: Text(String(localized: "match"))) {
                        ForEach(matchNames, id: \.self) {
                            let typeIndex = matchNames.firstIndex(of: $0) ?? 0
                            let tag = matches[typeIndex]
                            Text($0).tag(tag)
                        }
                    }.pickerStyle(.menu)

                    ValidatingTextField(
                        value: self.$value,
                        placeholder: self.$valuePlaceHolder,
                        fieldType: RulesOption.isNumericCondition(type: selectedConditionType) ? .numeric : (RulesOption.isHeaderCondition(type: selectedConditionType) ? .text : .bigText),
                        error: $valuePlaceHolderValidationError
                    )
                }

            } header: {
                VStack {
                    Text(String(localized: "add_condition_desc"))
                        .multilineTextAlignment(.center)
                        .padding(.bottom)

                }.frame(maxWidth: .infinity, alignment: .center)
            }.textCase(nil)

        }.navigationTitle(String(localized: "add_condition"))
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
                if let conditionEditObject = conditionEditObject {
                    self.selectedConditionType = conditionEditObject.type
                    let availableMatches = RulesOption.matches(for: conditionEditObject.type)
                    self.selectedConditionMatch = conditionEditObject.match ?? (availableMatches.first ?? "")
                    self.value = conditionEditObject.values?.joined(separator: ",") ?? ""
                } else {
                    let availableMatches = RulesOption.matches(for: selectedConditionType)
                    if !availableMatches.contains(selectedConditionMatch) {
                        selectedConditionMatch = availableMatches.first ?? ""
                    }
                }
                updatePlaceholder(for: selectedConditionType)
            })
    }

    private func updatePlaceholder(for conditionType: String) {
        if RulesOption.isHeaderCondition(type: conditionType) {
            valuePlaceHolder = String(localized: "enter_header_name")
        } else if conditionType == "email_size" {
            valuePlaceHolder = String(localized: "enter_size_in_bytes")
        } else if conditionType == "alias_emails_forwarded" {
            valuePlaceHolder = String(localized: "enter_email_count")
        } else {
            valuePlaceHolder = String(localized: "enter_values_comma_separated")
        }
    }

    private func saveButton() -> some View {
        Button {
            if RulesOption.isBooleanCondition(type: self.selectedConditionType) {
                let condition = Condition(type: self.selectedConditionType, match: nil, values: nil)
                self.onAddedCondition(conditionEditObject, condition)
            } else {
                if self.value.trimmingCharacters(in: .whitespaces).isEmpty {
                    valuePlaceHolderValidationError = String(localized: "this_field_cannot_be_empty")
                    return
                }
                let valuesList = self.value.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                let condition = Condition(type: self.selectedConditionType, match: self.selectedConditionMatch, values: valuesList)
                self.onAddedCondition(conditionEditObject, condition)
            }
        } label: {
            if conditionEditObject != nil {
                Text(String(localized: "save"))
            } else {
                Text(String(localized: "add"))
            }
        }
    }

    init(conditionEditObject: Condition?, onAddedCondition: @escaping (Condition?, Condition) -> Void) {
        self.onAddedCondition = onAddedCondition
        self.conditionEditObject = conditionEditObject
    }
}

#Preview {
    ConditionBottomSheet(conditionEditObject: nil, onAddedCondition: { _, _ in
        // Dummy function for preview
    })
}
