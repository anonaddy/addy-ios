//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by Stijn van de Water on 01/07/2024.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers
import addy_shared

class ShareViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Ensure access to extensionItem and itemProvider
        guard
            let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
            let itemProvider = extensionItem.attachments?.first else {
            close()
            return
        }
        
        if SettingsManager(encrypted: true).getSettingsString(key: .apiKey) != nil {
            // Check type identifier
            let textDataType = UTType.plainText.identifier
            let urlDataType = UTType.url.identifier
            if itemProvider.hasItemConformingToTypeIdentifier(textDataType){
                
                // Load the item from itemProvider
                itemProvider.loadItem(forTypeIdentifier: textDataType , options: nil) { (providedText, error) in
                    if error != nil {
                        self.close()
                        return
                    }
                    
                    if let text = providedText as? String {
                        DispatchQueue.main.async {
                            // host the SwiftUI view
                            let contentView = UIHostingController(rootView: MailToActionSheet(mailToActionSheetData: MailToActionSheetData(value: text), openedThroughShareSheet: true, returnToApp: { aliasId in
                                self.openAliasInApp(url: URL(string: "addyio://alias/\(aliasId)")!)
                            }, close: {
                                self.close()
                            }, openMailToShareSheet: { url in
                                self.open(url: url)
                            }))
                            self.addChild(contentView)
                            self.view.addSubview(contentView.view)
                            
                            // set up constraints
                            contentView.view.translatesAutoresizingMaskIntoConstraints = false
                            contentView.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
                            contentView.view.bottomAnchor.constraint (equalTo: self.view.bottomAnchor).isActive = true
                            contentView.view.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
                            contentView.view.rightAnchor.constraint (equalTo: self.view.rightAnchor).isActive = true
                        }
                    } else {
                        self.close()
                        return
                    }
                    
                }
                
            } else if itemProvider.hasItemConformingToTypeIdentifier(urlDataType){
                
                // Load the item from itemProvider
                itemProvider.loadItem(forTypeIdentifier: urlDataType , options: nil) { (providedText, error) in
                    if error != nil {
                        self.close()
                        return
                    }
                    
                    if let text = providedText as? URL? {
                        DispatchQueue.main.async {
                            // host the SwiftUI view
                            let contentView = UIHostingController(rootView: MailToActionSheet(mailToActionSheetData: MailToActionSheetData(value: text!.absoluteString), openedThroughShareSheet: true, returnToApp: { aliasId in
                                self.openAliasInApp(url: URL(string: "addyio://alias/\(aliasId)")!)
                            }, close: {
                                self.close()
                            }, openMailToShareSheet: { url in
                                self.open(url: url)
                            }))
                            self.addChild(contentView)
                            self.view.addSubview(contentView.view)
                            
                            // set up constraints
                            contentView.view.translatesAutoresizingMaskIntoConstraints = false
                            contentView.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
                            contentView.view.bottomAnchor.constraint (equalTo: self.view.bottomAnchor).isActive = true
                            contentView.view.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
                            contentView.view.rightAnchor.constraint (equalTo: self.view.rightAnchor).isActive = true
                        }
                    } else {
                        self.close()
                        return
                    }
                    
                }
                
            } else {
                self.close()
                return
            }
            
            NotificationCenter.default.addObserver(forName: NSNotification.Name("close"), object: nil, queue: nil) { _ in
                DispatchQueue.main.async {
                    self.close()
                }
            }
        } else {
            DispatchQueue.main.async {
                // host the SwiftUI view
                let contentView = UIHostingController(rootView: ContentUnavailableView {
                    Label(String(localized: "app_not_setup"), systemImage: "questionmark.key.filled")
                } description: {
                    Text("app_not_setup_desc")
                })
                self.addChild(contentView)
                self.view.addSubview(contentView.view)
                
                // set up constraints
                contentView.view.translatesAutoresizingMaskIntoConstraints = false
                contentView.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
                contentView.view.bottomAnchor.constraint (equalTo: self.view.bottomAnchor).isActive = true
                contentView.view.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
                contentView.view.rightAnchor.constraint (equalTo: self.view.rightAnchor).isActive = true
            }
        }
        
    }
    
    
    /// Close the Share Extension
    private func close() {
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    
    
    private func open(url: URL) {
        SettingsManager(encrypted: true).putSettingsString(key: .pendingURLFromShareViewController, string: url.absoluteString)

        // Create an alert
        let alert = UIAlertController(title: String(localized: "shareviewcontroller_pending_url_scheduled"), message: String(localized: "shareviewcontroller_pending_url_scheduled_desc"), preferredStyle: .alert)
        
        // Add an action to the alert
        alert.addAction(UIAlertAction(title: String(localized: "understood"), style: .default, handler: { _ in
            self.close()
        }))
        
        // Present the alert
        self.present(alert, animated: true, completion: nil)
    }
    
     private func openAliasInApp(url: URL) {
        SettingsManager(encrypted: true).putSettingsString(key: .pendingURLFromShareViewController, string: url.absoluteString)

        // Create an alert
        let alert = UIAlertController(title: String(localized: "shareviewcontroller_pending_alias_scheduled"), message: String(localized: "shareviewcontroller_pending_alias_scheduled_desc"), preferredStyle: .alert)
        
        // Add an action to the alert
        alert.addAction(UIAlertAction(title: String(localized: "understood"), style: .default, handler: { _ in
            self.close()
        }))
        
        // Present the alert
        self.present(alert, animated: true, completion: nil)
    }
    
    
}
