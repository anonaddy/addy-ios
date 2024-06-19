//
//  ConditionBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 08/06/2024.
//

import SwiftUI
import AVFoundation
import addy_shared

struct ConditionBottomSheet: View {
    
    
    @State private var value = ""
    @State private var valuePlaceHolder = String(localized: "enter_values_comma_separated")
    @State private var valuePlaceHolderValidationError:String?
    
    
    @State private var selectedConditionType = "sender"
    let conditionsType = ["sender", "subject", "alias"]
    let conditionsTypeName = [
        NSLocalizedString("the_sender", comment: ""),
        NSLocalizedString("the_subject", comment: ""),
        NSLocalizedString("the_alias", comment: "")
    ]
    
    @State private var selectedConditionMatch = "contains"
    let conditionsMatch = ["contains", "does not contain", "is exactly", "is not", "starts with", "does not start with", "ends with", "does not end with"]
    let conditionsMatchName = [
        NSLocalizedString("contains", comment: ""),
        NSLocalizedString("does_not_contain", comment: ""),
        NSLocalizedString("is_exactly", comment: ""),
        NSLocalizedString("is_not", comment: ""),
        NSLocalizedString("starts_with", comment: ""),
        NSLocalizedString("does_not_start_with", comment: ""),
        NSLocalizedString("ends_with", comment: ""),
        NSLocalizedString("does_not_end_with", comment: "")
    ]
    
    
    private var conditionEditObject:Condition?
    
    let onAddedCondition: (Condition?, Condition) -> Void
    
    init(conditionEditObject: Condition?, onAddedCondition: @escaping (Condition?, Condition) -> Void) {
        self.onAddedCondition = onAddedCondition
        self.conditionEditObject = conditionEditObject
    }
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
        Form{
            
            Section {
                
                //TODO: The checkmark next to selected pickeritems is at default value instead of the selected item
                Picker(selection: $selectedConditionType, label: Text(String(localized: "select"))) {
                    ForEach(conditionsTypeName, id: \.self) {
                        let typeIndex = conditionsTypeName.firstIndex(of: $0) ?? 0
                        let tag = conditionsType[typeIndex]
                        Text($0).tag(tag)
                    }
                }.pickerStyle(.menu)
                
                Picker(selection: $selectedConditionMatch, label: Text(String(localized: "match"))) {
                    ForEach(conditionsMatchName, id: \.self) {
                        let typeIndex = conditionsMatchName.firstIndex(of: $0) ?? 0
                        let tag = conditionsMatch[typeIndex]
                        Text($0).tag(tag)
                    }
                }.pickerStyle(.menu)
                
                
                ValidatingTextField(value: self.$value, placeholder: self.$valuePlaceHolder, fieldType: .bigText, error: $valuePlaceHolderValidationError)
                
            } header: {
                VStack {
                    Text(String(localized: "add_condition_desc"))
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                    
                }.textCase(nil).frame(maxWidth: .infinity, alignment: .center)
            }
            
            Section {
                AddyButton(action: {
                    let condition = Condition(type: self.selectedConditionType, match: self.selectedConditionMatch, values: self.value.split(separator: ",").map { String($0) })
                    self.onAddedCondition(conditionEditObject, condition)
                }) {
                    Text(String(localized: "add")).foregroundColor(Color.white)
                }.frame(minHeight: 56)
            }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())
            
        }.navigationTitle(String(localized: "add_condition")).pickerStyle(.navigationLink)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text(String(localized: "cancel"))
                    }
                    
                }
            })
            .onAppear(perform: {
                if let conditionEditObject = conditionEditObject {
                    
                    self.selectedConditionType = conditionEditObject.type
                    self.selectedConditionMatch = conditionEditObject.match
                    self.value = conditionEditObject.values.joined(separator: ",")
                    
                }
            })
        
        
    }
    
}

#Preview {
    ConditionBottomSheet(conditionEditObject: nil, onAddedCondition: { oldCondition, modifiedCondition in
        // Dummy function for preview
    })
}
