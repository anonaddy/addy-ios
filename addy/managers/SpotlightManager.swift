//
//  SpotlightManager.swift
//  addy
//
//  Created by Stijn van de Water on 13/09/2026.
//

import addy_shared
import CoreSpotlight
import Foundation
import UIKit
import UniformTypeIdentifiers

public final class SpotlightManager: Sendable {
    public static let shared = SpotlightManager()

    public static let domainIdentifier = "io.addy.aliases"
    public static let actionDomainIdentifier = "io.addy.actions"
    public static let addAliasActionIdentifier = "host.stjin.addy.spotlight_add_alias"
    private static let lastSyncKey = "SpotlightManager_lastSyncDate"

    private init() {}

    /// Indicates whether Spotlight indexing is currently enabled and permitted by the user's settings.
    public var isEnabled: Bool {
        guard CSSearchableIndex.isIndexingAvailable() else { return false }

        // Privacy mode suppresses Spotlight indexing entirely
        if SettingsManager(encrypted: true).getSettingsBool(key: .privacyMode) {
            return false
        }

        return SettingsManager(encrypted: true).getSettingsBool(key: .spotlightSearch, default: true)
    }

    // MARK: - CoreSpotlight Indexing

    /// Indexes a list of aliases into CoreSpotlight.
    public func indexAliases(aliases: [Aliases]) async {
        guard isEnabled else { return }

        // Separate deleted aliases from active/inactive ones
        let deletedAliases = aliases.filter { $0.deleted_at != nil }
        let validAliases = aliases.filter { $0.deleted_at == nil }

        if !deletedAliases.isEmpty {
            await deindexAliases(ids: deletedAliases.map(\.id))
        }

        await indexStaticActions()

        guard !validAliases.isEmpty else { return }

        let searchableItems: [CSSearchableItem] = validAliases.map { alias in
            let attributeSet = CSSearchableItemAttributeSet(contentType: .emailMessage)
            attributeSet.title = alias.email
            attributeSet.displayName = alias.email

            var descParts: [String] = []
            if let desc = alias.description?.trimmingCharacters(in: .whitespacesAndNewlines), !desc.isEmpty {
                descParts.append(desc)
            }
            let status = alias.active
                ? String(localized: "active", bundle: Bundle(for: SharedData.self))
                : String(localized: "inactive", bundle: Bundle(for: SharedData.self))
            descParts.append(status)

            if let recipients = alias.recipients, !recipients.isEmpty {
                let recipientList = recipients.map(\.email).joined(separator: ", ")
                descParts.append("→ \(recipientList)")
            }
            attributeSet.contentDescription = descParts.joined(separator: " • ")
            attributeSet.emailAddresses = [alias.email]

            var keywords: Set<String> = [
                alias.email,
                alias.local_part,
                alias.domain,
                "alias",
                "addy",
                "addy.io",
                alias.active ? "active" : "inactive",
            ]

            if let desc = alias.description, !desc.isEmpty {
                keywords.insert(desc)
                for word in desc.components(separatedBy: CharacterSet.alphanumerics.inverted) where word.count > 1 {
                    keywords.insert(word)
                }
            }

            if let fromName = alias.from_name, !fromName.isEmpty {
                keywords.insert(fromName)
            }

            if let recipients = alias.recipients {
                for recipient in recipients {
                    keywords.insert(recipient.email)
                }
            }

            if let labels = alias.labels {
                for label in labels {
                    keywords.insert(label.name)
                }
            }

            attributeSet.keywords = Array(keywords)
            attributeSet.identifier = alias.id
            attributeSet.relatedUniqueIdentifier = alias.id
            attributeSet.supportsNavigation = 1
            attributeSet.supportsPhoneCall = 0
            attributeSet.actionIdentifiers = [Self.addAliasActionIdentifier]
            attributeSet.containerTitle = "addy.io"

            let item = CSSearchableItem(
                uniqueIdentifier: alias.id,
                domainIdentifier: Self.domainIdentifier,
                attributeSet: attributeSet
            )
            item.expirationDate = Date.distantFuture
            return item
        }

        do {
            try await CSSearchableIndex.default().indexSearchableItems(searchableItems)
            await indexStaticActions()
            #if DEBUG
                print("Indexed \(searchableItems.count) aliases into Spotlight")
            #endif
        } catch {
            LoggingHelper().addLog(
                importance: .critical,
                error: "Failed to index aliases in Spotlight: \(error.localizedDescription)",
                method: "SpotlightManager.indexAliases",
                extra: nil
            )
        }
    }

    /// Indexes static app actions into CoreSpotlight (e.g. "Add alias").
    public func indexStaticActions() async {
        guard isEnabled else { return }

        let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
        attributeSet.title = String(localized: "add_alias", bundle: Bundle(for: SharedData.self))
        attributeSet.displayName = String(localized: "add_alias", bundle: Bundle(for: SharedData.self))
        attributeSet.contentDescription = String(localized: "app_intent_add_alias_desc")
        attributeSet.keywords = [
            "add",
            "add alias",
            "new alias",
            "create alias",
            "generate alias",
            "alias",
            "addy",
            "email",
        ]
        if let plusImage = UIImage(systemName: "plus.circle.fill") {
            attributeSet.thumbnailData = plusImage.pngData()
        }

        let item = CSSearchableItem(
            uniqueIdentifier: Self.addAliasActionIdentifier,
            domainIdentifier: Self.actionDomainIdentifier,
            attributeSet: attributeSet
        )
        item.expirationDate = Date.distantFuture

        do {
            try await CSSearchableIndex.default().indexSearchableItems([item])
            #if DEBUG
                print("Successfully indexed static Spotlight actions")
            #endif
        } catch {
            LoggingHelper().addLog(
                importance: .warning,
                error: "Failed to index static Spotlight actions: \(error.localizedDescription)",
                method: "SpotlightManager.indexStaticActions",
                extra: nil
            )
        }
    }

