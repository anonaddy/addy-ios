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

struct EditAliasFromNameBottomSheet: View {
    let aliasId: String
    let aliasEmail: String
    @State var fromName: String
    let fromNameEdited: (Aliases) -> Void

    init(aliasId: String, aliasEmail: String, fromName: String?, fromNameEdited: @escaping (Aliases) -> Void) {
        self.aliasId = aliasId
        self.aliasEmail = aliasEmail
        self.fromName = fromName ?? ""
        self.fromNameEdited = fromNameEdited
    }
    
    @State private var fromNameValidationError:String?
    @State private var fromNameRequestError:String?

    @State var IsLoadingSaveButton: Bool = false
    
    var body: some View {
        VStack{
            
            Text(String(localized: "edit_from_name"))
                .font(.system(.title2))
                .padding(.top, 25)
                .padding(.bottom, 15)
            
            Divider()
            
            ScrollView {

                VStack{
                    
                    let formattedString = String.localizedStringWithFormat(NSLocalizedString("edit_from_name_alias_desc", comment: ""), aliasEmail)
                    // Use Text with markdown to display the formatted string
                    Text(LocalizedStringKey(formattedString))
                        .font(.system(.footnote))
                        .multilineTextAlignment(.center)
                        .opacity(0.5)
                    
                    Spacer(minLength: 25)
                    
                    
                    
                    ValidatingTextField(value: self.$fromName, placeholder: String(localized: "from_name"), fieldType: .text, error: $fromNameValidationError)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        if let error = fromNameRequestError {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.system(size: 15))
                                .multilineTextAlignment(.leading)
                                .padding([.horizontal], 0)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                }.padding(.vertical)
                
                
                AddyLoadingButton(action: {
                    // Since the ValidatingTextField is also handling validationErrors (and resetting these errors on every change)
                    // We should not allow any saving until the validationErrors are nil
                    if (fromNameValidationError == nil){
                        IsLoadingSaveButton = true;
                        
                        DispatchQueue.global(qos: .background).async {
                            self.editFromName(fromName: self.fromName)
                        }
                    } else {
                        DispatchQueue.main.async {
                            IsLoadingSaveButton = false
                        }
                    }
                }, isLoading: $IsLoadingSaveButton) {
                    Text(String(localized: "save")).foregroundColor(Color.white)
                }.frame(minHeight: 56)

                
                
            }
            .padding(.horizontal)
            
        }.presentationDetents([.large])
            .presentationDragIndicator(.visible)
        
        
    }
    
    
    private func editFromName(fromName:String?) {
        fromNameRequestError = nil
        
        let networkHelper = NetworkHelper()
        networkHelper.updateFromNameSpecificAlias(completion: { alias, error in
            DispatchQueue.main.async {
                if let alias = alias {
                    self.fromNameEdited(alias)
                } else {
                    IsLoadingSaveButton = false
                    fromNameRequestError = error
                }
            }
        }, aliasId: self.aliasId, fromName: fromName)
    }
}

#Preview {
    EditAliasFromNameBottomSheet(aliasId: "000", aliasEmail: "TEST", fromName: "NICE", fromNameEdited: { alias in
        // Dummy function for preview
    })
}
