//
//  AliasDetailView.swift
//  addy
//
//  Created by Stijn van de Water on 08/05/2024.
//

import SwiftUI
import addy_shared
import Lottie
import UniformTypeIdentifiers

struct RecipientsDetailView: View {
    
    enum ActiveAlert {
        case reachedMaxAliases, deleteAliases, restoreAlias, forgetAlias, error
    }
    
    let recipientId: String
    let recipientEmail: String
        
    @State private var activeAlert: ActiveAlert = .reachedMaxAliases
    @State private var showAlert: Bool = false
    @State private var isDeletingRecipient: Bool = false
    
    @State private var errorAlertTitle = ""
    @State private var errorAlertMessage = ""
    @EnvironmentObject var mainViewState: MainViewState
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    @State private var recipient: Recipients? = nil
    @State private var errorText: String? = nil
    
    @State private var isAliasActive: Bool = false
    @State private var isSwitchingAliasActiveState: Bool = false
    @State private var isAliasBeingWatched: Bool = false
    @State private var isPresentingEditAliasDescriptionBottomSheet = false
    @State private var isPresentingEditAliasRecipientsBottomSheet = false
    @State private var isPresentingEditAliasFromNameBottomSheet = false
    @State private var isPresentingEditAliasSendMailRecipientBottomSheet = false
    
    
    init(recipientId: String, recipientEmail: String) {
        self.recipientId = recipientId
        self.recipientEmail = recipientEmail
    }
    
    
    var body: some View {
        
        if let recipient = recipient {
            Form {
               
                
                Section {
                    
                    Text("TODO")
                    
                    
                }header: {
                    Text(String(localized: "general"))
                }
                
                Section {
                    
//                    // If alias is not deleted, show the delete button section
//                    if alias.deleted_at == nil {
//                        AddySectionButton(title: String(localized: "delete_alias"), description: String(localized: "delete_alias_desc"),
//                                          leadingSystemimage: "trash", colorAccent: .softRed, isLoading: isDeletingAlias){
//                            activeAlert = .deleteAliases
//                            showAlert = true
//                        }
//                    }
//                    
//                    // If alias is deleted, show the restore button section
//                    if alias.deleted_at != nil {
//                        AddySectionButton(title: String(localized: "restore_alias"), description: String(localized: "restore_alias_desc"),
//                                          leadingSystemimage: "arrow.up.trash", colorAccent: .accentColor, isLoading: isRestoringAlias){
//                            activeAlert = .restoreAlias
//                            showAlert = true
//                        }
//                    }
//                    
//                    AddySectionButton(title: String(localized: "forget_alias"), description: String(localized: "forget_alias_desc"),
//                                      leadingSystemimage: "eraser", colorAccent: .red, isLoading: isForgettingAlias){
//                        activeAlert = .forgetAlias
//                        showAlert = true
//                    }
                    
                }
                
            }.disabled(isDeletingRecipient)
            .navigationTitle(self.recipientEmail)
            .navigationBarTitleDisplayMode(.inline)
//            .sheet(isPresented: $isPresentingEditAliasDescriptionBottomSheet) {
//                NavigationStack {
//                    EditAliasDescriptionBottomSheet(aliasId: alias.id, description: alias.description ?? ""){ alias in
//                        self.alias = alias
//                        isPresentingEditAliasDescriptionBottomSheet = false
//                    }
//                }
//            }
//            .sheet(isPresented: $isPresentingEditAliasRecipientsBottomSheet) {
//                NavigationStack {
//                    EditAliasRecipientsBottomSheet(aliasId: alias.id, selectedRecipientsIds: getRecipientsIds(recipients: alias.recipients)){ alias in
//                        self.alias = alias
//                        isPresentingEditAliasRecipientsBottomSheet = false
//                        
//                    }
//                }
//            }
//            .sheet(isPresented: $isPresentingEditAliasFromNameBottomSheet) {
//                NavigationStack {
//                    EditAliasFromNameBottomSheet(aliasId: alias.id, aliasEmail: alias.email, fromName: alias.from_name){ alias in
//                        self.alias = alias
//                        isPresentingEditAliasFromNameBottomSheet = false
//                        
//                    }
//                }
//            }
//            .sheet(isPresented: $isPresentingEditAliasSendMailRecipientBottomSheet) {
//                NavigationStack {
//                    EditAliasSendMailRecipientBottomSheet(aliasEmail: alias.email){ addresses in
//                        self.onPressSend(toString: addresses)
//                        isPresentingEditAliasSendMailRecipientBottomSheet = false
//                        
//                    }
//                }
//            }
//            .alert(isPresented: $showAlert) {
//                        switch activeAlert {
//                        case .reachedMaxAliases:
//                            return Alert(title: Text(String(localized: "aliaswatcher_max_reached")), message: Text(String(localized: "aliaswatcher_max_reached_desc")), dismissButton: .default(Text(String(localized: "understood"))))
//                        case .deleteAliases:
//                            return Alert(title: Text(String(localized: "delete_alias")), message: Text(String(localized: "delete_alias_confirmation_desc")), primaryButton: .destructive(Text(String(localized: "delete"))){
//                                isDeletingAlias = true
//                                
//                                DispatchQueue.global(qos: .background).async {
//                                    deleteAlias(alias: alias)
//                                }
//                            }, secondaryButton: .cancel())
//                        case .restoreAlias:
//                            return Alert(title: Text(String(localized: "restore_alias")), message: Text(String(localized: "restore_alias_confirmation_desc")), primaryButton: .default(Text(String(localized: "restore"))){
//                                isRestoringAlias = true
//                                
//                                DispatchQueue.global(qos: .background).async {
//                                    restoreAlias(alias: alias)
//                                }
//                            }, secondaryButton: .cancel())
//                        case .forgetAlias:
//                            return Alert(title: Text(String(localized: "forget_alias")), message: Text(String(localized: "forget_alias_confirmation_desc")), primaryButton: .destructive(Text(String(localized: "forget"))){
//                                isForgettingAlias = true
//                                
//                                DispatchQueue.global(qos: .background).async {
//                                    forgetAlias(alias: alias)
//                                }
//                            }, secondaryButton: .cancel())
//                        case .error:
//                            return Alert(
//                                title: Text(errorAlertTitle),
//                                message: Text(errorAlertMessage)
//                            )
//                        }
//                    }
            
        } else {

            VStack {
                if let errorText = errorText
                {
                    ContentUnavailableView {
                       Label(String(localized: "error_obtaining_recipient"), systemImage: "questionmark")
                   } description: {
                       Text(errorText)
                   }.onAppear{
                       HapticHelper.playHapticFeedback(hapticType: .error)
                   }
                } else {
                    VStack(spacing: 20) {
                        LottieView(animation: .named("gray_ic_loading_logo.shapeshifter"))
                            .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                            .animationSpeed(Double(2))
                            .frame(maxHeight: 128)
                            .opacity(0.5)
                        
                    }
                }
            }.task {
                getRecipient(recipientId: self.recipientId)
            }
           
            .navigationTitle(self.recipientEmail)
            .navigationBarTitleDisplayMode(.inline)
        }
        
    }
    
