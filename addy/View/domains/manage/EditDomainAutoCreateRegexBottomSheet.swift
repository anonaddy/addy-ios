//
//  EditDomainAutoCreateRegexBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 26/07/2024.
//

import SwiftUI
import AVFoundation
import addy_shared

struct EditDomainAutoCreateRegexBottomSheet: View {
    let domainId: String
    let domain: String
    @State var autoCreateRegex: String
    @State var autoCreateRegexPlaceholder: String = String(localized: "auto_create_regex_hint")
    let autoCreateRegexEdited: (Domains) -> Void

    init(domainId: String, domain: String, autoCreateRegex: String?, autoCreateRegexEdited: @escaping (Domains) -> Void) {
        self.domainId = domainId
        self.domain = domain
        self.autoCreateRegex = autoCreateRegex ?? ""
        self.autoCreateRegexEdited = autoCreateRegexEdited
    }
    
    @State private var autoCreateRegexValidationError:String?
    @State private var autoCreateRegexRequestError:String?

    @State var IsLoadingSaveButton: Bool = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
            Form {
                
                Section{
                    ValidatingTextField(value: self.$autoCreateRegex, placeholder: self.$autoCreateRegexPlaceholder, fieldType: .text, error: $autoCreateRegexValidationError)
                    
                } header: {
                    VStack(alignment: .leading){
                        let formattedString = String.localizedStringWithFormat(NSLocalizedString("edit_auto_create_regex_desc", comment: ""), domain)
                        Text(LocalizedStringKey(formattedString))
                            .multilineTextAlignment(.center)
                            .padding(.bottom)
                    }.frame(maxWidth: .infinity, alignment: .center)
                } footer: {
                    if let error = autoCreateRegexRequestError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.system(size: 15))
                            .multilineTextAlignment(.leading)
                            .padding([.horizontal], 0)
                            .onAppear{
                                HapticHelper.playHapticFeedback(hapticType: .error)
                            }
                    }
                
                }.textCase(nil)
                
                Section{
                    AddyLoadingButton(action: {
                        // Since the ValidatingTextField is also handling validationErrors (and resetting these errors on every change)
                        // We should not allow any saving until the validationErrors are nil
                        if (autoCreateRegexValidationError == nil){
                            IsLoadingSaveButton = true;
                            
                            Task {
                                await self.editautoCreateRegex(autoCreateRegex: self.autoCreateRegex)
                            }
                        } else {
                                IsLoadingSaveButton = false
                        }
                    }, isLoading: $IsLoadingSaveButton) {
                        Text(String(localized: "save")).foregroundColor(Color.white)
                    }.frame(minHeight: 56)
                }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())
                
                
                
                
            }.navigationTitle(String(localized: "edit_auto_create_regex")).pickerStyle(.navigationLink)
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
            
            
        
    }
    
    
    private func editautoCreateRegex(autoCreateRegex: String?) async {
        autoCreateRegexRequestError = nil
        let networkHelper = NetworkHelper()
        do {
            if let domain = try await networkHelper.updateAutoCreateRegexSpecificDomain(domainId: self.domainId, autoCreateRegex: autoCreateRegex) {
                self.autoCreateRegexEdited(domain)
            }
        } catch {
            IsLoadingSaveButton = false
            autoCreateRegexRequestError = error.localizedDescription
        }
    }

}

#Preview {
    EditDomainAutoCreateRegexBottomSheet(domainId: "000", domain: "TEST", autoCreateRegex: "NICE", autoCreateRegexEdited: { domain in
        // Dummy function for preview
    })
}
