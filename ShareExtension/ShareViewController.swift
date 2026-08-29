//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by Stijn van de Water on 01/07/2024.
//

import addy_shared
import SwiftUI
import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    private var closeObserver: NSObjectProtocol?

    deinit {
        if let closeObserver = closeObserver {
            NotificationCenter.default.removeObserver(closeObserver)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Ensure access to extensionItem and itemProvider
        guard
            let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
            let itemProvider = extensionItem.attachments?.first
        else {
            close()
            return
        }

        if SettingsManager(encrypted: true).getSettingsString(key: .apiKey) != nil {
            // Check type identifier
            let textDataType = UTType.plainText.identifier
            let urlDataType = UTType.url.identifier
            if itemProvider.hasItemConformingToTypeIdentifier(textDataType) {
                // Load the item from itemProvider
                itemProvider.loadItem(forTypeIdentifier: textDataType, options: nil) { [weak self] providedText, error in
                    guard let self = self, error == nil, let text = providedText as? String else {
                        self?.close()
                        return
                    }

                    DispatchQueue.main.async {
                        self.presentMailToActionSheet(value: text)
                    }
                }

            } else if itemProvider.hasItemConformingToTypeIdentifier(urlDataType) {
                // Load the item from itemProvider
                itemProvider.loadItem(forTypeIdentifier: urlDataType, options: nil) { [weak self] providedText, error in
                    guard let self = self, error == nil, let url = providedText as? URL else {
                        self?.close()
                        return
                    }

                    DispatchQueue.main.async {
                        self.presentMailToActionSheet(value: url.absoluteString)
                    }
                }

            } else {
                close()
                return
            }

            closeObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name("close"), object: nil, queue: .main) { [weak self] _ in
                self?.close()
            }
        } else {
            DispatchQueue.main.async {
                let unavailableView = ContentUnavailableView {
                    Label(String(localized: "app_not_setup"), systemImage: "questionmark.key.filled")
                } description: {
                    Text(String(localized: "app_not_setup_desc"))
                }
                self.embedHostView(unavailableView)
            }
        }
    }

    private func presentMailToActionSheet(value: String) {
        let sheet = MailToActionSheet(
            mailToActionSheetData: MailToActionSheetData(value: value),
            openedThroughShareSheet: true,
            returnToApp: { [weak self] aliasId in
                if let url = URL(string: "addyio://alias/\(aliasId)") {
                    self?.openAliasInApp(url: url)
                }
            },
            close: { [weak self] in
                self?.close()
            },
            openMailToShareSheet: { [weak self] url in
                self?.open(url: url)
            }
        )
        embedHostView(sheet)
    }

    private func embedHostView<V: View>(_ rootView: V) {
        let contentView = UIHostingController(rootView: rootView)
        addChild(contentView)
        view.addSubview(contentView.view)

        contentView.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.view.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            contentView.view.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
    }

    /// Close the Share Extension
    private func close() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

    private func open(url: URL) {
        SettingsManager(encrypted: true).putSettingsString(key: .pendingURLFromShareViewController, string: url.absoluteString)

        // Create an alert
        let alert = UIAlertController(title: String(localized: "shareviewcontroller_pending_url_scheduled"), message: String(localized: "shareviewcontroller_pending_url_scheduled_desc"), preferredStyle: .alert)

        // Add an action to the alert
        alert.addAction(UIAlertAction(title: String(localized: "understood", bundle: Bundle(for: SharedData.self)), style: .default, handler: { _ in
            self.close()
        }))

        // Present the alert
        present(alert, animated: true, completion: nil)
    }

    private func openAliasInApp(url: URL) {
        SettingsManager(encrypted: true).putSettingsString(key: .pendingURLFromShareViewController, string: url.absoluteString)

        // Create an alert
        let alert = UIAlertController(title: String(localized: "shareviewcontroller_pending_alias_scheduled"), message: String(localized: "shareviewcontroller_pending_alias_scheduled_desc"), preferredStyle: .alert)

        // Add an action to the alert
        alert.addAction(UIAlertAction(title: String(localized: "understood", bundle: Bundle(for: SharedData.self)), style: .default, handler: { _ in
            self.close()
        }))

        // Present the alert
        present(alert, animated: true, completion: nil)
    }
}