    /// Indexes a single alias into CoreSpotlight.
    public func indexAlias(alias: Aliases) async {
        await indexAliases(aliases: [alias])
    }

    /// Removes searchable items with the specified alias IDs from CoreSpotlight.
    public func deindexAliases(ids: [String]) async {
        guard !ids.isEmpty else { return }
        do {
            try await CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: ids)
            #if DEBUG
                print("Deindexed \(ids.count) aliases from Spotlight")
            #endif
        } catch {
            LoggingHelper().addLog(
                importance: .warning,
                error: "Failed to deindex aliases from Spotlight: \(error.localizedDescription)",
                method: "SpotlightManager.deindexAliases",
                extra: nil
            )
        }
    }

    /// Removes a single alias from CoreSpotlight.
    public func deindexAlias(aliasId: String) async {
        await deindexAliases(ids: [aliasId])
    }

    /// Deletes all indexed aliases and actions under this app's domain identifiers.
    public func deleteAllIndexedAliases() async {
        do {
            try await CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [Self.domainIdentifier, Self.actionDomainIdentifier])
            #if DEBUG
                print("Deleted all indexed aliases and actions from Spotlight")
            #endif
        } catch {
            LoggingHelper().addLog(
                importance: .warning,
                error: "Failed to delete all indexed aliases from Spotlight: \(error.localizedDescription)",
                method: "SpotlightManager.deleteAllIndexedAliases",
                extra: nil
            )
        }
    }

    // MARK: - Synchronization

    /// Fetches all non-deleted aliases from the API and indexes them into CoreSpotlight.
    public func syncAllAliases(force: Bool = false) async {
        guard isEnabled else {
            await deleteAllIndexedAliases()
            return
        }

        guard AppState.shared.apiKey != nil else { return }

        var page = 1
        var allAliases: [Aliases] = []
        let request = AliasSortFilterRequest(
            onlyActiveAliases: false,
            onlyDeletedAliases: false,
            onlyInactiveAliases: false,
            onlyWatchedAliases: false,
            onlyPinnedAliases: false,
            sort: "created_at",
            sortDesc: false,
            filter: "",
            label: nil
        )

        do {
            while true {
                let response = try await AliasRepository.shared.getAliases(
                    aliasSortFilterRequest: request,
                    page: page,
                    size: 100
                )
                allAliases.append(contentsOf: response.data)

                if let lastPage = response.meta?.last_page, page < lastPage, page < 10 {
                    page += 1
                } else {
                    break
                }
            }

            await indexAliases(aliases: allAliases)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Self.lastSyncKey)
            #if DEBUG
                print("Successfully synced \(allAliases.count) aliases to Spotlight")
            #endif
        } catch {
            LoggingHelper().addLog(
                importance: .warning,
                error: "Failed to sync aliases for Spotlight: \(error.localizedDescription)",
                method: "SpotlightManager.syncAllAliases",
                extra: nil
            )
        }
    }

    /// Triggers a sync only if more than 24 hours have passed since the last sync.
    public func syncAllAliasesIfNeeded() async {
        guard isEnabled else { return }
        let lastSync = UserDefaults.standard.double(forKey: Self.lastSyncKey)
        let now = Date().timeIntervalSince1970
        let dayInSeconds: Double = 86400

        if lastSync == 0 || (now - lastSync) > dayInSeconds {
            await syncAllAliases(force: false)
        }
    }

    // MARK: - Deep Linking / User Activity Handling

    /// Handles an incoming `NSUserActivity` from CoreSpotlight, navigating the user to the matching alias or action.
    @MainActor
    @discardableResult
    public func handleSpotlightActivity(_ userActivity: NSUserActivity) -> Bool {
        guard userActivity.activityType == CSSearchableItemActionType else {
            return false
        }

        let actionId = userActivity.userInfo?[CSActionIdentifier] as? String
        let activityId = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String

        #if DEBUG
            print("Spotlight user activity received: activityId=\(String(describing: activityId)), actionId=\(String(describing: actionId))")
        #endif

        // Check if the user selected the "Add alias" item or triggered its action button
        if activityId == Self.addAliasActionIdentifier || actionId == Self.addAliasActionIdentifier {
            // Dismiss any obstructing sheets
            MainViewState.shared.isPresentingProfileBottomSheet = false
            MainViewState.shared.isPresentingFailedDeliveriesSheet = false
            MainViewState.shared.isPresentingAccountNotificationsSheet = false

            // Navigate to the Aliases tab and display the Add Alias bottom sheet
            MainViewState.shared.selectedTab = .aliases
            MainViewState.shared.showAddAliasBottomSheet = true
            return true
        }

        guard let aliasId = activityId, !aliasId.isEmpty else {
            return false
        }

        // Dismiss any obstructing sheets
        MainViewState.shared.isPresentingProfileBottomSheet = false
        MainViewState.shared.isPresentingFailedDeliveriesSheet = false
        MainViewState.shared.isPresentingAccountNotificationsSheet = false

        // Select the Aliases tab and navigate to the alias detail view
        MainViewState.shared.selectedTab = .aliases

        if MainViewState.shared.showAliasWithId == aliasId {
            MainViewState.shared.showAliasWithId = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                MainViewState.shared.showAliasWithId = aliasId
            }
        } else {
            MainViewState.shared.showAliasWithId = aliasId
        }

        return true
    }
}
