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
class BackgroundWorkerHelper {
    
    
    func scheduleBackgroundWorker() {
        let request = BGAppRefreshTaskRequest(identifier: "host.stjin.addy.backgroundworker")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // Fetch no earlier than 1 minute from now
        
        do {
            
#if DEBUG
            print("Scheduled backgroundworker for at least \(15) minutes.")
#endif
            
            
            
            // Manually triggr with
            // e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"host.stjin.addy.backgroundworker"]
            
            BackgroundWorker().main()
            
            try BGTaskScheduler.shared.submit(request)
            // Run the Background worked immediately after scheduling
        } catch {
            LoggingHelper().addLog(
                importance: LogImportance.critical,
                error: "Could not schedule app refresh",
                method: "scheduleAppRefresh",
                extra: error.localizedDescription)
            
            
#if DEBUG
            print("Could not schedule app refresh: \(error)")
#endif
            
        }
    }
    
    
    func cancelScheduledBackgroundWorker() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: "host.stjin.addy.backgroundworker")
#if DEBUG
        print("Cancelled all work")
#endif
        
    }
    
    public func currentConfigurationsAsync() async throws -> [WidgetInfo] {
        try await withCheckedThrowingContinuation { continuation in
            WidgetCenter.shared.getCurrentConfigurations { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func isThereWorkTodo() async -> Bool {
        let settingsManager = SettingsManager(encrypted: false)
        
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
        let shouldCheckApiTokenExpiry = settingsManager.getSettingsBool(key: .notifyApiTokenExpiry)
        //let shouldMakePeriodicBackups = settingsManager.getSettingsBool(key:  .periodicBackups)
        
        // If there are
        // -aliases to be watched
        // -widgets to be updated
        // -app updates to be checked for in the background
        // -failed deliveries to be checked
        // --return true
        
#if DEBUG            
        print("isThereWorkTodo: aliasToWatch=\(aliasToWatch);amountOfWidgets=\(amountOfWidgets);NOTIFY_UPDATES=\(shouldCheckForUpdates);NOTIFY_FAILED_DELIVERIES=\(shouldCheckForFailedDeliveries)")
#endif

        
        return (!aliasToWatch.isEmpty || amountOfWidgets > 0 || shouldCheckForUpdates || shouldCheckForFailedDeliveries || shouldCheckApiTokenExpiry)
    }
    
}
