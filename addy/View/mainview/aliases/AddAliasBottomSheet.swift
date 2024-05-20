//
//  EditAliasDescriptionBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 12/05/2024.
//

import SwiftUI

//
//  AddApiBottomSHeet.swift
//  addy
//
//  Created by Stijn van de Water on 07/05/2024.
//

import SwiftUI
import AVFoundation
import CodeScanner
import addy_shared

struct AddAliasBottomSheet: View {
    let onAdded: () -> Void
    @EnvironmentObject var mainViewState: MainViewState

    
    init(onAdded: @escaping () -> Void) {
        self.onAdded = onAdded
    }
    
    
    @State private var localPartValidationError:String?
    @State private var descriptionValidationError:String?
    
    @State private var showAlert: Bool = false
    @State private var errorAlertTitle = ""
    @State private var errorAlertMessage = ""
    
    @State private var domains: [String] = []
    @State private var sharedDomains: [String] = []
    @State private var formats: [[String]] =
    [[String(localized: "domains_format_random_characters", comment: ""), "random_characters"],
     [String(localized: "domains_format_uuid", comment: ""), "uuid"],
     [String(localized: "domains_format_random_words", comment: ""), "random_words"],
     [String(localized: "domains_format_custom", comment: ""), "custom"]]
    
    @State private var selectedDomain: String = ""
    
#if DEBUG
    @State private var selectedFormat: String = "custom"
#else
    @State private var selectedFormat: String = ""
#endif
    
    @State private var localPart: String = ""
    @State private var localPartPlaceholder: String = String(localized: "alias_local_part")
    @State private var description: String = ""
    @State private var descriptionPlaceholder: String = String(localized: "description")
    
    
    @State private var aliasError :String? = ""
    
    @State private var formatValidationError:Bool = false
    @State private var localPartError:Bool = false
    
    @State private var recipientsRequestError:String? = ""
    
    @State var recipientsLoaded: Bool = false
    @State var selectedRecipientChips: [String] = []
    @State var recipientsChips: [AddyChipModel] = [AddyChipModel(chipId: "loading_recipients", label: String(localized: "loading_recipients"))]
    
