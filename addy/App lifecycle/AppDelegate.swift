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
    
    var window: UIWindow?
    
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        if let shortcutItem = options.shortcutItem {
            QuickActionsManager.instance.handleQaItem(shortcutItem)
        }
        
        let sceneConfiguration = UISceneConfiguration(name: "Custom Configuration", sessionRole: connectingSceneSession.role)
        sceneConfiguration.delegateClass = CustomSceneDelegate.self
        
        return sceneConfiguration
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        UNUserNotificationCenter.current().delegate = self
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "host.stjin.addy.backgroundworker", using: nil) { task in
            // Handle the task
#if DEBUG
            print("handleAppRefresh is gonna get called now")
#endif
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        
        return true
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


class CustomSceneDelegate: UIResponder, UIWindowSceneDelegate {
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        QuickActionsManager.instance.handleQaItem(shortcutItem)
    }
}