    private func getFromName(alias: Aliases) -> String {
        
        
        if mainViewState.userResource!.hasUserFreeSubscription() {
            return String(localized: "feature_not_available_subscription")
        }
        else {
            // Set description based on alias.from_name and initialize the bottom dialog fragment
            if let fromName = alias.from_name {
                return fromName
            } else {
                return String(localized: "alias_no_from_name")
            }
            
        }
        
    }
    
    private func updateUi(recipient: Recipients){
//        var aliasTotalCount =  Double(alias.emails_forwarded + alias.emails_replied + alias.emails_sent + alias.emails_blocked)
//        aliasTotalCount = aliasTotalCount != 0.0 ? aliasTotalCount : 10.0 // To prevent dividing by 0
//        
//        
//        let aliasEmailForwardedProgress =  (Double(alias.emails_forwarded) / aliasTotalCount) * 100
//        let aliasEmailRepliedProgress = (Double(alias.emails_replied) / aliasTotalCount) * 100
//        let aliasEmailSentProgress = (Double(alias.emails_sent) / aliasTotalCount) * 100
//        let aliasEmailBlockedProgress = (Double(alias.emails_blocked) / aliasTotalCount) * 100
//        
        
    }
    
    private func deleteAlias(alias:Aliases) {
        let networkHelper = NetworkHelper()
        networkHelper.deleteAlias(completion: { result in
            DispatchQueue.main.async {
                self.isDeletingRecipient = false
                
                if result == "204" {
                    // TODO: Let the recipientView know this alias is deleted/restores/forgotten so it can refresh the data
                    self.presentationMode.wrappedValue.dismiss()
                } else {
                    activeAlert = .error
                    showAlert = true
                    errorAlertTitle = String(localized: "error_deleting_recipient")
                    errorAlertMessage = result ?? String(localized: "error_unknown_refer_to_logs")
                }
            }
        },aliasId: alias.id)
    }
    
   
    
    private func getRecipient(recipientId: String) {
        let networkHelper = NetworkHelper()
        networkHelper.getSpecificRecipient(completion: { recipient, error in
            DispatchQueue.main.async {
                if let recipient = recipient {
                    withAnimation {
                        self.recipient = recipient
                        self.updateUi(recipient: recipient)
                    }
                    
                } else {
                    withAnimation {
                        self.errorText = error
                    }
                }
            }
        },recipientId: recipientId)
    }
}


#Preview {
    RecipientsDetailView(recipientId: "6a866f49-5a0b-4c7e-bc45-f46bf019c4ed", recipientEmail: "PLACEHOLDER")
}
