//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by Stijn van de Water on 01/07/2024.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

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
                            self.open(url: URL(string: "addyio://alias/\(aliasId)")!)
                            self.close()
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
                            self.open(url: URL(string: "addyio://alias/\(aliasId)")!)
                            self.close()
                        }, close: {
                            self.close()
                        }, openMailToShareSheet: { url in
                            self.open(url: url)
                            self.close()
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
            close()
            return
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("close"), object: nil, queue: nil) { _ in
            DispatchQueue.main.async {
                self.close()
            }
        }
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//
//        for item in extensionContext!.inputItems as! [NSExtensionItem] {
//            if let attachments = item.attachments {
//                for itemProvider in attachments {
//                    if itemProvider.hasItemConformingToTypeIdentifier("public.url") {
//                        itemProvider.loadItem(forTypeIdentifier: "public.url", options: nil, completionHandler: { (item, error) in
//                            let url = (item as! NSURL).absoluteURL!
//
//                            self.open(url: url)
//                            self.extensionContext!.completeRequest(returningItems: nil, completionHandler: nil)
//                        })
//                    }
//                }
//            }
//        }
//    }
//    
    
    //TODO: This is not working on iOS18DB2
    
    /// Close the Share Extension
    private func close() {
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    
    
    private func open(url: URL) {
            var responder: UIResponder? = self as UIResponder
            let selector = #selector(openURL(_:))

            while responder != nil {
                if responder!.responds(to: selector) && responder != self {
                    responder!.perform(selector, with: url)

                    return
                }

                responder = responder?.next
            }
        }

        @objc
        private func openURL(_ url: URL) {
            return
        }
}
