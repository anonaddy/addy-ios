//
//  MainViewState.swift
//  addy
//
//  Created by Stijn van de Water on 20/07/2024.
//

import addy_shared
import Combine
import SwiftUI

@MainActor
class MainViewState: ObservableObject {
    static let shared = MainViewState() // Shared instance

    // MARK: NOTIFICATION AND SHORTCUT ACTIONS

    public struct BlockActionRequest: Identifiable, Equatable {
        public let id = UUID()
        public let type: String // "email" or "domain"
        public let value: String
        public let aliasId: String?

        public init(type: String, value: String, aliasId: String? = nil) {
            self.type = type
            self.value = value
            self.aliasId = aliasId
        }
    }

    @Published var aliasToDisable: String? = nil
    @Published var showAliasWithId: String? = nil
    @Published var blockActionRequest: BlockActionRequest? = nil

    // MARK: END NOTIFICATION AND SHORTCUT ACTIONS

    @discardableResult
    func handleIncomingURL(_ url: URL) -> Bool {
        // 1. mailto: links
        if url.scheme?.lowercased() == "mailto" {
            self.mailToActionSheetData = MailToActionSheetData(value: url.absoluteString)
            return true
        }

        // 2. Custom app scheme (e.g. addy://alias/{id})
        if url.host == "alias" {
            self.showAliasWithId = url.lastPathComponent
            self.selectedTab = .aliases
            return true
        }

        // 3. Email verification link (/api/auth/verify)
        if url.path.contains("/api/auth/verify") {
            SetupViewState.shared.verifyQuery = url.query()
            return true
        }

        let pathSegments = url.path.split(separator: "/").map(String.init)

        // 4. Deactivate alias link: /deactivate/{id} (or addyio://deactivate/{id})
        var deactivateAliasId: String? = nil
        if let deactivateIndex = pathSegments.firstIndex(of: "deactivate"), pathSegments.count > deactivateIndex + 1 {
            deactivateAliasId = pathSegments[deactivateIndex + 1]
        } else if url.host == "deactivate", let first = pathSegments.first {
            deactivateAliasId = first
        }

        if let id = deactivateAliasId {
            self.aliasToDisable = id
            self.selectedTab = .aliases
            return true
        }

        // 5. Actions link: /aliases/{aliasId}/actions?action=block_email&email=... or block_domain
        var targetAliasId: String? = nil
        if let aliasesIndex = pathSegments.firstIndex(of: "aliases"),
           pathSegments.count > aliasesIndex + 2,
           pathSegments[aliasesIndex + 2] == "actions" {
            targetAliasId = pathSegments[aliasesIndex + 1]
        } else if url.host == "aliases", pathSegments.count >= 2, pathSegments[1] == "actions" {
            targetAliasId = pathSegments[0]
        }

        if let aliasId = targetAliasId {
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
                  let queryItems = components.queryItems else {
                return false
            }

            let action = queryItems.first(where: { $0.name == "action" })?.value
            let emailParam = queryItems.first(where: { $0.name == "email" })?.value
            let domainParam = queryItems.first(where: { $0.name == "domain" })?.value

            let cleanCharacters = CharacterSet(charactersIn: "<> \t\n\r")

            if action == "block_email" || action == "block_sender" {
                let rawEmail = (emailParam ?? domainParam ?? "").trimmingCharacters(in: cleanCharacters)
                if !rawEmail.isEmpty {
                    self.blockActionRequest = BlockActionRequest(type: "email", value: rawEmail, aliasId: aliasId)
                    self.profileBottomSheetAction = .blocklist
                    self.isPresentingProfileBottomSheet = true
                    return true
                }
            } else if action == "block_domain" {
                var rawDomain = ""
                if let domain = domainParam?.trimmingCharacters(in: cleanCharacters), !domain.isEmpty {
                    rawDomain = domain
                } else if let email = emailParam?.trimmingCharacters(in: cleanCharacters), !email.isEmpty {
                    if let atIndex = email.lastIndex(of: "@") {
                        rawDomain = String(email[email.index(after: atIndex)...]).trimmingCharacters(in: cleanCharacters)
                    } else {
                        rawDomain = email
                    }
                }

                if !rawDomain.isEmpty {
                    self.blockActionRequest = BlockActionRequest(type: "domain", value: rawDomain, aliasId: aliasId)
                    self.profileBottomSheetAction = .blocklist
                    self.isPresentingProfileBottomSheet = true
                    return true
                }
            }
        }

        return false
    }

