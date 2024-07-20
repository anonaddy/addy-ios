//
//  SendMailRecipientView.swift
//  addy
//
//  Created by Stijn van de Water on 01/07/2024.
//

import SwiftUI
import Combine
import Shimmer
import UniformTypeIdentifiers
import addy_shared

struct SendMailRecipientView: View {
    
    @State private var openedThroughShareSheet: Bool
    @State private var domainOptions: [String]
    private let close: () -> Void
    private let openMailToShareSheet: (URL) -> Void
    private let networkHelper = NetworkHelper()
    @State private var aliasPlaceholder:String = String(localized: "start_typing_to_show_aliases")
    @State private var addressesPlaceholder:String = String(localized: "addresses")
    @State private var addressesValidationError:String?
    @State private var aliasValidationError:String?
    @State private var addresses:String = ""
    
    
    @State private var recipients: [String]
    @State private var validCcRecipients: [String]
    @State private var validBccRecipients: [String]
    @State private var emailSubject: String
    @State private var emailBody: String
    @State private var isPresentingEmailSelectionDialog: Bool = false
    
    
    @State private var showAlert: Bool = false
    @State private var isCreatingAlias: Bool = false
    @State private var errorAlertTitle = ""
    @State private var errorAlertMessage = ""
    
    @StateObject private var viewModel = SendMailRecipientSearchViewModel()
    @State private var copiedToClipboard = false
    
    @State private var clients: [ThirdPartyMailClient] = []
    
    
    init(openedThroughShareSheet: Bool, recipients: [String], validCcRecipients: [String], validBccRecipients: [String], emailSubject: String, emailBody: String, domainOptions: [String], close: @escaping () -> Void, openMailToShareSheet: @escaping (URL) -> Void){
        self.openedThroughShareSheet = openedThroughShareSheet
        self.domainOptions = domainOptions
        self.close = close
        self.openMailToShareSheet = openMailToShareSheet
        self.addresses = recipients.joined(separator: ",")
        self.recipients = recipients
        self.validCcRecipients = validCcRecipients
        self.validBccRecipients = validBccRecipients
        self.emailSubject = emailSubject
        self.emailBody = emailBody
    }
    
    
    
