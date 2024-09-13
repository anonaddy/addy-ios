//
//  MailToActionSheet.swift
//  addy
//
//  Created by Stijn van de Water on 01/07/2024.
//

import SwiftUI
import AVFoundation
import addy_shared
import LocalAuthentication
struct MailToActionSheet: View {
    
    @Environment(\.scenePhase) var scenePhase

    @State private var showBiometricsNotAvailableScreen = false

    @State private var sendMailRecipientView: SendMailRecipientView? = nil
    @State private var mailToActionSheetData: MailToActionSheetData
    @State private var openedThroughShareSheet: Bool
    @State private var errorTitle: String = ""
    @State private var errorMessage: String = ""
    @State private var isUnlocked: Bool = false
    @State private var showSendMailRecipientView: Bool = false
    @State private var loadingStatusText = String(localized: "intent_checking_address")
    private let networkHelper = NetworkHelper()
    private let returnToApp: (String) -> Void
    private let close: () -> Void
    private let openMailToShareSheet: (URL) -> Void

    
    init(mailToActionSheetData: MailToActionSheetData, openedThroughShareSheet: Bool, returnToApp: @escaping (String) -> Void, close: @escaping () -> Void, openMailToShareSheet: @escaping (URL) -> Void) {
        self.mailToActionSheetData = mailToActionSheetData
        self.openedThroughShareSheet = openedThroughShareSheet
        self.returnToApp = returnToApp
        self.close = close
        self.openMailToShareSheet = openMailToShareSheet
    }
    
    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
        
