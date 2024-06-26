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
    @State private var selectedBannerLocationOptions = "top"
    
    
    @State var selectedRecipientChip:[String]
    @State var recipientsChips: [AddyChipModel] = [AddyChipModel(chipId: "loading_recipients", label: String(localized: "loading_recipients"))]

    
    private var actionEditObject:Action?
    private var recipients: [Recipients]
    
    let onAddedAction: (Action?, Action) -> Void
    
    init(recipients: [Recipients], actionEditObject: Action?, onAddedAction: @escaping (Action?, Action) -> Void) {
        self.onAddedAction = onAddedAction
        self.actionEditObject = actionEditObject
        self.recipients = recipients

        if actionEditObject?.type == "forwardTo"{
            self.selectedRecipientChip = [actionEditObject?.value ?? ""]
        } else {
            self.selectedRecipientChip = []
        }
    }
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
        Form{
            
            Section {
                
                
                Picker(selection: $selectedActionsType, label: Text(String(localized: "select"))) {
                    ForEach(RulesOption.actionsTypeName, id: \.self) {
                        let typeIndex = RulesOption.actionsTypeName.firstIndex(of: $0) ?? 0
                        let tag = RulesOption.actionsType[typeIndex]
                        Text($0).tag(tag)
                    }
                }.pickerStyle(.menu)
                
                if (selectedActionsType == "banner"){
                    Picker(selection: $selectedBannerLocationOptions, label: Text(String(localized: "banner_location"))) {
                        ForEach(RulesOption.bannerLocationOptionName, id: \.self) {
                            let bannerLocationOptionIndex = RulesOption.bannerLocationOptionName.firstIndex(of: $0) ?? 0
                            let tag = RulesOption.bannerLocationOptions[bannerLocationOptionIndex]
                            Text($0).tag(tag)
                        }
                    }.pickerStyle(.menu)
                }
                
                if (selectedActionsType == "subject" ||
                    selectedActionsType == "displayFrom"){
                    ValidatingTextField(value: self.$value, placeholder: self.$valuePlaceHolder, fieldType: .text, error: $valuePlaceHolderValidationError)
                    
                }
                
                if (selectedActionsType == "forwardTo"){
                    VStack(alignment: .leading) {
                        

                    AddyMultiSelectChipView(chips: $recipientsChips, selectedChips: $selectedRecipientChip, singleLine: false) { onTappedChip in
                        withAnimation {
                            if (selectedRecipientChip.contains(onTappedChip.chipId)){
                                // If the chip is already selected, remove all
                                selectedRecipientChip.removeAll()
                            } else {
                                // Else Remove all and select the tapped chip
                                selectedRecipientChip.removeAll()
                                selectedRecipientChip.append(onTappedChip.chipId)
                            }
                        }
                        
                    }
                    
                    if selectedRecipientChip.isEmpty{
                        Text(String(localized: "select_a_recipient"))
                            .foregroundColor(.red)
                            .font(.system(size: 15))
                            .multilineTextAlignment(.leading)
                            .padding([.horizontal], 0)
                            .onAppear{
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
                    
                }.textCase(nil).frame(maxWidth: .infinity, alignment: .center)
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
                    // If the type is set to remove attachments send a true
                    else if (selectedActionsType == "removeAttachments"){
                        newAction.value = String(true)
                    }
                    // If the type is set to forward to send selected recipientID
                    else if (selectedActionsType == "forwardTo"){
                        if selectedRecipientChip.isEmpty{
                            return
                        } else {
                            newAction.value = selectedRecipientChip.first!
                        }
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
                ToolbarItem(placement: .topBarTrailing) {
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
                
                // Load recipients
                
                recipientsChips = []
                recipients.forEach(){ recipient in
                    if recipient.email_verified_at != nil {
                        recipientsChips.append(AddyChipModel(chipId: recipient.id, label: recipient.email))
                    }
                }
            })
        
        
    }
    
}

#Preview {
    ActionBottomSheet(recipients: [], actionEditObject: nil, onAddedAction: { oldAction, modifiedAction in
        // Dummy function for preview
    })
}
