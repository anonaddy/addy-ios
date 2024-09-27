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
    @State private var selectedConditionMatch = "contains"

    
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
                
                Picker(selection: $selectedConditionType, label: Text(String(localized: "select"))) {
                    ForEach(RulesOption.conditionsTypeName, id: \.self) {
                        let typeIndex = RulesOption.conditionsTypeName.firstIndex(of: $0) ?? 0
                        let tag = RulesOption.conditionsType[typeIndex]
                        Text($0).tag(tag)
                    }
                }.pickerStyle(.menu)
                
                Picker(selection: $selectedConditionMatch, label: Text(String(localized: "match"))) {
                    ForEach(RulesOption.conditionsMatchName, id: \.self) {
                        let typeIndex = RulesOption.conditionsMatchName.firstIndex(of: $0) ?? 0
                        let tag = RulesOption.conditionsMatch[typeIndex]
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
