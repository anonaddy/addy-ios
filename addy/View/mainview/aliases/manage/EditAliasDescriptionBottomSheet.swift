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

struct EditAliasDescriptionBottomSheet: View {
    let aliasId: String
    @State private var description: String
    @State private var descriptionPlaceholder: String = String(localized: "description")
    let descriptionEdited: (Aliases) -> Void

    init(aliasId: String, description: String, descriptionEdited: @escaping (Aliases) -> Void) {
        self.aliasId = aliasId
        self.description = description
        self.descriptionEdited = descriptionEdited
    }
    
    @State private var descriptionValidationError:String?
    @State private var descriptionRequestError:String?

    @State var IsLoadingSaveButton: Bool = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Form{

            Section {

                
                ValidatingTextField(value: self.$description, placeholder: self.$descriptionPlaceholder, fieldType: .bigText, error: $descriptionValidationError, formStyling: true)

                

                
                
            } header: {
                VStack(alignment: .leading){
                    Text(String(localized: "edit_desc_alias_desc"))
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                    
                }.textCase(nil)
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
                        
                        DispatchQueue.global(qos: .background).async {
                            self.editDescription(description: self.description)
                        }
                    } else {
                        DispatchQueue.main.async {
                            IsLoadingSaveButton = false
                        }
                    }
                }, isLoading: $IsLoadingSaveButton) {
                    Text(String(localized: "save")).foregroundColor(Color.white)
                }.frame(minHeight: 56)
            }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())
            
            }.navigationTitle(String(localized: "edit_description")).pickerStyle(.navigationLink)
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
        
        
    }
    
    
    private func editDescription(description:String?) {
        descriptionRequestError = nil
        
        let networkHelper = NetworkHelper()
        networkHelper.updateDescriptionSpecificAlias(completion: { alias, error in
            DispatchQueue.main.async {
                if let alias = alias {
                    self.descriptionEdited(alias)
                } else {
                    IsLoadingSaveButton = false
                    descriptionRequestError = error
                }
            }
        }, aliasId: self.aliasId, description: description)
    }
}

#Preview {
    EditAliasDescriptionBottomSheet(aliasId: "000", description: "TEST", descriptionEdited: { alias in
        // Dummy function for preview
    })
}