    // MARK: SHORTCUT ACTIONS

    @Published var showAddAliasBottomSheet = false

    // MARK: END SHORTCUT ACTIONS

    // MARK: Share sheet AND MailTo tap action

    @Published var mailToActionSheetData: MailToActionSheetData? = nil

    // MARK: END Share sheet AND MailTo tap action

    @Published var isPresentingProfileBottomSheet = false
    @Published var profileBottomSheetAction: Destination? = nil
    @Published var isPresentingFailedDeliveriesSheet = false
    @Published var isPresentingAccountNotificationsSheet = false
    @Published var isPresentingWatchKitLogsSheet = false

    @Published var selectedTab: Destination = .home

    @Published var newFailedDeliveries: Int? = nil
    @Published var newAccountNotifications: Int = 0
    @Published var updateAvailable: Bool = false
    @Published var permissionsRequired: Bool = false
    @Published var backgroundAppRefreshDenied: Bool = false

    @Published var showApiExpirationWarning = false
    @Published var showSubscriptionExpirationWarning = false

    @Published var isUnlocked = false

    @Published var encryptedSettingsManager = SettingsManager(encrypted: true)
    @Published var settingsManager = SettingsManager(encrypted: false)

    let userResourceChanged = PassthroughSubject<Void, Never>()

    private var cachedUserResource: UserResource? = nil
    private var cachedUserResourceExtended: UserResourceExtended? = nil

    @Published var userResourceData: String? {
        didSet {
            if let jsonString = userResourceData, let jsonData = jsonString.data(using: .utf8) {
                cachedUserResource = try? JSONDecoder().decode(UserResource.self, from: jsonData)
            } else {
                cachedUserResource = nil
            }
            userResourceData.map { encryptedSettingsManager.putSettingsString(key: .userResource, string: $0) }
            userResourceChanged.send()
        }
    }

    var userResource: UserResource? {
        get {
            if cachedUserResource == nil, let jsonString = userResourceData, let jsonData = jsonString.data(using: .utf8) {
                cachedUserResource = try? JSONDecoder().decode(UserResource.self, from: jsonData)
            }
            return cachedUserResource
        }
        set {
            cachedUserResource = newValue
            if let newValue = newValue {
                let encoder = JSONEncoder()
                if let jsonData = try? encoder.encode(newValue),
                   let jsonString = String(data: jsonData, encoding: .utf8)
                {
                    userResourceData = jsonString
                }
            } else {
                userResourceData = nil
            }
        }
    }

    @Published var userResourceExtendedData: String? {
        didSet {
            if let jsonString = userResourceExtendedData, let jsonData = jsonString.data(using: .utf8) {
                cachedUserResourceExtended = try? JSONDecoder().decode(UserResourceExtended.self, from: jsonData)
            } else {
                cachedUserResourceExtended = nil
            }
            userResourceExtendedData.map { encryptedSettingsManager.putSettingsString(key: .userResourceExtended, string: $0) }
        }
    }

    var userResourceExtended: UserResourceExtended? {
        get {
            if cachedUserResourceExtended == nil, let jsonString = userResourceExtendedData, let jsonData = jsonString.data(using: .utf8) {
                cachedUserResourceExtended = try? JSONDecoder().decode(UserResourceExtended.self, from: jsonData)
            }
            return cachedUserResourceExtended
        }
        set {
            cachedUserResourceExtended = newValue
            if let newValue = newValue {
                let encoder = JSONEncoder()
                if let jsonData = try? encoder.encode(newValue),
                   let jsonString = String(data: jsonData, encoding: .utf8)
                {
                    userResourceExtendedData = jsonString
                }
            } else {
                userResourceExtendedData = nil
            }
        }
    }
}
