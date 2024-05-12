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
        guard let aliasesToWatch = encryptedSettingsManager.getStringSet(key: SettingsManager.Prefs.backgroundServiceWatchAliasList),
              let aliasesJson = encryptedSettingsManager.getSettingsString(key: SettingsManager.Prefs.backgroundServiceCacheWatchAliasData),
              let previousAliasesJson = encryptedSettingsManager.getSettingsString(key: SettingsManager.Prefs.backgroundServiceCacheWatchAliasDataPrevious),
              let aliasesList = GsonTools.jsonToAliasObject(json: aliasesJson),
              
                
                
                let aliasesListPrevious = GsonTools.jsonToAliasObject(json: previousAliasesJson) else { return }

        for alias in aliasesList {
            let currentEmailsForwarded = alias.emails_forwarded
            let index = aliasesListPrevious.firstIndex { $0.id == alias.id }
            let previousEmailsForwarded = index == nil ? 0 : aliasesListPrevious[index!].emails_forwarded

            if currentEmailsForwarded > previousEmailsForwarded {
                NotificationHelper().createAliasWatcherNotification(
                    emailDifference: currentEmailsForwarded - previousEmailsForwarded,
                    id: alias.id,
                    email: alias.email
                )
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
            BackgroundWorkerHelper().scheduleBackgroundWorker()
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
                BackgroundWorkerHelper().scheduleBackgroundWorker()
            }
            return true
        }
    }
}
