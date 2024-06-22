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

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "host.stjin.addy.backgroundworker", using: nil) { task in
            // Handle the task
#if DEBUG
            print("handleAppRefresh is gonna get called now")
#endif
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        
        // Check if the app was launched from a shortcut item
        if let shortcutItem = launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            handleShortcutItem(shortcutItem)
        } else {
            print("SHORTCUT IS NIL")
        }
        
        return true
    }
    
    
    func application(_ application: UIApplication,performActionFor shortcutItem: UIApplicationShortcutItem,completionHandler: @escaping (Bool) -> Void) {
        handleShortcutItem(shortcutItem)
        completionHandler(true)
    }
    
    private func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) {
#if DEBUG
        print("SHORTCUT ITEM RECEIVED \(shortcutItem)")
#endif
        if shortcutItem.type == "host.stjin.addy.shortcut_add_alias" {
            MainViewState.shared.isPresentingFailedDeliveriesSheet = true
        } else if shortcutItem.type.starts(with: "host.stjin.addy.shortcut_open_alias_") {
            if let range = shortcutItem.type.range(of: "host.stjin.addy.shortcut_open_alias_") {
                let aliasId = shortcutItem.type[range.upperBound...]
                MainViewState.shared.showAliasWithId = String(aliasId)
                MainViewState.shared.selectedTab = .aliases
            }
            
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
#if DEBUG
        print("App hit background")
#endif
        
        BackgroundWorkerHelper().scheduleBackgroundWorker()
    }
    
    
    func handleAppRefresh(task: BGAppRefreshTask) {
        // Schedule the next refresh task.
        BackgroundWorkerHelper().scheduleBackgroundWorker()
        
        // Create an operation that performs the refresh.
        let operation = BackgroundWorker()
        
        // Provide the completion block for the operation.
        operation.completionBlock = {
            task.setTaskCompleted(success: !operation.isCancelled)
        }
        
        // Add the operation to an operation queue.
        OperationQueue.main.addOperation(operation)
    }
    
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
#if DEBUG
        print("User tapped on a notification with identifier (\(response.actionIdentifier))")
#endif
        
        NotificationActionHelper().handleNotificationActions(response: response)
        
        
        completionHandler()
        
    }
    
    /**
     when a notification arrives and your app is in the foreground, the system calls this method. The completion handler is then called with the .list, .banner and .sound options, which means the alert dialog or banner is presented to the user and the sound associated with the notification is played. This also triggers the userNotificationCenter(_:didReceive:withCompletionHandler:) method.
     */
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.list, .banner, .sound])
    }
    
    
    
}
