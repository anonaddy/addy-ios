//
//  AppDelegate.swift
//  addy
//
//  Created by Stijn van de Water on 12/06/2024.
//

import Foundation
import SwiftUI
import BackgroundTasks
import addy_shared

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "host.stjin.addy.backgroundworker", using: nil) { task in
                // Handle the task
                self.handleAppRefresh(task: task as! BGAppRefreshTask)
            }

        return true
    }
    
    
    func handleAppRefresh(task: BGAppRefreshTask) {
        // Schedule the next refresh task.
        BackgroundWorkerHelper().scheduleBackgroundWorker()

        // Create an operation that performs the refresh.
        let operation = BackgroundWorkerHelper()

        // Provide the completion block for the operation.
        operation.completionBlock = {
            task.setTaskCompleted(success: !operation.isCancelled)
        }

        // Add the operation to an operation queue.
        OperationQueue.main.addOperation(operation)
    }

    
    
}
