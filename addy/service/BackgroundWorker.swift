//
//  BackgroundWorker.swift
//  addy
//
//  Created by Stijn van de Water on 12/05/2024.
//

import Foundation
import BackgroundTasks
import addy_shared
import UserNotifications
import WidgetKit
import os.log

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "BackgroundAppRefreshManager")

class BackgroundWorker {
    
    func performRequest(completion: @escaping (Error?) -> Void) {
        
#if DEBUG
        logger.log("BackgroundWorker() called")
        LoggingHelper().addLog(
            importance: LogImportance.info,
            error: "BackgroundWorker() called",
            method: "BackgroundWorker() called",
            extra: nil)
#endif
        
        let settingsManager = SettingsManager(encrypted: false)
        let encryptedSettingsManager = SettingsManager(encrypted: true)
        let backgroundWorkerHelper = BackgroundWorkerHelper()
                    
            Task {
                
                // True if there are aliases to be watched, widgets to be updated or checked for updates
                if (await backgroundWorkerHelper.isThereWorkTodo()){
                    let networkHelper = NetworkHelper()
                    
                    // Background work here
                    
#if DEBUG
                    logger.log("BackgroundWorker task 1")
                    LoggingHelper().addLog(
                        importance: LogImportance.info,
                        error: "Running task 1",
                        method: "BackgroundWorker task 1",
                        extra: nil)
#endif
                    _ = await networkHelper.cacheUserResourceForWidget()
                    
                    
#if DEBUG
                    logger.log("BackgroundWorker task 2")
                    LoggingHelper().addLog(
                        importance: LogImportance.info,
                        error: "Running task 2",
                        method: "BackgroundWorker task 2",
                        extra: nil)
#endif
                    _ = await networkHelper.cacheMostPopularAliasesDataForWidget()
                    
                    
                    
                    
                    /**
                     ALIAS_WATCHER FUNCTIONALITY
                     **/
#if DEBUG
                    logger.log("BackgroundWorker task 3")
                    LoggingHelper().addLog(
                        importance: LogImportance.info,
                        error: "Running task 3",
                        method: "BackgroundWorker task 3",
                        extra: nil)
#endif
                    do {
                        _ = try await self.aliasWatcherTask(networkHelper: networkHelper, settingsManager: encryptedSettingsManager)
                    } catch {
                        logger.log("\(error.localizedDescription)")
                    }
                    
                    
                    /*
                     UPDATES
                     */
                    
#if DEBUG
                    logger.log("BackgroundWorker task 4")
                    LoggingHelper().addLog(
                        importance: LogImportance.info,
                        error: "Running task 4",
                        method: "BackgroundWorker task 4",
                        extra: nil)
#endif
                    if settingsManager.getSettingsBool(key: .notifyUpdates) {
                        do {
                            let (updateAvailable, latestVersion, _, _) = try await Updater().isUpdateAvailable()
                            if updateAvailable {
                                if let version = latestVersion {
                                    NotificationHelper().createUpdateNotification(version: version)
                                }
                            }
                        } catch {
                            logger.log("Failed to check for updates: \(error)")
                        }
                    }
                    
                    
                    
                    /*
                     API TOKEN
                     */
                    
#if DEBUG
                    logger.log("BackgroundWorker task 5")
                    LoggingHelper().addLog(
                        importance: LogImportance.info,
                        error: "Running task 5",
                        method: "BackgroundWorker task 5",
                        extra: nil)
#endif
                    if settingsManager.getSettingsBool(key: .notifyApiTokenExpiry) {
                        do {
                            let apiTokenDetails = try await networkHelper.getApiTokenDetails()
                            if let expiresAt = apiTokenDetails?.expires_at {
                                let expiryDate = try DateTimeUtils.convertStringToLocalTimeZoneDate(expiresAt) // Get the expiry date
                                let currentDateTime = Date() // Get the current date
                                let deadLineDate = Calendar.current.date(byAdding: .day, value: -5, to: expiryDate) // Subtract 5 days from the expiry date
                                if let deadLineDate = deadLineDate, currentDateTime > deadLineDate {
                                    // The current date is suddenly after the deadline date. It will expire within 5 days
                                    // Show the api is about to expire card
                                    
                                    // Check if the notification has already been fired for this day
                                    let previousNotificationLeftDays = encryptedSettingsManager.getSettingsInt(key: .backgroundServiceCacheApiKeyExpiryLeftCount)
                                    let currentLeftDays = Calendar.current.dateComponents([.day], from: currentDateTime, to: deadLineDate).day!
                                    
                                    if previousNotificationLeftDays != currentLeftDays {
                                        encryptedSettingsManager.putSettingsInt(key: .backgroundServiceCacheApiKeyExpiryLeftCount, int: currentLeftDays)
                                        
                                        NotificationHelper().createApiTokenExpiryNotification(daysLeft: expiryDate.futureDateDisplay())
                                    }
                                    
                                }
                            }
                            // If expires_at is null it will never expire
                        } catch {
                            // Panic
                            LoggingHelper().addLog(
                                importance: LogImportance.critical,
                                error: "Could not parse expiresAt",
                                method: "BackgroundWorker",
                                extra: error.localizedDescription)
                        }
                    }
                    
                    
                    
                    
                    
                    /*
                     DOMAIN ERRORS
                     */
                    
#if DEBUG
                    logger.log("BackgroundWorker task 6")
                    LoggingHelper().addLog(
                        importance: LogImportance.info,
                        error: "Running task 6",
                        method: "BackgroundWorker task 6",
                        extra: nil)
#endif
                    Task {
                        if settingsManager.getSettingsBool(key: .notifyDomainError) {
                            do {
                                let domains = try await networkHelper.getDomains()
                                if let domains = domains, !domains.data.isEmpty {
                                    // Check the amount of domains with MX errors
                                    let amountOfDomainsWithErrors = domains.data.filter { $0.domain_mx_validated_at == nil }.count
                                    if amountOfDomainsWithErrors > 0 {
                                        
                                        // Check if the notification has already been fired for this count of domains
                                        let previousNotificationLeftDays = encryptedSettingsManager.getSettingsInt(key: .backgroundServiceCacheDomainErrorCount)
                                        
                                        // If the domains with errors have been changed, fire a notification
                                        if previousNotificationLeftDays != amountOfDomainsWithErrors {
                                            encryptedSettingsManager.putSettingsInt(key: .backgroundServiceCacheDomainErrorCount, int: amountOfDomainsWithErrors)
                                            NotificationHelper().createDomainErrorNotification(count: amountOfDomainsWithErrors)
                                        }
                                        
                                    }
                                }
                            } catch {
                                logger.log("Failed to get domains: \(error)")
                            }
                        }
                    }
                    
                    /*
                     SUBSCRIPTION EXPIRY
                     */
                    
#if DEBUG
                    logger.log("BackgroundWorker task 7")
                    LoggingHelper().addLog(
                        importance: LogImportance.info,
                        error: "Running task 7",
                        method: "BackgroundWorker task 7",
                        extra: nil)
#endif
                    if settingsManager.getSettingsBool(key: .notifySubscriptionExpiry) {
                        do {
                            let user = try await networkHelper.getUserResource()
                            if let subscriptionEndsAt = user?.subscription_ends_at {
                                let expiryDate = try DateTimeUtils.convertStringToLocalTimeZoneDate(subscriptionEndsAt) // Get the expiry date
                                let currentDateTime = Date() // Get the current date
                                let deadLineDate = Calendar.current.date(byAdding: .day, value: -7, to: expiryDate) // Subtract 7 days from the expiry date
                                if let deadLineDate = deadLineDate, currentDateTime > deadLineDate {
                                    // The current date is suddenly after the deadline date. It will expire within 7 days
                                    // Show the subscription is about to expire card
                                    
                                    // Check if the notification has already been fired for this day
                                    let previousNotificationLeftDays = encryptedSettingsManager.getSettingsInt(key: .backgroundServiceCacheSubscriptionExpiryLeftCount)
                                    let currentLeftDays = Calendar.current.dateComponents([.day], from: currentDateTime, to: deadLineDate).day!
                                    
                                    if previousNotificationLeftDays != currentLeftDays {
                                        encryptedSettingsManager.putSettingsInt(key: .backgroundServiceCacheSubscriptionExpiryLeftCount, int: currentLeftDays)
                                        NotificationHelper().createSubscriptionExpiryNotification(daysLeft: expiryDate.futureDateDisplay())
                                    }
                                } else {
                                    // The current date is not yet after the deadline date.
                                }
                            }
                            // If expires_at is null it will never expire
                        } catch {
                            // Panic
                            LoggingHelper().addLog(
                                importance: LogImportance.critical,
                                error: "Could not parse subscriptionEndsAt",
                                method: "BackgroundWorker",
                                extra: error.localizedDescription)
                        }
                    }
                    
                    
                    
                    /*
                     BACKUPS
                     */
                    
                    //                if settingsManager.getSettingsBool(key: .periodicBackups) {
                    //                    let backupHelper = BackupHelper()
                    //                    let date = backupHelper.getLatestBackupDate()?.addingTimeInterval(TimeInterval(Zone.current.secondsFromGMT()))
                    //                    let today = Date()
                    //                    // If the previous backup is *older* than 1 day OR if there is no backup at-all. Create a new backup
                    //                    // Else don't make a new backup
                    //                    if date?.addingTimeInterval(60*60*24) ?? Date.distantPast < today {
                    //                        if backupHelper.createBackup() {
                    //                            // When the backup is successful delete backups older than 30 days
                    //                            backupHelper.deleteBackupsOlderThanXDays(30)
                    //                        } else {
                    //                            NotificationHelper.createFailedBackupNotification(in: appContext)
                    //                        }
                    //                    }
                    //                }
                    
                    
                    /*
                     FAILED DELIVERIES
                     */
                    
#if DEBUG
                    logger.log("BackgroundWorker task 8")
                    LoggingHelper().addLog(
                        importance: LogImportance.info,
                        error: "Running task 8",
                        method: "BackgroundWorker task 8",
                        extra: nil)
#endif
                    if settingsManager.getSettingsBool(key: .notifyFailedDeliveries) {
                        let _ = await networkHelper.cacheFailedDeliveryCountForWidgetAndBackgroundService()
                        // Store the result if the data succeeded to update in a boolean
                        
                        let currentFailedDeliveries = encryptedSettingsManager.getSettingsInt(key: .backgroundServiceCacheFailedDeliveriesCount)
                        let previousFailedDeliveries = encryptedSettingsManager.getSettingsInt(key: .backgroundServiceCacheFailedDeliveriesCountPrevious)
                        // If the current failed delivery count is bigger than the previous list. That means there are new failed deliveries
                        if currentFailedDeliveries > previousFailedDeliveries {
                            NotificationHelper().createFailedDeliveryNotification(difference: currentFailedDeliveries - previousFailedDeliveries)
                        }
                        
                    }
                    
                    /*
                     ACCOUNT NOTIFICATIONS
                     */
                    
#if DEBUG
                    logger.log("BackgroundWorker task 9")
                    LoggingHelper().addLog(
                        importance: LogImportance.info,
                        error: "Running task 9",
                        method: "BackgroundWorker task 9",
                        extra: nil)
#endif
                    if settingsManager.getSettingsBool(key: .notifyAccountNotifications) {
                        let _ = await networkHelper.cacheAccountNotificationsCountForWidgetAndBackgroundService()
                        // Store the result if the data succeeded to update in a boolean
                        
                        let currentAccountNotifications = encryptedSettingsManager.getSettingsInt(key: .backgroundServiceCacheAccountNotificationsCount)
                        let previousAccountNotifications = encryptedSettingsManager.getSettingsInt(key: .backgroundServiceCacheAccountNotificationsCountPrevious)
                        // If the current account notifications count is bigger than the previous list. That means there are new account notifications
                        if currentAccountNotifications > previousAccountNotifications {
                            NotificationHelper().createAccountNotification(difference: currentAccountNotifications - previousAccountNotifications)
                        }
                        
                    }
                    
                    
                    // Now the data has been updated, perform the AliasWatcher check
                    AliasWatcher().watchAliasesForDifferences()
                    
                    
                    // Now the data has been updated, we can update the widget as well
                    WidgetCenter.shared.reloadAllTimelines()
                    
                    completion(nil)
                } else {
                    backgroundWorkerHelper.cancelScheduledBackgroundWorker()
                    completion(nil)
                }
            }
            
        
        
    }
    