    var body: some View {
        
        List {
            Section {
                
                ValidatingTextField(value: $viewModel.searchQuery, placeholder: $aliasPlaceholder, fieldType: .email, error: $aliasValidationError)
                
            } header: {
                let formattedString = String(localized: "send_mail_from_alias_from_intent_desc")
                // Use Text with markdown to display the formatted string
                Text(LocalizedStringKey(formattedString))
                    .multilineTextAlignment(.center).padding(.bottom)
            } footer: {
                if viewModel.searchQuery.count < 3 {
                    Text(String(localized: "suggestions_will_appear_when_typing")).opacity(0.3)
                } else if viewModel.networkError != "" {
                    Text(viewModel.networkError)
                } else if viewModel.isLoading {
                    Text(String(localized: "loading_suggestions")).shimmering().shimmering()
                } else if viewModel.suggestionChips.isEmpty {
                    Text(String(localized: "no_suggestions"))
                } else {
                    AddyRoundedChipView(chips: $viewModel.suggestionChips, selectedChip: $viewModel.searchQuery, singleLine: true) { onTappedChip in
                        withAnimation {
                            viewModel.searchQuery = onTappedChip.label
                            viewModel.suggestionChips = []
                        }
                    }
                }
                
            } .textCase(nil).frame(maxWidth: .infinity, alignment: .leading)
            
            Section {
                ValidatingTextField(value: self.$addresses, placeholder: $addressesPlaceholder, fieldType: .commaSeperatedEmails, error: $addressesValidationError)
            }
            
        }
        .overlay {
            ToastOverlay(showToast: $copiedToClipboard, text: String(localized: "copied_to_clipboard"))
        }
        .disabled(isCreatingAlias)
        .confirmationDialog(String(localized: "send_mail"), isPresented: $isPresentingEmailSelectionDialog) {
            
            ForEach(clients, id: \.self) { item in
                Button(item.name) {
                    sendMail(client: item)
                }
            }
            
            Button(String(localized: "cancel"), role: .cancel) { }
        } message: {
            Text(String(localized: "select_mail_client"))
        }
        .onAppear(perform: {
            self.viewModel.setDomainOptions(domainOptions: domainOptions)
            
            // Get the available mail clients
            self.clients = ThirdPartyMailClient.clients.filter( {ThirdPartyMailer.isMailClientAvailable($0)})
            self.clients.append(ThirdPartyMailClient.systemDefault)
            
        })
        .alert(isPresented: $showAlert, content: {
            return Alert(
                title: Text(errorAlertTitle),
                message: Text(errorAlertMessage)
            )
        })
        .navigationTitle(String(localized: "send_mail"))
        .pickerStyle(.navigationLink)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    self.close()
                } label: {
                    Text(String(localized: "cancel"))
                }
                
            }
            ToolbarItem(placement: .topBarTrailing) {
                if isCreatingAlias {
                    ProgressView()
                } else {
                    Button {
                        self.sendMail()
                    } label: {
                        Text(String(localized: "send"))
                    }.disabled(addressesValidationError != nil || aliasValidationError != nil)
                }
                
                
            }
            
        }
        
    }
    
    
    private func sendMail(client: ThirdPartyMailClient? = nil){
        // .disabled on the Button will take care of this
        //        if addressesValidationError != nil {
        //            return
        //        }
        //
        //        if aliasValidationError != nil {
        //            return
        //        }
        
        
        // Check if client is nil, if so, ask the user to select a client
        if client == nil {
            isPresentingEmailSelectionDialog = true
        } else {
            
            // Check if alias is empty, if alias is empty just forward the recipient to the default mail app without generating an alias
            if viewModel.searchQuery.isEmpty {
                let composeUrl = client!.composeURL(to: addresses.split(separator: ",").map(String.init), subject: emailSubject, body: emailBody, cc: validCcRecipients, bcc: validBccRecipients)
                self.openMailToShareSheet(composeUrl)
            } else {
                // As we can dynamically create aliases, we need to check if the entered alias has a domain name that we can use
                
                // splittedEmailAddress[0] = custom part
                // splittedEmailAddress[1] = domain name
                let splittedEmailAddress = viewModel.searchQuery.split(separator: "@")
                
                if domainOptions.contains(where: { $0 == splittedEmailAddress[1] }) {
                    // This is a valid domain name the user has added to their addy.io account
                    
                    // Get the first alias that matched the email address with the one entered in the adapter
                    if let alias = viewModel.aliases?.first(where: {$0.email == viewModel.searchQuery}){
                        // This alias already exists
                        
                        let anonaddyRecipientAddresses = AnonAddyUtils.getSendAddress(recipientEmails: self.addresses.split(separator: ",").map { String($0) }, alias: alias)
                        let anonaddyCcRecipientAddresses = AnonAddyUtils.getSendAddress(recipientEmails: validCcRecipients, alias: alias)
                        let anonaddyBccRecipientAddresses = AnonAddyUtils.getSendAddress(recipientEmails: self.validBccRecipients, alias: alias)
                        
                        
                        let composeUrl = client!.composeURL(to: anonaddyRecipientAddresses, subject: emailSubject, body: emailBody, cc: anonaddyCcRecipientAddresses, bcc: anonaddyBccRecipientAddresses)
                        
                        UIPasteboard.general.setValue(anonaddyRecipientAddresses,forPasteboardType: UTType.plainText.identifier)
                        showCopiedToClipboardAnimation()
                        self.openMailToShareSheet(composeUrl)
                        
                        
                    } else {
                        // This alias does not exist (in the current searchQuery)                        
                        isCreatingAlias = true
                        Task {
                            if let alias = await addAliasToAccount(domain: String(splittedEmailAddress[1]), description: "", format: "custom", localPart: String(splittedEmailAddress[0])) {
                                isCreatingAlias = false
                                
                                let anonaddyRecipientAddresses = AnonAddyUtils.getSendAddress(recipientEmails: self.addresses.split(separator: ",").map { String($0) }, alias: alias)
                                let anonaddyCcRecipientAddresses = AnonAddyUtils.getSendAddress(recipientEmails: validCcRecipients, alias: alias)
                                let anonaddyBccRecipientAddresses = AnonAddyUtils.getSendAddress(recipientEmails: self.validBccRecipients, alias: alias)
                                
                                let composeUrl = client!.composeURL(to: anonaddyRecipientAddresses, subject: emailSubject, body: emailBody, cc: anonaddyCcRecipientAddresses, bcc: anonaddyBccRecipientAddresses)
                                
                                UIPasteboard.general.setValue(anonaddyRecipientAddresses,forPasteboardType: UTType.plainText.identifier)
                                showCopiedToClipboardAnimation()
                                
                                self.openMailToShareSheet(composeUrl)
                                
                            } else {
                                isCreatingAlias = false
                            }
                        }
                        
                    }
                } else {
                    self.aliasValidationError = String(format: String(localized: "you_do_not_own_this_domain"))
                    return
                }
                
            }
        }
        
    }
    
    private func addAliasToAccount(domain: String, description: String, format: String, localPart: String) async -> Aliases? {
        do {
            if let alias = try await networkHelper.addAlias(domain: domain, description: description, format: format, localPart: localPart, recipients: nil){
                return alias
            }
        } catch {
            errorAlertTitle = String(localized: "error_adding_alias")
            errorAlertMessage = error.localizedDescription
            showAlert = true
        }
        return nil
    }
    
    func showCopiedToClipboardAnimation(){
        withAnimation(.snappy) {
                copiedToClipboard = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.snappy) {
                    copiedToClipboard = false
                }
            }
    }
    
    
}

#Preview {
    SendMailRecipientView(openedThroughShareSheet: false, recipients: ["test@justplayinghard.ga"], validCcRecipients: ["cc@example.com"], validBccRecipients: ["bcc@example.com"], emailSubject:"test",emailBody:"testbody", domainOptions: ["test.com", "example.com"], close: {
        print("CLOSE")
    }, openMailToShareSheet: {_ in
        print("SEND MAIL")
    })
}
