//
//  MailToActionSheet.swift
//  addy
//
//  Created by Stijn van de Water on 01/07/2024.
//

import SwiftUI
import AVFoundation

public struct MailToActionSheet: View {
    
    @State private var mailToActionSheetData: MailToActionSheetData
    @State private var openedThroughShareSheet: Bool
    
    
    @State private var loadingStatusText = NSLocalizedString("intent_checking_address", bundle: Bundle(for: SharedData.self), comment: "")
    
    
    public init(mailToActionSheetData: MailToActionSheetData, openedThroughShareSheet: Bool) {
        self.mailToActionSheetData = mailToActionSheetData
        self.openedThroughShareSheet = openedThroughShareSheet
    }
    
    public var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
        
        NavigationStack{
            
            Group {
                loadingView
            }.navigationTitle(NSLocalizedString("integration_mailto_alias", bundle: Bundle(for: SharedData.self), comment: ""))
                .pickerStyle(.navigationLink)
                .navigationBarTitleDisplayMode(.inline)
                .apply {
                    if openedThroughShareSheet {
                        $0.toolbar {
                            Button(NSLocalizedString("cancel", bundle: Bundle(for: SharedData.self), comment: "")) {
                                close()
                            }
                        }
                    } else {
                        $0
                    }
                    
                }
                .onAppear {
                    let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
                    var emailBody = ""
                    
                    
                    // Starts with mailto, obtain the parameters
                    if mailToActionSheetData.value.hasPrefix("mailto:") {
                        let recipients = mailToActionSheetData.value.components(separatedBy: "?").first?.dropFirst(7).replacingOccurrences(of: ";", with: ",").split(separator: ",")
                        let subject = getParameter(mailToActionSheetData.value, parameter: "subject")
                        let ccRecipients = getParameter(mailToActionSheetData.value, parameter: "cc")?.replacingOccurrences(of: ";", with: ",").split(separator: ",")
                        let bccRecipients = getParameter(mailToActionSheetData.value, parameter: "bcc")?.replacingOccurrences(of: ";", with: ",").split(separator: ",")
                        emailBody = getParameter(mailToActionSheetData.value, parameter: "body") ?? ""
                        
                        // Filter out invalid email addresses
                        var validEmails: [String] = []
                        var validCcRecipients: [String] = []
                        var validBccRecipients: [String] = []
                        
                        
                        if let recipients = recipients {
                            for email in recipients {
                                if email.range(of: emailRegex, options: .regularExpression) != nil {
                                    validEmails.append(String(email))
                                }
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
                        
                        //TODO: Open the SendMailRecipientView
                        
                    } else {
                        // Does not start with mailto, user might want to
                        // - share text and wants to send it using an alias
                        // - Create or open an alias based on the selected email address
                        
                        if mailToActionSheetData.value.range(of: emailRegex, options: .regularExpression) != nil {
                            // The selected text is a valid email-address.
                            // Figure out if the selected email's domain name is part of the user's addy.io account or not
                            
                            //TODO: Check if the domain is owned
                        } else {
                            // The selected text is NOT a valid email-address
                            // Copy the content to the emailBody
                            emailBody = mailToActionSheetData.value
                            
                            //TODO: Open the SendMailRecipientView
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
    
    // Closes the share sheet
    func close() {
        NotificationCenter.default.post(name: NSNotification.Name("close"), object: nil)
    }
    
    
    func getParameter(_ data: String, parameter: String) -> String? {
        if data.contains("\(parameter)=") {
            return data.components(separatedBy: "\(parameter)=").last?.components(separatedBy: "&").first
        }
        return nil
    }
    
}

#Preview {
    MailToActionSheet(mailToActionSheetData: MailToActionSheetData(value: "TEST@TEST.com"), openedThroughShareSheet: false)
}
