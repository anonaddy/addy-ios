//
//  EditAliasFromNameBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 12/05/2024.
//

import SwiftUI
import AVFoundation
import CodeScanner
import addy_shared

struct EditAliasFromNameBottomSheet: View {
    let aliasId: String
    let aliasEmail: String
    @State var fromName: String
    @State var fromNamePlaceholder: String = String(localized: "from_name")
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
    @Environment(\.dismiss) var dismiss

    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
            Form {
                
                Section{
                    ValidatingTextField(value: self.$fromName, placeholder: self.$fromNamePlaceholder, fieldType: .text, error: $fromNameValidationError)
                    
                } header: {
                    VStack(alignment: .leading){
                        let formattedString = String.localizedStringWithFormat(NSLocalizedString("edit_from_name_alias_desc", comment: ""), aliasEmail)
                        Text(LocalizedStringKey(formattedString))
                            .multilineTextAlignment(.center)
                            .padding(.bottom)
                    }.frame(maxWidth: .infinity, alignment: .center)
                } footer: {
                    if let error = fromNameRequestError {
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
                        if (fromNameValidationError == nil){
                            IsLoadingSaveButton = true;
                            
                            Task {
                                await self.editFromName(fromName: self.fromName)
                            }
                        } else {
                                IsLoadingSaveButton = false
                            
                        }
                    }, isLoading: $IsLoadingSaveButton) {
                        Text(String(localized: "save")).foregroundColor(Color.white)
                    }.frame(minHeight: 56)
                }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())
                
                
                
                
            }.navigationTitle(String(localized: "edit_from_name")).pickerStyle(.navigationLink)
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
    
    
    private func editFromName(fromName: String?) async {
        fromNameRequestError = nil
        let networkHelper = NetworkHelper()
        do {
            if let alias = try await networkHelper.updateFromNameSpecificAlias(aliasId: self.aliasId, fromName: fromName){
                self.fromNameEdited(alias)
            }
        } catch {
            IsLoadingSaveButton = false
            fromNameRequestError = error.localizedDescription
        }
    }

}

#Preview {
    EditAliasFromNameBottomSheet(aliasId: "000", aliasEmail: "TEST", fromName: "NICE", fromNameEdited: { alias in
        // Dummy function for preview
    })
}