    @State var isLoadingAddButton: Bool = false
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        
        Form {
            Section{
                
                Picker(String(localized: "domain"), selection: $selectedDomain) {
                    ForEach(domains, id: \.self) { domain in
                        Text(domain).tag(domain)
                    }
                }
                
                
                
                Picker(String(localized: "alias_format"), selection: $selectedFormat) {
                    ForEach(formats, id: \.self) { format in
                        Text(format[0]).tag(format[1])
                    }
                }.foregroundColor(formatValidationError ? .red : nil)
                    .onChange(of: selectedFormat){
                        // When selecting another format it should reset the error
                        formatValidationError = false
                        aliasError = ""
                    }
                
                
                if (selectedFormat == "custom"){
                    ValidatingTextField(value: self.$localPart, placeholder: self.$localPartPlaceholder, fieldType: .text, error: $localPartValidationError, formStyling: true)
                        .foregroundColor(localPartError ? .red : nil)
                }
                
                
                
            } header: {
                VStack(alignment: .leading){
                    Text(String(format: String(localized: "add_alias_desc"), self.mainViewState.userResource!.username)).multilineTextAlignment(.center).textCase(nil)
                    Spacer(minLength: 25)
                    Text(String(localized: "alias"))
                    
                }
            } footer: {
                if let error = aliasError {
                    if (!error.isEmpty){
                        Text(error)
                            .foregroundColor(.red)
                            .font(.system(size: 15))
                            .multilineTextAlignment(.leading)
                            .padding([.horizontal], 0)
                            .onAppear{
                                UINotificationFeedbackGenerator().notificationOccurred(.error)

                            }
                    }
                }
                
            }
            Section {
                ValidatingTextField(value: self.$description, placeholder: self.$descriptionPlaceholder, fieldType: .bigText, error: $descriptionValidationError, formStyling: true)
            } header: {
                VStack(alignment: .leading){
                    Text(String(localized: "description"))
                    
                }
            }
            
            Section {
                AddyMultiSelectChipView(chips: $recipientsChips, selectedChips: $selectedRecipientChips, singleLine: false) { onTappedChip in
                    withAnimation {
                        if (selectedRecipientChips.contains(onTappedChip.chipId)){
                            if let index = selectedRecipientChips.firstIndex(of: onTappedChip.chipId) {
                                selectedRecipientChips.remove(at: index)
                            }
                        } else {
                            selectedRecipientChips.append(onTappedChip.chipId)
                        }
                    }
                    
                }.disabled(!recipientsLoaded)
            } header: {
                VStack(alignment: .leading){
                    Text(String(localized: "recipients"))
                    
                }
            }.listRowInsets(EdgeInsets()).padding(.horizontal, 8).padding(.vertical, 8)
            
            Section {
                AddyLoadingButton(action: {
                    addAlias()
                }, isLoading: $isLoadingAddButton) {
                    Text(String(localized: "add")).foregroundColor(Color.white)
                }.frame(minHeight: 56)
            }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())
            
            
            
            
        }.navigationTitle(String(localized: "add_alias")).pickerStyle(.navigationLink)
            .task {
                if (domains.isEmpty){
                    loadDomains()
                }
       
                // By default there is 1 chip. (the loading recipients...)
                if recipientsChips.contains(where: { $0.chipId == "loading_recipients" }) {
                    getAllRecipients()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                            ToolbarItem() {
                                Button {
                                    dismiss()
                                } label: {
                                    Label(String(localized: "dismiss"), systemImage: "xmark.circle.fill")
                                }

                            }
                        })
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(errorAlertTitle),
                    message: Text(errorAlertMessage)
                )
            }
                       
        
    }
    
    private func addAlias(){
        // Do all the check before creating the alias
        self.formatValidationError = false

        
        if selectedFormat == "random_words" {
            if (self.mainViewState.userResource!.hasUserFreeSubscription()){
                self.aliasError = String(localized: "domains_format_random_words_not_available_for_this_subscription")
                self.formatValidationError = true
                
                // TODO: workaround, fix
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isLoadingAddButton = false
                }
                
                return
            }
        } else if selectedFormat == "custom" {
            if sharedDomains.contains(selectedDomain){
                self.aliasError = String(localized: "domains_format_custom_not_available_for_this_domain")
                self.formatValidationError = true
                
                // TODO: workaround, fix
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isLoadingAddButton = false
                } 
                return
            }
            
            if localPart.isEmpty {
                self.aliasError = String(localized: "this_field_cannot_be_empty")
                self.localPartError = true
                
                // TODO: workaround, fix
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isLoadingAddButton = false
                }
                return
            }
        }
        
        
        DispatchQueue.global(qos: .background).async {
            addAliasToAccount(selectedDomain: selectedDomain, description: description, selectedFormat: selectedFormat, localPart: localPart, selectedRecipients: selectedRecipientChips)
        }
    }
    

    
    private func addAliasToAccount(selectedDomain: String, description: String, selectedFormat:String, localPart: String, selectedRecipients:[String]){
        let networkHelper = NetworkHelper()
        networkHelper.addAlias(completion: { alias, result in
            if let alias = alias {
                //TODO:  let user know
                UIPasteboard.general.setValue(alias.email,forPasteboardType: UTType.plainText.identifier)
                self.onAdded()
            } else {
                isLoadingAddButton = false
                showAlert = true
                errorAlertTitle = String(localized: "error_adding_alias")
                errorAlertMessage = result ?? String(localized: "error_unknown_refer_to_logs")
            }
        }, domain: selectedDomain, description: description, format: selectedFormat, localPart: localPart, recipients: selectedRecipients)
    }
    
    private func loadDomains() {
        let networkHelper = NetworkHelper()
        networkHelper.getDomainOptions(completion: { domainOptions, _ in
            
            if let domainOptions = domainOptions {
                DispatchQueue.main.async {
                    domains = domainOptions.data
                    sharedDomains = domainOptions.sharedDomains
                    selectedDomain = domainOptions.defaultAliasDomain
                    selectedFormat = domainOptions.defaultAliasFormat
                }
            }
        })
    }
    
    
    private func getAllRecipients() {
        let networkHelper = NetworkHelper()
        networkHelper.getRecipients(verifiedOnly: true, completion: { recipients, error in
            DispatchQueue.main.async {
                recipientsChips = []
                recipientsLoaded = true
                if let recipients = recipients {
                    withAnimation {
                        recipients.forEach(){ recipient in
                            recipientsChips.append(AddyChipModel(chipId: recipient.id, label: recipient.email))
                        }
                    }
                    
                } else {
                    print("Error: \(String(describing: error))")
                    recipientsRequestError = error
                }
            }
        })
    }
    
    
    
    //    private func editFromName(fromName:String?) {
    //       addAliasRequestError = nil
    //
    //        let networkHelper = NetworkHelper()
    //        networkHelper.updateFromNameSpecificAlias(completion: { alias, error in
    //            DispatchQueue.main.async {
    //                if let alias = alias {
    //                    self.fromNameEdited(alias)
    //                } else {
    //                    IsLoadingSaveButton = false
    //                    addAliasRequestError = error
    //                }
    //            }
    //        }, aliasId: self.aliasId, fromName: fromName)
    //    }
}

#Preview {
    AddAliasBottomSheet(onAdded: {
        // Dummy function for preview
    })
}
