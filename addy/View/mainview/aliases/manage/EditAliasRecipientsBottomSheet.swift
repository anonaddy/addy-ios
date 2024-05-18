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

struct EditAliasRecipientsBottomSheet: View {
    let aliasId: String
    let recipientsEdited: (Aliases) -> Void
    
    @State var recipientsLoaded: Bool = false
    @State var selectedChips: [String] = []
    @State var recipientsChips: [AddyChipModel] = [AddyChipModel(chipId: String(localized: "loading_recipients"), label: String(localized: "loading_recipients"))]

    init(aliasId: String, selectedRecipientsIds: [String]?, recipientsEdited: @escaping (Aliases) -> Void) {
        self.aliasId = aliasId
        self.selectedChips = selectedRecipientsIds ?? []
        self.recipientsEdited = recipientsEdited
    }
    
    @State private var recipientsRequestError:String? = ""

    @State var IsLoadingSaveButton: Bool = false
    
    var body: some View {
        VStack{
            
            Text(String(localized: "edit_recipients"))
                .font(.system(.title2))
                .fontWeight(.medium)
                .padding(.top, 25)
                .padding(.bottom, 15)
            
            Divider()
            
            ScrollView {

                VStack{
                    
                    Text(String(localized: "alias_edit_recipients_desc"))
                        .font(.system(.footnote))
                        .multilineTextAlignment(.center)
                        .opacity(0.5)
                    
                    Spacer(minLength: 25)
                    
                    
                    
                    AddyMultiSelectChipView(chips: $recipientsChips, selectedChips: $selectedChips, singleLine: false) { onTappedChip in
                        withAnimation {
                            if (selectedChips.contains(onTappedChip.chipId)){
                                if let index = selectedChips.firstIndex(of: onTappedChip.chipId) {
                                    selectedChips.remove(at: index)
                                }
                            } else {
                                selectedChips.append(onTappedChip.chipId)
                            }
                        }
                        
                    }.disabled(!recipientsLoaded)
                    
                }.padding(.vertical)
                
                VStack(alignment: .leading, spacing: 0) {
                    if let error = recipientsRequestError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.system(size: 15))
                            .multilineTextAlignment(.leading)
                            .padding([.horizontal], 0)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                AddyLoadingButton(action: {
                        IsLoadingSaveButton = true;
                        
                        DispatchQueue.global(qos: .background).async {
                            self.editRecipients()
                        }
                    
                }, isLoading: $IsLoadingSaveButton) {
                    Text(String(localized: "save")).foregroundColor(Color.white)
                }.frame(minHeight: 56)

                
                
            }
            .padding(.horizontal)
            
        }.presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .onAppear(perform: {
                getAllRecipients()
            })
        
        
    }
    
    
    
    
    private func getAllRecipients() {
        recipientsRequestError = nil
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
                    //self.showError = true
                }
            }
        })
    }
    
    
    private func editRecipients() {
        recipientsRequestError = nil
        let networkHelper = NetworkHelper()
        networkHelper.updateRecipientsSpecificAlias(completion: { alias, error in
            DispatchQueue.main.async {
                if let alias = alias {
                    self.recipientsEdited(alias)
                } else {
                    IsLoadingSaveButton = false
                    recipientsRequestError = error
                }
            }
        }, aliasId: self.aliasId, recipients: selectedChips)
    }
}

#Preview {
    EditAliasRecipientsBottomSheet(aliasId: "000", selectedRecipientsIds: ["TEST"], recipientsEdited: { alias in
        // Dummy function for preview
    })
}
