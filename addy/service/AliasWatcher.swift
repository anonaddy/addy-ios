//
//  AliasWatcher.swift
//  addy
//
//  Created by Stijn van de Water on 12/05/2024.
//

import addy_shared

class AliasWatcher {
    var encryptedSettingsManager: SettingsManager
    
    init() {
        self.encryptedSettingsManager = SettingsManager(encrypted: true)
    }
    
    func watchAliasesForDifferences() {
        let aliasesToWatch = encryptedSettingsManager.getStringSet(key: .backgroundServiceWatchAliasList)
        let aliasesJson = encryptedSettingsManager.getSettingsString(key: .backgroundServiceCacheWatchAliasData)
        let previousAliasesJson = encryptedSettingsManager.getSettingsString(key: .backgroundServiceCacheWatchAliasDataPrevious)
        
        // Turn the 2 alias en previousAlias jsons into objects.
        let aliasesList = aliasesJson != nil ? GsonTools.jsonToAliasObject(json: aliasesJson!) : nil
        let aliasesListPrevious = previousAliasesJson != nil ? GsonTools.jsonToAliasObject(json: previousAliasesJson!) : nil
        
        // Iterate through the new list, if an alias is on the watchlist, try to look up the emails_forwarded amount from the old list and compare it with
       // the new one

       // if aliasesToWatch is empty, skip everything, don't compare because there is nothing to be compared
        if let aliasesToWatch = aliasesToWatch, !aliasesToWatch.isEmpty {
            // if aliasesList is empty or null, skip everything, don't compare as there is no list
            if let aliasesList = aliasesList, !aliasesList.isEmpty {
                
                for alias in aliasesList {
                    let currentEmailsForwarded = alias.emails_forwarded
                    
                    let index = aliasesListPrevious?.firstIndex { $0.id == alias.id }
                    
                    let previousEmailsForwarded = index == nil ? 0 : aliasesListPrevious![index!].emails_forwarded
                    
                    if currentEmailsForwarded > previousEmailsForwarded {
                        NotificationHelper().createAliasWatcherNotification(
                            emailDifference: currentEmailsForwarded - previousEmailsForwarded,
                            id: alias.id,
                            email: alias.email
                        )
                    }
                }
            }

        }
        
        
        
    }
    
    func getAliasesToWatch() -> Set<String> {
        return encryptedSettingsManager.getStringSet(key: SettingsManager.Prefs.backgroundServiceWatchAliasList) ?? []
    }
    
    func removeAliasToWatch(alias: String) {
        var aliasList = getAliasesToWatch()
        
        if aliasList.contains(alias) {
            aliasList.remove(alias)
            encryptedSettingsManager.putStringSet(key: SettingsManager.Prefs.backgroundServiceWatchAliasList, mutableSet: aliasList)
            //BackgroundWorker().scheduleBackgroundWorker()
        }
    }
    
    func addAliasToWatch(alias: String) -> Bool {
        var aliasList = getAliasesToWatch()
        
        if aliasList.count > 24 {
            LoggingHelper().addLog(importance: LogImportance.warning, error: String(localized: "aliaswatcher_max_reached"), method: "addAliasToWatch", extra: nil)
            return false
        } else {
            if !aliasList.contains(alias) {
                aliasList.insert(alias)
                encryptedSettingsManager.putStringSet(key: SettingsManager.Prefs.backgroundServiceWatchAliasList, mutableSet: aliasList)
                //BackgroundWorker().scheduleBackgroundWorker()
            }
            return true
        }
    }
}
