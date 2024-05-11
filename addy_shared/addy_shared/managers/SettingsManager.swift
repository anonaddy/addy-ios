//
//  SettingsManager.swift
//  addy
//
//  Created by Stijn van de Water on 06/05/2024.
//

import Foundation

import Foundation
import UIKit

public class SettingsManager {
    enum PrefTypes {
        case boolean
        case string
        case int
        case float
        case stringSet
    }
    
    public enum Prefs {
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
        case apiKey
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
    
    
    /*
     This user val is made for possible multiple user support. Defaulting to 1 for now.
     */
    private let user: Int
    private let prefs: UserDefaults?
    private let keychain = KeychainSwift()
    private let useKeychain: Bool
    
    
    public init(encrypted: Bool, user: Int = 1) {
        self.user = user
        self.useKeychain = encrypted
        
        if encrypted {
            self.prefs = nil
        } else {
            self.prefs = UserDefaults.standard
        }
    }
    
    func putSettingsBool(key: Prefs, boolean: Bool) {
        let userKey = "\(user)_\(key)"
        
        if useKeychain {
            keychain.set(boolean, forKey: userKey)
        } else {
            prefs?.set(boolean, forKey: userKey)
        }
    }
    
    public func getSettingsBool(key: Prefs, default: Bool = false) -> Bool {
        let userKey = "\(user)_\(key)"
        
        if useKeychain {
            return keychain.getBool(userKey) ?? `default`
        } else {
            return prefs?.bool(forKey: userKey) ?? `default`
        }
    }
    
    public func putSettingsString(key: Prefs, string: String) {
        let userKey = "\(user)_\(key)"
        if useKeychain {
            keychain.set(string, forKey: userKey)
        } else {
            prefs?.set(string, forKey: userKey)
        }
    }
    
    public func getSettingsString(key: Prefs) -> String? {
        let userKey = "\(user)_\(key)"
        if useKeychain {
            return keychain.get(userKey)
        } else {
            return prefs?.string(forKey: userKey)
        }
    }
    
    func putSettingsInt(key: Prefs, int: Int) {
        let userKey = "\(user)_\(key)"
        if useKeychain {
            keychain.set("\(int)", forKey: userKey)
        } else {
            prefs?.set(int, forKey: userKey)
        }
    }
    
    func getSettingsInt(key: Prefs, default: Int = 0) -> Int {
        let userKey = "\(user)_\(key)"
        if useKeychain {
            return Int(keychain.get(userKey)!) ?? `default`
        } else {
            return prefs?.integer(forKey: userKey) ?? `default`
        }
    }
    
    func putSettingsFloat(key: Prefs, float: Float) {
        let userKey = "\(user)_\(key)"
        if useKeychain {
            keychain.set("\(float)", forKey: userKey)
        } else {
            prefs?.set(float, forKey: userKey)
        }
    }
    
    func getSettingsFloat(key: Prefs) -> Float {
        let userKey = "\(user)_\(key)"
        if useKeychain {
            return Float(keychain.get(userKey)!) ?? 0.0
        } else {
            return prefs?.float(forKey: userKey) ?? 0.0
        }
    }
    
    func putStringSet(key: Prefs, mutableSet: Set<String>) {
        let userKey = "\(user)_\(key)"
        if useKeychain {
            let array = Array(mutableSet)
            if let data = try? JSONEncoder().encode(array) {
                keychain.set(data, forKey: userKey)
            }
        } else {
            prefs?.set(Array(mutableSet), forKey: userKey)
        }
    }
    
    func getStringSet(key: Prefs) -> Set<String>? {
        let userKey = "\(user)_\(key)"
        if useKeychain {
            if let data = keychain.getData(userKey),
               let array = try? JSONDecoder().decode([String].self, from: data) {
                return Set(array)
            }
            return nil
        } else {
            guard let array = prefs?.array(forKey: userKey) as? [String] else {
                return nil
            }
            return Set(array)
        }
    }
    
    func removeSetting(value: Prefs) {
        let userKey = "\(user)_\(value)"
        if useKeychain {
            keychain.delete(userKey)
        } else {
            prefs?.removeObject(forKey: userKey)
        }
    }
    
    public func clearAllData() {
        if useKeychain {
            keychain.clear()
        } else {
            let domain = Bundle.main.bundleIdentifier!
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.synchronize()
        }
    }
    
        /*
        Clears all the settings and closes the app
         */

    public func clearSettingsAndCloseApp(){
        SettingsManager(encrypted: true).clearAllData()
        SettingsManager(encrypted: false).clearAllData()
        
        //TODO: AGAINST GUIDELINES
        exit(0)
    }
    
}
