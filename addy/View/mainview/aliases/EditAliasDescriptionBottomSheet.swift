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
    let descriptionEdited: (Aliases) -> Void

    init(aliasId: String, description: String, descriptionEdited: @escaping (Aliases) -> Void) {
        self.aliasId = aliasId
        self.description = description
        self.descriptionEdited = descriptionEdited
    }
    
    @State private var descriptionError:String?

    @State var IsLoadingSaveButton: Bool = false
    
    var body: some View {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        VStack{
            
            Text(String(localized: "edit_description"))
                .font(.system(.title2))
                .fontWeight(.medium)
                .padding(.top, 25)
                .padding(.bottom, 15)
            
            Divider()
            
            ScrollView {

                VStack{
                    
                    Text(String(localized: "edit_desc_alias_desc"))
                        .font(.system(.footnote))
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .opacity(0.5)
                    
                    Spacer(minLength: 25)
                    
                    
                    
                    ValidatingTextField(value: self.$description, placeholder: String(localized: "description"), fieldType: .bigText, error: $descriptionError)
                    
                    
                }.padding(.vertical)
                
                
                AddyLoadingButton(action: {
                    if (descriptionError == nil){
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

                
                
            }
            .padding(.horizontal)
            
        }.presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        
        
    }
    
    
    private func editDescription(description:String?) {
        let networkHelper = NetworkHelper()
        networkHelper.updateDescriptionSpecificAlias(completion: { alias, error in
            DispatchQueue.main.async {
                if let alias = alias {
                    self.descriptionEdited(alias)
                } else {
                    IsLoadingSaveButton = false
                    descriptionError = error
                }
            }
        }, aliasId: self.aliasId, description: self.description)
    }
}

#Preview {
    EditAliasDescriptionBottomSheet(aliasId: "000", description: "TEST", descriptionEdited: { alias in
        // Dummy function for preview
    })
}