    private func aliasWatcherTask(networkHelper: NetworkHelper, settingsManager: SettingsManager) async throws -> Bool {
        /*
         This method loops through all the aliases that need to be watched and caches those aliases locally
         */
        
        let aliasWatcher = AliasWatcher()
        let aliasesToWatch: [String] = Array(aliasWatcher.getAliasesToWatch())
        
        if !aliasesToWatch.isEmpty {
            // Get all aliases from the watchList
            if let result = try await networkHelper.bulkGetAlias(aliases: aliasesToWatch){
                
                // Get a copy of the current list
                let aliasesJson = settingsManager.getSettingsString(key: .backgroundServiceCacheWatchAliasData)
                let aliasesList = aliasesJson.flatMap { GsonTools.jsonToAliasObject(json: $0) }
                
                //region Save a copy of the list
                
                // When the call is successful, save a copy of the current CACHED version to `currentList`
                let currentList = settingsManager.getSettingsString(key: .backgroundServiceCacheWatchAliasData)
                
                // If the current CACHED list is not null, move the current list to the PREV position for AliasWatcher to compare
                // This CACHED list could be null if this would be the first time the service is running
                if let currentList = currentList {
                    settingsManager.putSettingsString(
                        key: .backgroundServiceCacheWatchAliasDataPrevious,
                        string: currentList
                    )
                }
                //endregion
                
                //region CLEANUP DELETED ALIASES
                // Let's say a user forgets this alias using the web-app, but this alias is watched. We need to make sure that the aliases we request
                // Are actually returned. If aliases requested are not returned we can assume the alias has been deleted thus we can delete this alias from the watchlist
                
                for id in aliasesToWatch {
                    if !result.data.contains(where: { $0.id == id }) {
                        // This alias is being watched but not returned, delete it from the watcher
                        
                        LoggingHelper().addLog(
                            importance: .warning,
                            error: String(format: String(localized: "notification_alias_watches_alias_does_not_exist_anymore_desc"),aliasesList?.first { $0.id == id }?.email ?? id
                                         ),
                            method: "aliasWatcherTask",
                            extra: nil
                        )
                        
                        NotificationHelper().createAliasWatcherAliasDoesNotExistAnymoreNotification(
                            email: aliasesList?.first { $0.id == id }?.email ?? id
                        )
                        
                        aliasWatcher.removeAliasToWatch(alias: id)
                    }
                }
                //endregion
                
                
                // Turn the list into a json object
                let data = try? JSONEncoder().encode(result.data)
                
                // Store a copy of the just received data locally
                if let data = data {
                    settingsManager.putSettingsString(key: .backgroundServiceCacheWatchAliasData, string: String(data: data, encoding: .utf8)!)
                }
            }
        }
        
        return true
    }
    
    
}
