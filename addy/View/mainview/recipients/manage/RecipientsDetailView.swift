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
        case deleteRecipient, error, removePgpKey
    }
    
    let recipientId: String
    let recipientEmail: String
    
    @Binding var shouldReloadDataInParent: Bool

    
    @State private var activeAlert: ActiveAlert = .deleteRecipient
    @State private var showAlert: Bool = false
    @State private var isDeletingRecipient: Bool = false
    @State private var isRemovingPgpKey: Bool = false
    
    @State private var errorAlertTitle = ""
    @State private var errorAlertMessage = ""
    @EnvironmentObject var mainViewState: MainViewState
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @State private var recipient: Recipients? = nil
    @State private var errorText: String? = nil
    
    @State private var replySendAllowed: Bool = false
    @State private var shouldEncrypt: Bool = false
    @State private var inlineEncryption: Bool = false
    @State private var protectedHeaders: Bool = false
    @State private var isSwitchingRecipientShouldEncryptState: Bool = false
    @State private var isSwitchingInlineEncryptionState: Bool = false
    @State private var isSwitchingProtectedHeadersState: Bool = false
    @State private var isSwitchingRecipientCanReplySendState: Bool = false
    @State private var isPresentingAddRecipientPublicGpgKeyBottomSheet = false
    
    @State private var aliasList: [String] = []
    
    
    
    @State private var totalForwarded: Int = 0
    @State private var totalBlocked: Int = 0
    @State private var totalReplies: Int = 0
    @State private var totalSent: Int = 0
    
    
    
    init(recipientId: String, recipientEmail: String, shouldReloadDataInParent: Binding<Bool>) {
        self.recipientId = recipientId
        self.recipientEmail = recipientEmail
        _shouldReloadDataInParent = shouldReloadDataInParent
    }
    
    
    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
        
        if let recipient = recipient {
            Form {
                
                
                Section {
                    Text(String(format: String(localized: "manage_recipient_basic_info"),
                                recipient.email,
                                DateTimeUtils.turnStringIntoLocalString(recipient.created_at),
                                DateTimeUtils.turnStringIntoLocalString(recipient.updated_at),
                                String(totalForwarded), String(totalBlocked), String(totalReplies), String(totalSent)))
                    
                    
                }header: {
                    Text(String(localized: "basic"))
                }
                
                Section {
                    Text(aliasList.joined(separator: "\n"))
                        .font(.system(size: 14)) // Set initial font size
                        .minimumScaleFactor(0.5) // Set minimum scale factor to resize text
                        .padding(.top, 5)
                    
                    
                } header: {
                    Text(String(format: String(localized: "recipient_aliases_d"),
                                String(recipient.aliases_count ?? 0)))
                }
                
                Section {
                    if let fingerprint = recipient.fingerprint {
                        Text(String(format: String(localized: "fingerprint_s"),
                                    String(fingerprint)))
                    } else {
                        Text(String(localized: "encryption_disabled"))
                    }
                    
                } header: {
                    Text(String(localized: "encryption"))
                }
                
                Section {
                    
                    AddyToggle(isOn: $replySendAllowed, isLoading: isSwitchingRecipientCanReplySendState, title: recipient.can_reply_send ? String(localized: "can_reply_send") : String(localized: "cannot_reply_send"), description: String(localized: "can_reply_send_desc"))
                        .onAppear {
                            self.replySendAllowed = recipient.can_reply_send
                        }
                        .onChange(of: replySendAllowed) {
                            // Only fire when the value is NOT the same as the value already in the model
                            if (replySendAllowed != recipient.can_reply_send){
                                self.isSwitchingRecipientCanReplySendState = true
                                
                                if (recipient.can_reply_send){
                                    DispatchQueue.global(qos: .background).async {
                                        self.disallowRecipientToReplySend(recipient: recipient)
                                    }
                                } else {
                                    DispatchQueue.global(qos: .background).async {
                                        self.allowRecipientToReplySend(recipient: recipient)
                                    }
                                }
                            }
                            
                        }
                    
                    AddyToggle(isOn: $shouldEncrypt, isLoading: isSwitchingRecipientShouldEncryptState, title: recipient.should_encrypt ? String(localized: "encryption_enabled") : String(localized: "encryption_disabled"), description: String(localized: "encrypt_emails_to_this_recipient"))
                        .onAppear {
                            self.shouldEncrypt = recipient.should_encrypt
                        }
                        .onChange(of: shouldEncrypt) {
                            // Only fire when the value is NOT the same as the value already in the model
                            if (shouldEncrypt != recipient.should_encrypt){
                                self.isSwitchingRecipientShouldEncryptState = true
                                
                                if (recipient.should_encrypt){
                                    DispatchQueue.global(qos: .background).async {
                                        self.disableEncryption(recipient: recipient)
                                    }
                                } else {
                                    DispatchQueue.global(qos: .background).async {
                                        self.enableEncryption(recipient: recipient)
                                    }
                                }
                            }
                            
                        }
                    
                    AddySectionButton(title: recipient.fingerprint != nil ? String(localized: "change_public_gpg_key") : String(localized: "add_public_gpg_key"),
                                      colorAccent: .accentColor,
                                      isLoading: false){
                        isPresentingAddRecipientPublicGpgKeyBottomSheet = true
                    }
                    
                    AddySectionButton(title: String(localized: "remove_public_key"), colorAccent: .accentColor, isLoading: isRemovingPgpKey){
                                                activeAlert = .removePgpKey
                                                showAlert = true
                    }.disabled(recipient.fingerprint == nil)
                    
                    AddyToggle(isOn: $inlineEncryption, isLoading: isSwitchingInlineEncryptionState, title: String(localized: "pgp_inline"), description: getPgpInlineDescription(recipient: recipient))
                        .onAppear {
                            self.inlineEncryption = recipient.inline_encryption
                        }
                        .onChange(of: inlineEncryption) {
                            // Only fire when the value is NOT the same as the value already in the model
                            if (inlineEncryption != recipient.inline_encryption){
                                self.isSwitchingInlineEncryptionState = true
                                
                                if (recipient.inline_encryption){
                                    DispatchQueue.global(qos: .background).async {
                                        self.disablePGPInline(recipient: recipient)
                                    }
                                } else {
                                    DispatchQueue.global(qos: .background).async {
                                        self.enablePGPInline(recipient: recipient)
                                    }
                                }
                            }
                            
                        }
                        .disabled(recipient.fingerprint == nil || recipient.protected_headers)
                    
                    AddyToggle(isOn: $protectedHeaders, isLoading: isSwitchingProtectedHeadersState, title: String(localized: "protected_headers"), description: getProtectedHeadersDescription(recipient: recipient))
                        .onAppear {
                            self.protectedHeaders = recipient.protected_headers
                        }
                        .onChange(of: protectedHeaders) {
                            // Only fire when the value is NOT the same as the value already in the model
                            if (protectedHeaders != recipient.protected_headers){
                                self.isSwitchingProtectedHeadersState = true
                                
                                if (recipient.protected_headers){
                                    DispatchQueue.global(qos: .background).async {
                                        self.disableProtectedHeaders(recipient: recipient)
                                    }
                                } else {
                                    DispatchQueue.global(qos: .background).async {
                                        self.enableProtectedHeaders(recipient: recipient)
                                    }
                                }
                            }
                            
                        }
                        .disabled(recipient.fingerprint == nil || mainViewState.userResource!.hasUserFreeSubscription() || recipient.inline_encryption)

                    
                    
                } header: {
                    Text(String(localized: "actions"))
                }
                
                Section {
                    AddySectionButton(title: String(localized: "delete_recipient"),
                                      leadingSystemimage: "trash", colorAccent: .softRed, isLoading: isDeletingRecipient){
                        activeAlert = .deleteRecipient
                        showAlert = true
                    }
                }
                
            }.disabled(isDeletingRecipient)
                .navigationTitle(self.recipientEmail)
                .navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $isPresentingAddRecipientPublicGpgKeyBottomSheet) {
                    NavigationStack {
                        AddRecipientPublicGpgKeyBottomSheet(recipientId: recipient.id){ recipient in
                            self.recipient = recipient
                            isPresentingAddRecipientPublicGpgKeyBottomSheet = false
                        }
                    }
                    .presentationDetents([.large])
                }

                .alert(isPresented: $showAlert) {
                            switch activeAlert {
                           case .deleteRecipient:
                                return Alert(title: Text(String(localized: "delete_recipient")), message: Text(String(localized: "delete_recipient_desc")), primaryButton: .destructive(Text(String(localized: "delete"))){
                                    isDeletingRecipient = true
    
                                    DispatchQueue.global(qos: .background).async {
                                        deleteRecipient(recipient: recipient)
                                    }
                                }, secondaryButton: .cancel())
                            case .removePgpKey:
                                return Alert(title: Text(String(localized: "remove_public_key")), message: Text(String(format: String(localized: "remove_public_key_desc"), recipient.email)), primaryButton: .destructive(Text(String(localized: "remove"))){
                                    isRemovingPgpKey = true
    
                                    DispatchQueue.global(qos: .background).async {
                                        removeGpgKeyHttpRequest(recipient: recipient)
                                    }
                                }, secondaryButton: .cancel())
                            case .error:
                                return Alert(
                                    title: Text(errorAlertTitle),
                                    message: Text(errorAlertMessage)
                                )
                            }
                        }
    
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
    
    private func allowRecipientToReplySend(recipient:Recipients) {
        let networkHelper = NetworkHelper()
        networkHelper.allowRecipientToReplySend(completion: { recipient, result in
            DispatchQueue.main.async {
                self.isSwitchingRecipientCanReplySendState = false
                
                if let recipient = recipient {
                    self.recipient = recipient
                    self.replySendAllowed = true
                } else {
                    self.replySendAllowed = false
                    activeAlert = .error
                    showAlert = true
                    errorAlertTitle = String(localized: "error_edit_active")
                    errorAlertMessage = result ?? String(localized: "error_unknown_refer_to_logs")
                }
            }
        },recipientId: recipient.id)
    }
    
    private func disallowRecipientToReplySend(recipient:Recipients) {
        let networkHelper = NetworkHelper()
        networkHelper.disallowRecipientToReplySend(completion: { result in
            DispatchQueue.main.async {
                self.isSwitchingRecipientCanReplySendState = false
                
                if result == "204" {
                    self.recipient?.can_reply_send = false
                    self.replySendAllowed = false
                } else {
                    self.replySendAllowed = true
                    activeAlert = .error
                    showAlert = true
                    errorAlertTitle = String(localized: "error_edit_active")
                    errorAlertMessage = result ?? String(localized: "error_unknown_refer_to_logs")
                }
            }
        },recipientId: recipient.id)
    }
    
    private func enableEncryption(recipient:Recipients) {
        let networkHelper = NetworkHelper()
        networkHelper.enableEncryptionRecipient(completion: { recipient, result in
            DispatchQueue.main.async {
                self.isSwitchingRecipientShouldEncryptState = false
                
                if let recipient = recipient {
                    self.recipient = recipient
                    self.shouldEncrypt = true
                } else {
                    self.shouldEncrypt = false
                    activeAlert = .error
                    showAlert = true
                    errorAlertTitle = String(localized: "error_edit_active")
                    errorAlertMessage = result ?? String(localized: "error_unknown_refer_to_logs")
                }
            }
        },recipientId: recipient.id)
    }
    
    private func disableEncryption(recipient:Recipients) {
        let networkHelper = NetworkHelper()
        networkHelper.disableEncryptionRecipient(completion: { result in
            DispatchQueue.main.async {
                self.isSwitchingRecipientShouldEncryptState = false
                
                if result == "204" {
                    self.recipient?.should_encrypt = false
                    self.shouldEncrypt = false
                } else {
                    self.shouldEncrypt = true
                    activeAlert = .error
                    showAlert = true
                    errorAlertTitle = String(localized: "error_edit_active")
                    errorAlertMessage = result ?? String(localized: "error_unknown_refer_to_logs")
                }
            }
        },recipientId: recipient.id)
    }     
    
    private func enableProtectedHeaders(recipient:Recipients) {
        let networkHelper = NetworkHelper()
        networkHelper.enableProtectedHeadersRecipient(completion: { recipient, result in
            DispatchQueue.main.async {
                self.isSwitchingProtectedHeadersState = false
                
                if let recipient = recipient {
                    self.recipient = recipient
                    self.protectedHeaders = true
                } else {
                    self.protectedHeaders = false
                    activeAlert = .error
                    showAlert = true
                    errorAlertTitle = String(localized: "error_edit_active")
                    errorAlertMessage = result ?? String(localized: "error_unknown_refer_to_logs")
                }
            }
        },recipientId: recipient.id)
    }
    
    private func disableProtectedHeaders(recipient:Recipients) {
        let networkHelper = NetworkHelper()
        networkHelper.disableProtectedHeadersRecipient(completion: { result in
            DispatchQueue.main.async {
                self.isSwitchingProtectedHeadersState = false
                
                if result == "204" {
                    self.recipient?.protected_headers = false
                    self.protectedHeaders = false
                } else {
                    self.protectedHeaders = true
                    activeAlert = .error
                    showAlert = true
                    errorAlertTitle = String(localized: "error_edit_active")
                    errorAlertMessage = result ?? String(localized: "error_unknown_refer_to_logs")
                }
            }
        },recipientId: recipient.id)
    }    
    
    
    private func enablePGPInline(recipient:Recipients) {
        let networkHelper = NetworkHelper()
        networkHelper.enablePgpInlineRecipient(completion: { recipient, result in
            DispatchQueue.main.async {
                self.isSwitchingInlineEncryptionState = false
                
                if let recipient = recipient {
                    self.recipient = recipient
                    self.inlineEncryption = true
                } else {
                    self.inlineEncryption = false
                    activeAlert = .error
                    showAlert = true
                    errorAlertTitle = String(localized: "error_edit_active")
                    errorAlertMessage = result ?? String(localized: "error_unknown_refer_to_logs")
                }
            }
        },recipientId: recipient.id)
    }
    
    private func disablePGPInline(recipient:Recipients) {
        let networkHelper = NetworkHelper()
        networkHelper.disablePgpInlineRecipient(completion: { result in
            DispatchQueue.main.async {
                self.isSwitchingInlineEncryptionState = false
                
                if result == "204" {
                    self.recipient?.inline_encryption = false
                    self.inlineEncryption = false
                } else {
                    self.inlineEncryption = true
                    activeAlert = .error
                    showAlert = true
                    errorAlertTitle = String(localized: "error_edit_active")
                    errorAlertMessage = result ?? String(localized: "error_unknown_refer_to_logs")
                }
            }
        },recipientId: recipient.id)
    }
    
    private func removeGpgKeyHttpRequest(recipient:Recipients) {
        let networkHelper = NetworkHelper()
        networkHelper.removeEncryptionKeyRecipient(completion: { result in
            DispatchQueue.main.async {
                self.isRemovingPgpKey = false
                
                if result == "204" {
                    self.recipient?.should_encrypt = false
                    self.recipient?.fingerprint = nil
                    self.shouldEncrypt = false
                } else {
                    activeAlert = .error
                    showAlert = true
                    errorAlertTitle = String(localized: "error_removing_gpg_key")
                    errorAlertMessage = result ?? String(localized: "error_unknown_refer_to_logs")
                }
            }
        },recipientId: recipient.id)
    }
    
    private func updateUi(aliasesArray: AliasesArray?){
        
        if let aliasesArray = aliasesArray {
            let sortedAliasesData = aliasesArray.data.sorted(by: { $0.email < $1.email })
            
            aliasList = sortedAliasesData.map { alias in
                totalForwarded += alias.emails_forwarded
                totalBlocked += alias.emails_blocked
                totalReplies += alias.emails_replied
                totalSent += alias.emails_sent
                return alias.email
            }
            
            
        }
    }
    
    private func getPgpInlineDescription(recipient: Recipients) -> String {
        if (recipient.inline_encryption){
            return String(localized: "pgp_inline_desc")
        } else if (recipient.protected_headers){
            return String(localized: "prerequisite_disable_protected_headers")
        }  else {
            return String(localized: "pgp_inline_desc")
        }
    }
    
    private func getProtectedHeadersDescription(recipient: Recipients) -> String {
        if (mainViewState.userResource!.hasUserFreeSubscription()){
            return String(localized: "feature_not_available_subscription")
        } else if (recipient.inline_encryption){
            return String(localized: "prerequisite_disable_pgp_inline")
        } else if (recipient.protected_headers){
            return String(localized: "protected_headers_subject_desc")
        }  else {
            return String(localized: "protected_headers_subject_desc")
        }
    }
    
    private func deleteRecipient(recipient:Recipients) {
        let networkHelper = NetworkHelper()
        networkHelper.deleteRecipient(completion: { result in
            DispatchQueue.main.async {
                self.isDeletingRecipient = false
                
                if result == "204" {
                    shouldReloadDataInParent = true
                    self.presentationMode.wrappedValue.dismiss()
                } else {
                    activeAlert = .error
                    showAlert = true
                    errorAlertTitle = String(localized: "error_deleting_recipient")
                    errorAlertMessage = result ?? String(localized: "error_unknown_refer_to_logs")
                }
            }
        },recipientId: recipient.id)
    }
    
    
    
    private func getRecipient(recipientId: String) {
        let networkHelper = NetworkHelper()
        networkHelper.getSpecificRecipient(completion: { recipient, error in
            
            if let recipient = recipient {
                DispatchQueue.main.async {
                    withAnimation {
                        self.recipient = recipient
                    }
                }
                
                DispatchQueue.global(qos: .background).async {
                    getAliasesAndAddThemToList(recipient: recipient)
                }
            } else {
                DispatchQueue.main.async {
                    withAnimation {
                        self.errorText = error
                    }
                }
            }
        },recipientId: recipientId)
    }
    
    private func getAliasesAndAddThemToList(recipient: Recipients, workingAliasList: AliasesArray? = nil) {
        let networkHelper = NetworkHelper()

        networkHelper.getAliases(completion: { list, error in
            if let list = list {
                addAliasesToList(recipient: recipient, aliasesArray: list, workingAliasListInbound: workingAliasList)
            } else {
                DispatchQueue.main.async {
                    withAnimation {
                        self.errorText = error
                    }
                }
            }
        },aliasSortFilterRequest: AliasSortFilterRequest(onlyActiveAliases: false, onlyDeletedAliases: false, onlyInactiveAliases: false, onlyWatchedAliases: false, sort: nil, sortDesc: false, filter: nil),
                                 page: (workingAliasList?.meta?.current_page ?? 0) + 1,
                                 size: 100,
                                 recipient: recipientId)
    }
    
    
    // Function to add aliases to the list
    func addAliasesToList(recipient: Recipients, aliasesArray: AliasesArray, workingAliasListInbound: AliasesArray? = nil) {
        var workingAliasList = workingAliasListInbound

        // If the aliasList is nil, completely set it
        if workingAliasList == nil {
            workingAliasList = aliasesArray
        } else {
            // If not, update meta, links and append aliases
            workingAliasList?.meta = aliasesArray.meta
            workingAliasList?.links = aliasesArray.links
            workingAliasList?.data.append(contentsOf: aliasesArray.data)
        }
        
        // Check if there are more aliases to obtain (are there more pages)
        // If so, repeat.
        if (workingAliasList?.meta?.current_page ?? 0) < (workingAliasList?.meta?.last_page ?? 0) {
            getAliasesAndAddThemToList(recipient: recipient, workingAliasList: workingAliasList)
        } else {
            DispatchQueue.main.async {
                // Else, set aliasList to update UI
                updateUi(aliasesArray: workingAliasList)
            }
        }
    }
    
}

//
//#Preview {
//    RecipientsDetailView(recipientId: "6a866f49-5a0b-4c7e-bc45-f46bf019c4ed", recipientEmail: "PLACEHOLDER")
//}
