//
//  BackgroundWorkerHelper.swift
//  addy
//
//  Created by Stijn van de Water on 12/05/2024.
//

import Foundation
import BackgroundTasks
import addy_shared
import WidgetKit
import os.log
import UIKit


private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "BackgroundAppRefreshManager")
private let backgroundTaskIdentifier = "host.stjin.addy.backgroundworker"

public class BackgroundWorkerHelper {
    static let shared = BackgroundWorkerHelper()
    static let backgroundWorker = BackgroundWorker()
    
    public init() { }
    
    
}

public extension BackgroundWorkerHelper {
    
    func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: .main, launchHandler: handleTask(_:))
    }
    
    func listPendingTasks() {
#if DEBUG
        let scheduler = BGTaskScheduler.shared
        scheduler.getPendingTaskRequests { (tasks) in
            
            print("\(tasks.count) BGTasks pending..")
            
            for task in tasks {
                print("Task Identifier: \(task.identifier)")
                print("Task Earliest Begin Date: \(task.earliestBeginDate ?? Date())")
                // Print other relevant properties
            }
            
        }
#endif
    }
    
    func handleTask(_ task: BGTask) {
        show(message: task.identifier)
        
        BackgroundWorkerHelper.backgroundWorker.performRequest { error in
            task.setTaskCompleted(success: error == nil)
            
            // Schedule for next time
            self.scheduleAppRefresh()
            
        }
        
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
            
            // Schedule for next time
            self.scheduleAppRefresh()
        }
        
    }
    
    func currentConfigurationsAsync() async throws -> [WidgetInfo] {
        try await withCheckedThrowingContinuation { continuation in
            WidgetCenter.shared.getCurrentConfigurations { result in
                continuation.resume(with: result)
            }
        }
    }
    
    
    
    func cancelScheduledBackgroundWorker() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: backgroundTaskIdentifier)
#if DEBUG
        print("Cancelled all work")
#endif
        
    }
    
    func checkBackgroundRefreshStatus() -> Bool {
        // Check the background refresh status
        switch UIApplication.shared.backgroundRefreshStatus {
        case .available:
            LoggingHelper().addLog(
                importance: LogImportance.info,
                error: "Background refresh is available.",
                method: "checkBackgroundRefreshStatus",
                extra: nil)
            return true
        case .denied:
            LoggingHelper().addLog(
                importance: LogImportance.critical,
                error: "Background refresh has been explicitly denied by the user.",
                method: "checkBackgroundRefreshStatus",
                extra: nil)
        case .restricted:
            LoggingHelper().addLog(
                importance: LogImportance.critical,
                error: "Background refresh is restricted, possibly by parental controls or other restrictions.",
                method: "checkBackgroundRefreshStatus",
                extra: nil)
        @unknown default:
            LoggingHelper().addLog(
                importance: LogImportance.critical,
                error: "Unknown background refresh status.",
                method: "checkBackgroundRefreshStatus",
                extra: nil)
        }
        return false
    }
    
    
    
    func scheduleAppRefresh() {
        // Cancel the work to prevent it from being scheduled twice
        cancelScheduledBackgroundWorker()
        
        Task {
            // True if there are aliases to be watched or there are widgets to be updated
            if await isThereWorkTodo() {
                let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
                request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // Fetch no earlier than 15 minute from now
                
                var message = "Scheduled"
                do {
                    try BGTaskScheduler.shared.submit(request)
                    logger.log("task request submitted to scheduler")
                    listPendingTasks()
                    
                    //#warning("add breakpoint at previous line")
                    
                    // at (lldb) prompt, type:
                    //
                    // e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@""host.stjin.addy.backgroundworker""]
                } catch BGTaskScheduler.Error.notPermitted {
                    message = "BGTaskScheduler.shared.submit notPermitted"
                } catch BGTaskScheduler.Error.tooManyPendingTaskRequests {
                    message = "BGTaskScheduler.shared.submit tooManyPendingTaskRequests"
                } catch BGTaskScheduler.Error.unavailable {
                    message = "BGTaskScheduler.shared.submit unavailable"
                } catch {
                    message = "BGTaskScheduler.shared.submit \(error.localizedDescription)"
                }
                
                show(message: message)
            }
        }
    }
    
    
    func isThereWorkTodo() async -> Bool {
        let settingsManager = SettingsManager(encrypted: false)
        let encryptedSettingsManager = SettingsManager(encrypted: true)
        
        if encryptedSettingsManager.getSettingsString(key: .apiKey) != nil {
            
            // Count amount of aliases to be watched
            let aliasToWatch = AliasWatcher().getAliasesToWatch()
            // Count amount of widgets
            var amountOfWidgets = 0
            
            do {
                amountOfWidgets = try await currentConfigurationsAsync().count
            } catch {
                LoggingHelper().addLog(
                    importance: LogImportance.critical,
                    error: "Could not obtain currentConfigurationsAsync",
                    method: "isThereWorkTodo",
                    extra: error.localizedDescription)
            }
            
            
            
            
            let shouldCheckForUpdates = settingsManager.getSettingsBool(key: .notifyUpdates)
            let shouldCheckForFailedDeliveries = settingsManager.getSettingsBool(key: .notifyFailedDeliveries)
            let shouldCheckForAccountNotifications = settingsManager.getSettingsBool(key: .notifyAccountNotifications)
            let shouldCheckApiTokenExpiry = settingsManager.getSettingsBool(key: .notifyApiTokenExpiry)
            //let shouldMakePeriodicBackups = settingsManager.getSettingsBool(key:  .periodicBackups)
            
            // If there are
            // -aliases to be watched
            // -widgets to be updated
            // -app updates to be checked for in the background
            // -failed deliveries to be checked
            // --return true
            
#if DEBUG
            print("isThereWorkTodo: aliasToWatch=\(aliasToWatch);amountOfWidgets=\(amountOfWidgets);NOTIFY_UPDATES=\(shouldCheckForUpdates);NOTIFY_FAILED_DELIVERIES=\(shouldCheckForFailedDeliveries);NOTIFY_ACCOUNT_NOTIFICATIONS=\(shouldCheckForAccountNotifications)")
#endif
            
            
            return (!aliasToWatch.isEmpty || amountOfWidgets > 0 || shouldCheckForUpdates || shouldCheckForFailedDeliveries || shouldCheckForAccountNotifications || shouldCheckApiTokenExpiry)
        } else {
            return false
        }
    }
    
}

// MARK: - Private utility methods

private extension BackgroundWorkerHelper {
    
    func show(message: String) {
        
        logger.debug("\(message, privacy: .public)")
        LoggingHelper().addLog(
            importance: LogImportance.warning,
            error: "AppRefresh task",
            method: "BackgroundWorkerHelper.show",
            extra: message)
    }
}





