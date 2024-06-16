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

class BackgroundWorker: Operation {
    
    override func main() {
        if isCancelled {
            return
        }
        
#if DEBUG
        print("BackgroundWorker() called")
#endif
        
        let settingsManager = SettingsManager(encrypted: false)
        let encryptedSettingsManager = SettingsManager(encrypted: true)
        let backgroundWorkerHelper = BackgroundWorkerHelper()
        
        // True if there are aliases to be watched, widgets to be updated or checked for updates
        if (backgroundWorkerHelper.isThereWorkTodo()){
            let networkHelper = NetworkHelper()
            
            // Stored if the network call succeeds its task
            var userResourceNetworkCallResult = false
            var aliasNetworkCallResult = false
            var aliasWatcherNetworkCallResult = false
            var failedDeliveriesNetworkCallResult = false
            
            /**
             In this code, semaphore.signal() is called when each asynchronous function completes, and semaphore.wait() is used to block the current queue until the previous function has signaled completion.
             */
            
            let semaphore = DispatchSemaphore(value: 0)

            DispatchQueue.global().async {
                // Background work here
                
                networkHelper.cacheUserResourceForWidget { result in
                    // Store the result if the data succeeded to update in a boolean
                    userResourceNetworkCallResult = result
                    semaphore.signal()
                }
                semaphore.wait()
                
                
            
                networkHelper.cacheMostPopularAliasesDataForWidget { result in
                    // Store the result if the data succeeded to update in a boolean
                    aliasNetworkCallResult = result
                    semaphore.signal()
                }
                semaphore.wait()
                
                
                /**
                 ALIAS_WATCHER FUNCTIONALITY
                 **/
                
                self.aliasWatcherTask(networkHelper: networkHelper, settingsManager: encryptedSettingsManager) { result in
                    aliasWatcherNetworkCallResult = result
                    semaphore.signal()

                }
                semaphore.wait()

                
                /*
                 UPDATES
                 */
                
                if settingsManager.getSettingsBool(key: .notifyUpdates) {
                    Updater().isUpdateAvailable { (updateAvailable, latestVersion, _, _) in
                        if updateAvailable {
                            if let version = latestVersion {
                                NotificationHelper().createUpdateNotification(version: version)
                            }
                        }
                        semaphore.signal()
                    }
                    semaphore.wait()
                }
               

                
                /*
                 API TOKEN
                 */
                
                if settingsManager.getSettingsBool(key: .notifyApiTokenExpiry, default: true) {
                    networkHelper.getApiTokenDetails { (apiTokenDetails, error) in
                        if let expiresAt = apiTokenDetails?.expires_at {
                            do {
                                let expiryDate = try DateTimeUtils.turnStringIntoLocalDateTime(expiresAt) // Get the expiry date
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
                                    
                                } else {
                                    // The current date is not yet after the deadline date.
                                }
                            } catch {
                                // Panic
                                LoggingHelper().addLog(
                                    importance: LogImportance.critical,
                                    error: "Could not parse expiresAt",
                                    method: "BackgroundWorker",
                                    extra: error.localizedDescription)
                            }
                            
                        }
                        semaphore.signal()
                        // If expires_at is null it will never expire
                    }
                    semaphore.wait()
                }
                
                
                /*
                 DOMAIN ERRORS
                 */
                
                if settingsManager.getSettingsBool(key: .notifyDomainError, default: false) {
                    networkHelper.getDomains { (domains, _) in
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
                        semaphore.signal()
                    }
                    semaphore.wait()
                }
                
                
                /*
                 SUBSCRIPTION EXPIRY
                 */
                
                if settingsManager.getSettingsBool(key: .notifySubscriptionExpiry, default: false) {
                    networkHelper.getUserResource { (user, _) in
                        if let subscriptionEndsAt = user?.subscription_ends_at {
                            do {
                                let expiryDate = try DateTimeUtils.turnStringIntoLocalDateTime(subscriptionEndsAt) // Get the expiry date
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
                            } catch {
                                // Panic
                                LoggingHelper().addLog(
                                    importance: LogImportance.critical,
                                    error: "Could not parse subscriptionEndsAt",
                                    method: "BackgroundWorker",
                                    extra: error.localizedDescription)
                            }
                        }
                        semaphore.signal()
                        // If expires_at is null it will never expire
                    }
                    semaphore.wait()
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

                if settingsManager.getSettingsBool(key: .notifyFailedDeliveries) {
                    networkHelper.cacheFailedDeliveryCountForWidgetAndBackgroundService { (result) in
                        // Store the result if the data succeeded to update in a boolean
                        failedDeliveriesNetworkCallResult = result
                        semaphore.signal()
                    }
                    semaphore.wait()

                    let currentFailedDeliveries = encryptedSettingsManager.getSettingsInt(key: .backgroundServiceCacheFailedDeliveriesCount)
                    let previousFailedDeliveries = encryptedSettingsManager.getSettingsInt(key: .backgroundServiceCacheFailedDeliveriesCountPrevious)
                    // If the current failed delivery count is bigger than the previous list. That means there are new failed deliveries
                    if currentFailedDeliveries > previousFailedDeliveries {
                        NotificationHelper().createFailedDeliveryNotification(difference: currentFailedDeliveries - previousFailedDeliveries)
                    }
                } else {
                    // Not required so always success
                    failedDeliveriesNetworkCallResult = true
                }

                // If the aliasNetwork call was successful, perform the check
               if (aliasWatcherNetworkCallResult) {
                   // Now the data has been updated, perform the AliasWatcher check
                   AliasWatcher().watchAliasesForDifferences()
               }
                
                // Now the data has been updated, we can update the widget as well
                WidgetCenter.shared.reloadAllTimelines()
            }
            
             
        } else {
            backgroundWorkerHelper.cancelScheduledBackgroundWorker()
        }
        
        
        
        if isCancelled {
            return
        }
        
    }
    
    private func aliasWatcherTask(networkHelper: NetworkHelper, settingsManager: SettingsManager, completion: @escaping (Bool) -> Void){
        
        /*
         This method loops through all the aliases that need to be watched and caches those aliases locally
         */
        
        let aliasWatcher = AliasWatcher()
        let aliasesToWatch: [String] = Array(aliasWatcher.getAliasesToWatch())
        
        
        
        if !aliasesToWatch.isEmpty {
            // Get all aliases from the watchList
            networkHelper.bulkGetAlias (completion: { result, _ in
                if let result = result {
                    
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
                } else {
                    // The call failed, it will be logged in NetworkHelper. Try again later
                }
            }, aliases: aliasesToWatch)
        }
        
        completion(true)
    }
    
}
