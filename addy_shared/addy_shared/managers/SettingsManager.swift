//
//  SettingsManager.swift
//  addy
//
//  Created by Stijn van de Water on 06/05/2024.
//

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
        case notifyUpdates
        case periodicBackups
        case backupsLocation
        case notifyFailedDeliveries
        case notifyApiTokenExpiry
        case notifyDomainError
        case notifySubscriptionExpiry
        case mailtoActivityShowSuggestions
        case aliasSortFilter
        case pendingURLFromShareViewController
        case biometricEnabled
        case privacyMode
        case apiKey
        case baseUrl
        case recentSearches
        case backupsPassword
        case userResource
        case userResourceExtended
        case backgroundServiceCacheMostActiveAliasesData

        
        // WearOS
        case backgroundServiceCacheFavoriteAliasesData
        case backgroundServiceCacheLastUpdatedAliasesData

        
        //case backgroundServiceCacheUserResource // Is .userResource in Android version
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
#if DEBUG
        let suiteName = "group.host.stjin.addy.debug"

        #else
        let suiteName = "group.host.stjin.addy"
#endif
        keychain.accessGroup = suiteName

        if encrypted {
            self.prefs = nil
        } else {
            self.prefs = UserDefaults(suiteName: suiteName)
        }
        
        print("SettingsManager initialized with suiteName: \(suiteName)")

    }
    
    public func putSettingsBool(key: Prefs, boolean: Bool) {
        let userKey = "\(user)_\(key)"
        
        if useKeychain {
            keychain.set(boolean, forKey: userKey, withAccess: .accessibleAfterFirstUnlock)
        } else {
            prefs?.set(boolean, forKey: userKey)
        }
    }
    
    public func getSettingsBool(key: Prefs) -> Bool {
        let userKey = "\(user)_\(key)"
        
        if useKeychain {
            return keychain.getBool(userKey) ?? false
        } else {
            return prefs?.bool(forKey: userKey) ?? false
        }
    }
    
    public func putSettingsString(key: Prefs, string: String) {
        let userKey = "\(user)_\(key)"
        if useKeychain {
            keychain.set(string, forKey: userKey, withAccess: .accessibleAfterFirstUnlock)
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
    
    public func putSettingsInt(key: Prefs, int: Int) {
        let userKey = "\(user)_\(key)"
        if useKeychain {
            keychain.set("\(int)", forKey: userKey, withAccess: .accessibleAfterFirstUnlock)
        } else {
            prefs?.set(int, forKey: userKey)
        }
    }
    
    public func getSettingsInt(key: Prefs, default: Int = 0) -> Int {
        let userKey = "\(user)_\(key)"
        if useKeychain {
            return Int(keychain.get(userKey) ?? String(`default`)) ?? `default`
        } else {
            if let value = prefs?.object(forKey: userKey) as? Int {
                return value
            } else {
                // This line will be executed if the key does not exist
                return `default`
            }
        }
    }

    
    func putSettingsFloat(key: Prefs, float: Float) {
        let userKey = "\(user)_\(key)"
        if useKeychain {
            keychain.set("\(float)", forKey: userKey, withAccess: .accessibleAfterFirstUnlock)
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
    
    public func putStringSet(key: Prefs, mutableSet: Set<String>) {
        let userKey = "\(user)_\(key)"
        if useKeychain {
            let array = Array(mutableSet)
            if let data = try? JSONEncoder().encode(array) {
                keychain.set(data, forKey: userKey, withAccess: .accessibleAfterFirstUnlock)
            }
        } else {
            prefs?.set(Array(mutableSet), forKey: userKey)
        }
    }
    
    public func getStringSet(key: Prefs) -> Set<String>? {
        let userKey = "\(user)_\(key)"
        if useKeychain {
            if let data = keychain.getData(userKey),
               let array = try? JSONDecoder().decode([String].self, from: data) {
                return Set(array)
            }
            return Set()
        } else {
            guard let array = prefs?.array(forKey: userKey) as? [String] else {
                return Set()
            }
            return Set(array)
        }
    }
    
    public func removeSetting(key: Prefs) {
        let userKey = "\(user)_\(key)"
        if useKeychain {
            keychain.delete(userKey)
        } else {
            prefs?.removeObject(forKey: userKey)
        }
    }
    
    private func clearAllData() {
        if useKeychain {
            keychain.clear()
        } else {
            
#if DEBUG
        let suiteName = "group.host.stjin.addy.debug"

        #else
        let suiteName = "group.host.stjin.addy"
#endif
            
            let keys = UserDefaults(suiteName: suiteName)?.dictionaryRepresentation().keys
            for key in keys! {
                prefs?.removeObject(forKey: key)
            }

        }

        #if DEBUG
        // Don't clear logs on debug
#else
        LoggingHelper().clearLogs()
#endif
        
    }
    
        /*
        Clears all the settings
         */

    public func clearSettingsAndCloseApp(){
        
        // Clear shortcuts
        UIApplication.shared.shortcutItems = []
        
        SettingsManager(encrypted: false).clearAllData()
        SettingsManager(encrypted: true).clearAllData()

        DispatchQueue.main.async {
            // remove API from memory (will also reset the viewstate)
            AppState.shared.apiKey = nil
        }
    }
    
}
