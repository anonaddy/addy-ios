//
//  ActionBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 08/06/2024.
//

import SwiftUI
import AVFoundation
import addy_shared

struct ActionBottomSheet: View {
    
    
    @State private var value = ""
    @State private var valuePlaceHolder = String(localized: "enter_value")
    @State private var valuePlaceHolderValidationError:String?
    
    
    @State private var selectedActionsType = "subject"
    let actionsType = ["subject", "displayFrom", "encryption", "banner", "block"]
    let actionsTypeName = [
        NSLocalizedString("replace_the_subject_with", comment: ""),
        NSLocalizedString("replace_the_from_name_with", comment: ""),
        NSLocalizedString("turn_PGP_encryption_off", comment: ""),
        NSLocalizedString("set_the_banner_information_location_to", comment: ""),
        NSLocalizedString("block_the_email", comment: "")
    ]
    
    @State private var selectedBannerLocationOptions = "top"
    let bannerLocationOptions = ["top", "bottom", "off"]
    let bannerLocationOptionName = [
        NSLocalizedString("rule_bannerlocation_top", comment: ""),
        NSLocalizedString("rule_bannerlocation_bottom", comment: ""),
        NSLocalizedString("rule_bannerlocation_off", comment: "")
    ]
    
    
    private var actionEditObject:Action?
    
    let onAddedAction: (Action?, Action) -> Void
    
    init(actionEditObject: Action?, onAddedAction: @escaping (Action?, Action) -> Void) {
        self.onAddedAction = onAddedAction
        self.actionEditObject = actionEditObject
    }
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form{
            
            Section {
                
                
                Picker(selection: $selectedActionsType, label: Text(String(localized: "select"))) {
                    ForEach(actionsTypeName, id: \.self) {
                        let typeIndex = actionsTypeName.firstIndex(of: $0) ?? 0
                        let tag = actionsType[typeIndex]
                        Text($0).tag(tag)
                    }
                }.pickerStyle(.menu)
                
                if (selectedActionsType == "banner"){
                    Picker(selection: $selectedBannerLocationOptions, label: Text(String(localized: "banner_location"))) {
                        ForEach(bannerLocationOptionName, id: \.self) {
                            let bannerLocationOptionIndex = bannerLocationOptionName.firstIndex(of: $0) ?? 0
                            let tag = bannerLocationOptions[bannerLocationOptionIndex]
                            Text($0).tag(tag)
                        }
                    }.pickerStyle(.menu)
                }
                
                if (selectedActionsType == "subject" ||
                    selectedActionsType == "displayFrom"){
                    ValidatingTextField(value: self.$value, placeholder: self.$valuePlaceHolder, fieldType: .text, error: $valuePlaceHolderValidationError)
                    
                }
                
            } header: {
                VStack(alignment: .leading){
                    Text(String(localized: "add_action_desc"))
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                    
                }.textCase(nil)
            }
            
            Section {
                AddyButton(action: {
                    var newAction = Action(type: selectedActionsType, value: "")
                    
                    
                    // If the type is set to set banner information location get the value from the picker and use that
                    if (selectedActionsType == "banner"){
                        newAction.value = selectedBannerLocationOptions
                    }
                    // If the type is set to block email send a true
                    else if (selectedActionsType == "block"){
                        newAction.value = String(true)
                    }
                    // If the type is set to turn off PGP send a true
                    else if (selectedActionsType == "encryption"){
                        newAction.value = String(true)
                    }
                    else {
                        // Else just get the textfield value
                        newAction.value = self.value
                    }
                    
                    
                    self.onAddedAction(actionEditObject, newAction)
                }) {
                    Text(String(localized: "add")).foregroundColor(Color.white)
                }.frame(minHeight: 56)
            }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())
            
        }.navigationTitle(String(localized: "add_action")).pickerStyle(.navigationLink)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text(String(localized: "cancel"))
                    }
                    
                }
            })
            .onAppear(perform: {
                if let actionEditObject = actionEditObject {
                    
                    self.selectedActionsType = actionEditObject.type
                    
                    if actionEditObject.type == "banner"{
                        self.selectedBannerLocationOptions = actionEditObject.value
                    }
                    self.value = actionEditObject.value
                    
                }
            })
        
        
    }
    
}

#Preview {
    ActionBottomSheet(actionEditObject: nil, onAddedAction: { oldAction, modifiedAction in
        // Dummy function for preview
    })
}
