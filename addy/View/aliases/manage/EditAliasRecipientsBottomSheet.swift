//
//  EditAliasDescriptionBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 12/05/2024.
//

import SwiftUI
import AVFoundation
import addy_shared

struct EditAliasRecipientsBottomSheet: View {
    let aliasId: String
    let recipientsEdited: (Aliases) -> Void
    
    @State var recipientsLoaded: Bool = false
    @State var selectedChips: [String] = []
    @State var recipientsChips: [AddyChipModel] = [AddyChipModel(chipId: "loading_recipients", label: String(localized: "loading_recipients"))]

    init(aliasId: String, selectedRecipientsIds: [String]?, recipientsEdited: @escaping (Aliases) -> Void) {
        self.aliasId = aliasId
        self.selectedChips = selectedRecipientsIds ?? []
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
                
            
            } header: {
                VStack(alignment: .leading){
                    Text(String(localized: "alias_edit_recipients_desc"))
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
        let networkHelper = NetworkHelper()
        do {
            if let recipients = try await networkHelper.getRecipients(verifiedOnly: true) {
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
            if let alias = try await networkHelper.updateRecipientsSpecificAlias(aliasId: self.aliasId, recipients: selectedChips) {
                self.recipientsEdited(alias)
            }
        } catch {
            IsLoadingSaveButton = false
            recipientsRequestError = error.localizedDescription
        }
    }

}

#Preview {
    EditAliasRecipientsBottomSheet(aliasId: "000", selectedRecipientsIds: ["TEST"], recipientsEdited: { alias in
        // Dummy function for preview
    })
}
