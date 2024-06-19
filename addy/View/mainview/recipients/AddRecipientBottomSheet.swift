//
//  AddRecipientBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 12/05/2024.
//

import SwiftUI


import SwiftUI
import AVFoundation
import CodeScanner
import addy_shared

struct AddRecipientBottomSheet: View {
    @State var address: String = ""
    @State var addressPlaceHolder: String = String(localized: "address")
    let onAdded: () -> Void

    init(onAdded: @escaping () -> Void) {
        self.onAdded = onAdded
    }
    
    @State private var recipientValidationError:String?
    @State private var recipientRequestError:String?

    @State var IsLoadingAddButton: Bool = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
            
            Form {
                
                Section{
                    ValidatingTextField(value: self.$address, placeholder: self.$addressPlaceHolder, fieldType: .email, error: $recipientValidationError)
                    
                } header: {
                    VStack(alignment: .leading){
                        let formattedString = String.localizedStringWithFormat(NSLocalizedString("add_recipient_desc", comment: ""))
                        Text(LocalizedStringKey(formattedString))
                            .multilineTextAlignment(.center)
                            .padding(.bottom)
                    }.frame(maxWidth: .infinity, alignment: .center)
                } footer: {
                    if let error = recipientRequestError {
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
                        if (recipientValidationError == nil){
                            IsLoadingAddButton = true;
                            
                            DispatchQueue.global(qos: .background).async {
                                self.addRecipientToAccount(address: self.address)
                            }
                        } else {
                            DispatchQueue.main.async {
                                IsLoadingAddButton = false
                            }
                        }
                    }, isLoading: $IsLoadingAddButton) {
                        Text(String(localized: "add")).foregroundColor(Color.white)
                    }.frame(minHeight: 56)
                }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())
                
                
                
                
            }.navigationTitle(String(localized: "add_recipient")).pickerStyle(.navigationLink)
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
    
    
    private func addRecipientToAccount(address:String) {
        recipientRequestError = nil
        
        let networkHelper = NetworkHelper()
        networkHelper.addRecipient(completion: { recipient, error in
            DispatchQueue.main.async {
                if recipient != nil {
                    self.onAdded()
                } else {
                    IsLoadingAddButton = false
                    recipientRequestError = error
                }
            }
        }, address: address)
    }
}

#Preview {
    AddRecipientBottomSheet() {
        // Dummy function for preview
    }
}
