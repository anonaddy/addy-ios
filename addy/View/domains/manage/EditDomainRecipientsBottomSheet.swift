//
//  EditDomainRecipientsBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 03/06/2024.
//

import SwiftUI
import AVFoundation
import CodeScanner
import addy_shared

struct EditDomainRecipientsBottomSheet: View {
    let domainId: String
    let recipientsEdited: (Domains) -> Void
    
    @State var recipientsLoaded: Bool = false
    @State var selectedRecipientChip:[String]
    @State var recipientsChips: [AddyChipModel] = [AddyChipModel(chipId: "loading_recipients", label: String(localized: "loading_recipients"))]

    init(domainId: String, selectedRecipientId: String?, recipientsEdited: @escaping (Domains) -> Void) {
        self.domainId = domainId
        self.selectedRecipientChip = selectedRecipientId != nil ? [selectedRecipientId!] : []
        self.recipientsEdited = recipientsEdited
    }
    
    @State private var recipientsRequestError:String? = ""

    @State var IsLoadingSaveButton: Bool = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
        Form{
            
        
            Section {

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
                    
                }.disabled(!recipientsLoaded)
                
            
            } header: {
                VStack {
                    Text(String(localized: "domain_edit_recipient_desc"))
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                    
                }.frame(maxWidth: .infinity, alignment: .center)
            } footer: {
                if let error = recipientsRequestError {
                    if (!error.isEmpty){
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
            }.textCase(nil).listRowInsets(EdgeInsets()).padding(.horizontal, 8).padding(.vertical, 8)
            
            Section {
                AddyLoadingButton(action: {
                        IsLoadingSaveButton = true;
                        
                        Task {
                            await self.editRecipients()
                        }
                    
                }, isLoading: $IsLoadingSaveButton) {
                    Text(String(localized: "save")).foregroundColor(Color.white)
                }.frame(minHeight: 56)

            }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())
            
        }.navigationTitle(String(localized: "edit_recipients")).pickerStyle(.navigationLink)
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
            .task{
                await getAllRecipients()
            }
        
    }
    
    
    
    
    private func getAllRecipients() async {
        recipientsRequestError = nil
        let networkHelper = NetworkHelper()
        do {
            if let recipients = try await networkHelper.getRecipients(verifiedOnly: true){
                recipientsChips = []
                recipientsLoaded = true
                withAnimation {
                    recipients.forEach { recipient in
                        recipientsChips.append(AddyChipModel(chipId: recipient.id, label: recipient.email))
                    }
                }
            }
        } catch {
            recipientsRequestError = error.localizedDescription
        }
    }

    

    private func editRecipients() async {
        recipientsRequestError = nil
        let networkHelper = NetworkHelper()
        do {
            if let domain = try await networkHelper.updateDefaultRecipientForSpecificDomain(domainId: self.domainId, recipientId: selectedRecipientChip.first){
                self.recipientsEdited(domain)
            }
        } catch {
            IsLoadingSaveButton = false
            recipientsRequestError = error.localizedDescription
        }
    }

}

#Preview {
    EditDomainRecipientsBottomSheet(domainId: "000", selectedRecipientId: nil, recipientsEdited: { domain in
        // Dummy function for preview
    })
}
