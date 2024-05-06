//
//  SettingsManager.swift
//  addy
//
//  Created by Stijn van de Water on 06/05/2024.
//

import Foundation

import Foundation

class SettingsManager {
    enum PrefTypes {
        case boolean
        case string
        case int
        case float
        case stringSet
    }

    enum Prefs {
        case darkMode
        case dynamicColors
        case storeLogs
        case versionCode
        case backgroundServiceInterval
        case widgetsActive
        case notifyUpdates
        case periodicBackups
        case backupsLocation
        case notifyFailedDeliveries
        case manageMultipleAliases
        case notifyApiTokenExpiry
        case notifyDomainError
        case notifySubscriptionExpiry
        case mailtoActivityShowSuggestions
        case aliasSortFilter
        case biometricEnabled
        case privacyMode
        case apiKey // Is only used for keychain API
        case baseUrl
        case recentSearches
        case backupsPassword
        case userResource
        case userResourceExtended
        case wearosSkipAliasCreateGuide
        case wearosFavoriteAliases
        case disableWearosQuickSetupDialog
        case selectedWearosDevice
        case backgroundServiceCacheFavoriteAliasesData
        case backgroundServiceCacheMostActiveAliasesData
        case backgroundServiceCacheLastUpdatedAliasesData
        case backgroundServiceCacheDomainCount
        case backgroundServiceCacheUserResource
        case backgroundServiceCacheUsernameCount
        case backgroundServiceCacheRulesCount
        case backgroundServiceCacheRecipientCount
        case backgroundServiceCacheFailedDeliveriesCount
        case backgroundServiceCacheApiKeyExpiryLeftCount
        case backgroundServiceCacheSubscriptionExpiryLeftCount
        case backgroundServiceCacheDomainErrorCount
        case backgroundServiceCacheFailedDeliveriesCountPrevious
        case backgroundServiceWatchAliasList
        case backgroundServiceCacheWatchAliasData
        case backgroundServiceCacheWatchAliasDataPrevious
    }

    private let user = 1
    private let prefs: UserDefaults = UserDefaults.standard

    func putSettingsBool(key: Prefs, boolean: Bool) {
        prefs.set(boolean, forKey: "\(key)")
    }

    func getSettingsBool(key: Prefs, default: Bool = false) -> Bool {
        return prefs.bool(forKey: "\(key)")
    }

    func putSettingsString(key: Prefs, string: String) {
        prefs.set(string, forKey: "\(key)")
    }

    func getSettingsString(key: Prefs) -> String? {
        return prefs.string(forKey: "\(key)")
    }

    func putSettingsInt(key: Prefs, int: Int) {
        prefs.set(int, forKey: "\(key)")
    }

    func getSettingsInt(key: Prefs, default: Int = 0) -> Int {
        return prefs.integer(forKey: "\(key)")
    }

    func putSettingsFloat(key: Prefs, float: Float) {
        prefs.set(float, forKey: "\(key)")
    }

    func getSettingsFloat(key: Prefs) -> Float {
        return prefs.float(forKey: "\(key)")
    }

    func putStringSet(key: Prefs, mutableSet: Set<String>) {
        prefs.set(mutableSet, forKey: "\(key)")
    }

    func getStringSet(key: Prefs) -> Set<String>? {
        guard let array = prefs.array(forKey: "\(key)") as? [String] else {
            return nil
        }
        return Set(array)
    }


    func removeSetting(value: Prefs) {
        prefs.removeObject(forKey: "\(value)")
    }

    func clearAllData() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
    }
}
