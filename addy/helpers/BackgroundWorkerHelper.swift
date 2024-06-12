//
//  BackgroundWorkerHelper.swift
//  addy
//
//  Created by Stijn van de Water on 12/05/2024.
//

import Foundation
import BackgroundTasks
import addy_shared

class BackgroundWorkerHelper: Operation {
    
    
    func scheduleBackgroundWorker() {
        let backgroundServiceIntervalInMinutes = Double(SettingsManager(encrypted: false).getSettingsInt(key: .backgroundServiceInterval, default: 30))
            let request = BGAppRefreshTaskRequest(identifier: "host.stjin.addy.backgroundworker")
            request.earliestBeginDate = Date(timeIntervalSinceNow: backgroundServiceIntervalInMinutes * 60) // Fetch no earlier than 1 minute from now

            do {
                try BGTaskScheduler.shared.submit(request)
            } catch {
                LoggingHelper().addLog(
                                    importance: LogImportance.critical,
                                    error: "Could not schedule app refresh",
                                    method: "scheduleAppRefresh",
                                    extra: error.localizedDescription)
                
                print("Could not schedule app refresh: \(error)")
            }
        }
    
    override func main() {
        if isCancelled {
            return
        }

        // Your data fetching logic goes here.
        // For example, you might call an API to fetch data.
        // Make sure to handle errors appropriately.
        
        print("TEST background task")

        if isCancelled {
            return
        }

        // Once the data is fetched, you can process it as needed.
        // Remember to check `isCancelled` periodically to ensure the operation stops if needed.
    }
}