        NavigationStack{
            if !SettingsManager(encrypted: true).getSettingsBool(key: .biometricEnabled) || self.isUnlocked {
                Group {
                    if (!errorMessage.isEmpty){
                        ContentUnavailableView {
                            Label(errorTitle, systemImage: "exclamationmark.triangle.fill")
                        } description: {
                            Text(errorMessage)
                        }
                    } else {
                        loadingView
                    }
                }.navigationTitle(String(localized: "integration_mailto_alias"))
                    .pickerStyle(.navigationLink)
                    .navigationBarTitleDisplayMode(.inline)
                    .apply {
                        if openedThroughShareSheet {
                            $0.toolbar {
                                Button(String(localized: "cancel")) {
                                    self.close()
                                }
                            }
                        } else {
                            $0
                        }
                        
                    }
                    .navigationDestination(isPresented: $showSendMailRecipientView, destination: {
                        sendMailRecipientView
                            .navigationBarBackButtonHidden(true)
                    })
                    .onAppear {
                            
                            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
                            var emailBody = ""
                            var emailSubject = ""

                        
                            // mailto: contains 7 chars
                            // mailto:test@stjinchan123.anonaddy.com?subject=hello&body=beepboop BECOMES test@stjinchan123.anonaddy.com
                            // If not mailto, extract the email addresses directly

                            let recipients = mailToActionSheetData.value.starts(with: "mailto:") ?
                            mailToActionSheetData.value.components(separatedBy: "?").first?.dropFirst(7).replacingOccurrences(of: ";", with: ",").split(separator: ",") ?? [] :
                            mailToActionSheetData.value.components(separatedBy: "?").first?.replacingOccurrences(of: ";", with: ",").split(separator: ",") ?? []
                            
                            emailSubject = getParameter(mailToActionSheetData.value, parameter: "subject") ?? ""
                            let ccRecipients = getParameter(mailToActionSheetData.value, parameter: "cc")?.replacingOccurrences(of: ";", with: ",").split(separator: ",")
                            let bccRecipients = getParameter(mailToActionSheetData.value, parameter: "bcc")?.replacingOccurrences(of: ";", with: ",").split(separator: ",")
                            emailBody = getParameter(mailToActionSheetData.value, parameter: "body") ?? mailToActionSheetData.value // Get body from mailto: else just take the raw value (as it will be the selected text for sharing
                            
                            
                        
                            // Filter out invalid email addresses
                            var validEmails: [String] = []
                            var validCcRecipients: [String] = []
                            var validBccRecipients: [String] = []
                        
                            // Verify if any email address has been captured
                            for email in recipients {
                                if email.range(of: emailRegex, options: .regularExpression) != nil {
                                    validEmails.append(String(email))
                                }
                            }
                          
                            
                            if let ccRecipients = ccRecipients {
                                for email in ccRecipients {
                                    if email.range(of: emailRegex, options: .regularExpression) != nil {
                                        validCcRecipients.append(String(email))
                                    }
                                }
                            }
                            
                            if let bccRecipients = bccRecipients {
                                for email in bccRecipients {
                                    if email.range(of: emailRegex, options: .regularExpression) != nil {
                                        validBccRecipients.append(String(email))
                                    }
                                }
                            }
                            
                            Task {
                                await figureOutNextAction(emails: validEmails, validCcRecipients: validCcRecipients, validBccRecipients: validBccRecipients, emailSubject: emailSubject, emailBody: emailBody)
                            }
                        
                    }
            } else {
                Group {
                    if showBiometricsNotAvailableScreen {
                        ContentUnavailableView {
                            Label(String(localized: "addyio_locked"), systemImage: "lock.fill")
                        } description: {
                            Text(String(localized: "addyio_locked_desc"))
                        } actions: {
                            Button(String(localized: "unlock")) {
                                authenticate()
                            }
                        }
                    } else {
                        ContentUnavailableView {
                            Label(String(localized: "addyio_locked"), systemImage: "lock.fill")
                        } description: {
                            Text(String(localized: "biometric_error"))
                        } actions: {
                            Button(String(localized: "unlock")) {
                                authenticate()
                            }
                        }
                    }
                }
                .onAppear {
                    if SettingsManager(encrypted: true).getSettingsBool(key: .biometricEnabled){
                        authenticate()
                    } else {
                        self.isUnlocked = true
                    }
                                    
                }
            }
        }
        
    }
    
    var loadingView: some View {
        
        return VStack {
            
            VStack(spacing: 20) {
                
                Text(loadingStatusText)
                ProgressView()
                
            }
            
        }
        
        
    }
    
    
    func getParameter(_ data: String, parameter: String) -> String? {
        if data.contains("\(parameter)=") {
            return data.components(separatedBy: "\(parameter)=").last?.components(separatedBy: "&").first
        }
        return nil
    }
    
    private func figureOutNextAction(emails: [String], validCcRecipients: [String], validBccRecipients: [String], emailSubject: String, emailBody: String) async{
        do {
            if let domainOptions = try await networkHelper.getDomainOptions() {
                let domainOptions = domainOptions.data
                
                if !emails.isEmpty && emails.count == 1 {
                    // Only 1 email address found.

                    // splittedEmailAddress[0] = custom part
                    // splittedEmailAddress[1] = domain name
                    let splittedEmailAddress = emails[0].split(separator: "@")
                    
                    if domainOptions.contains(where: { $0 == splittedEmailAddress[1] }) {
                        DispatchQueue.main.async {
                            loadingStatusText = String(format: String(localized: "intent_creating_alias"), emails[0])
                        }
                        await checkIfAliasExists(text: emails[0])
                    } else {
                        DispatchQueue.main.async {
                            loadingStatusText =
                            String(localized: "intent_opening_send_mail_dialog")
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            sendMailRecipientView = SendMailRecipientView(openedThroughShareSheet: openedThroughShareSheet, recipients: emails, validCcRecipients: validCcRecipients, validBccRecipients: validBccRecipients, emailSubject: emailSubject, emailBody: emailBody, domainOptions: domainOptions, close: self.close, openMailToShareSheet: self.openMailToShareSheet)
                            showSendMailRecipientView = true

                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        loadingStatusText = String(localized: "intent_opening_send_mail_dialog")
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        sendMailRecipientView = SendMailRecipientView(openedThroughShareSheet: openedThroughShareSheet, recipients: emails, validCcRecipients: validCcRecipients, validBccRecipients: validBccRecipients, emailSubject: emailSubject, emailBody: emailBody, domainOptions: domainOptions, close: self.close, openMailToShareSheet: self.openMailToShareSheet)
                        showSendMailRecipientView = true
                    }
                }
                
            }
        } catch {
            errorTitle = String(localized:"something_went_wrong_retrieving_domains")
            errorMessage = error.localizedDescription
        }
    }
    
    private func checkIfAliasExists(text: String) async{
        do {
            let aliasSortFilterRequest = AliasSortFilterRequest(
                onlyActiveAliases: false,
                onlyDeletedAliases: false,
                onlyInactiveAliases: false,
                onlyWatchedAliases: false,
                sort: nil,
                sortDesc: true,
                filter: text
            )
            
            let aliasArray = try await networkHelper.getAliases(aliasSortFilterRequest: aliasSortFilterRequest)
            if let aliasArray = aliasArray {
                
                // Check if there is an alias with this email address and get its ID
                if let aliasId = aliasArray.data.first(where: { $0.email.lowercased() == text.lowercased() })?.id {
                    // ID is not empty, thus there was a match
                    // Let the user know that an alias exists, wait 1s and open the alias
                    DispatchQueue.main.async {
                        loadingStatusText = String(localized: "intent_alias_already_exists")
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        // There is an alias with this exact email address. It already exists! Open the app
                        self.returnToApp(aliasId)
                    }
                    
                } else {
                    // ID is empty, this alias is new! Let's create it
                    let splittedEmailAddress = text.split(separator: "@")
                    await addAliasToAccount(domain: String(splittedEmailAddress[1]), description: "", format: "custom", localPart: String(splittedEmailAddress[0]))
                    
                }

                
            }
        
        } catch {
            errorTitle = String(localized:"something_went_wrong_retrieving_aliases")
            errorMessage = error.localizedDescription
        }
    }
    
    
    private func addAliasToAccount(domain: String, description: String, format: String, localPart: String) async {
        do {
            if (try await networkHelper.addAlias(domain: domain, description: description, format: format, localPart: localPart, recipients: nil)) != nil{
                //TODO:  let user know
                DispatchQueue.main.async {
                    self.close()
                }
            }
        } catch {
            errorTitle = String(localized:"error_adding_alias")
            errorMessage = error.localizedDescription
        }
    }
    
    func authenticate() {
        let context = LAContext()
        var error: NSError?
        
        // check whether biometric authentication is possible
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // it's possible, so go ahead and use it
            let reason = String(localized: "addyio_locked")
            
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in
                // authentication has now completed
                if success {
                    DispatchQueue.main.async {
                        self.isUnlocked = true

                                }
                }
            }
        } else {
            //showBiometricsNotAvailableAlert = true
        }
    }

    
}

#Preview {
    MailToActionSheet(mailToActionSheetData: MailToActionSheetData(value: "TEST@TEST.com"), openedThroughShareSheet: false, returnToApp: { aliasId in
        print("OPEN APP")
    }, close: {
        print("CLOSE")
    }, openMailToShareSheet: {_ in
        print("SEND MAIL")
    })
}
