//
//  EditDomainDescriptionBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 03/06/2024.
//

import SwiftUI
import AVFoundation
import addy_shared

struct EditDomainDescriptionBottomSheet: View {
    let domainId: String
    @State private var description: String
    @State private var descriptionPlaceholder: String = String(localized: "description")
    let descriptionEdited: (Domains) -> Void

    init(domainId: String, description: String, descriptionEdited: @escaping (Domains) -> Void) {
        self.domainId = domainId
        self.description = description
        self.descriptionEdited = descriptionEdited
    }
    
    @State private var descriptionValidationError:String?
    @State private var descriptionRequestError:String?

    @State var IsLoadingSaveButton: Bool = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
        Form{

            Section {

                
                ValidatingTextField(value: self.$description, placeholder: self.$descriptionPlaceholder, fieldType: .bigText, error: $descriptionValidationError)

                

                
                
            } header: {
                VStack {
                    Text(String(localized: "edit_desc_domain_desc"))
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                    
                }.textCase(nil).frame(maxWidth: .infinity, alignment: .center)
            } footer: {
                if let error = descriptionRequestError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.system(size: 15))
                        .multilineTextAlignment(.leading)
                        .padding([.horizontal], 0)
                        .onAppear{
                            HapticHelper.playHapticFeedback(hapticType: .error)
                                                        }
                }
            }
            
            Section {
                AddyLoadingButton(action: {
                    // Since the ValidatingTextField is also handling validationErrors (and resetting these errors on every change)
                    // We should not allow any saving until the validationErrors are nil
                    if (descriptionValidationError == nil){
                        IsLoadingSaveButton = true;
                        
                        Task {
                            await self.editDescription(description: self.description)
                        }
                    } else {
                            IsLoadingSaveButton = false
                        
                    }
                }, isLoading: $IsLoadingSaveButton) {
                    Text(String(localized: "save")).foregroundColor(Color.white)
                }.frame(minHeight: 56)
            }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())
            
            }.navigationTitle(String(localized: "edit_description")).pickerStyle(.navigationLink)
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
    
    
    private func editDescription(description: String?) async {
        descriptionRequestError = nil
        let networkHelper = NetworkHelper()
        do {
            if let domain = try await networkHelper.updateDescriptionSpecificDomain(domainId: self.domainId, description: description) {
                self.descriptionEdited(domain)
            }
        } catch {
            IsLoadingSaveButton = false
            descriptionRequestError = error.localizedDescription
        }
    }

}

#Preview {
    EditDomainDescriptionBottomSheet(domainId: "000", description: "TEST", descriptionEdited: { domain in
        // Dummy function for preview
    })
}
