//
//  AppDelegate.swift
//  addy
//
//  Created by Stijn van de Water on 12/06/2024.
//

import Foundation
import SwiftUI
import BackgroundTasks

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL,
              let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
              let pathComponents = components.path?.components(separatedBy: "/") else {
            return false
        }

        // Check if the URL is in the expected format
        if pathComponents.count > 2 && pathComponents[1] == "deactivate" {
            let id = pathComponents[2]
            MainViewState.shared.aliasToDisable = id
            MainViewState.shared.selectedTab = .aliases
        }

        return true
    }



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
    
    //TODO: Check if this  + above works
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.list, .banner, .sound])
    }
    
    
    
}


class CustomSceneDelegate: UIResponder, UIWindowSceneDelegate {
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        QuickActionsManager.instance.handleQaItem(shortcutItem)
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
#if DEBUG
        print("Scene hit background")
#endif
        
        BackgroundWorkerHelper().scheduleBackgroundWorker()
    }
    

    /**
     NOTE: Please note that even thought addy.io is able to parse mailto: URI's, it cannot be the default mail handler on iOS due to limitation with Apple's OS
     https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_developer_mail-client
     */
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            if url.scheme == "mailto" {
                // Handle the email URL
                MainViewState.shared.mailToActionSheetData = MailToActionSheetData(value: url.absoluteString)
                return
            }
        }
    }
    
    
    // This function is called when your app launches.
    // Check to see if our app was launched with a universal link.
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        
        if let urlContext = connectionOptions.urlContexts.first {
            let url = urlContext.url
            if url.scheme?.lowercased() == "mailto" {
                // Handle mailto URL
                MainViewState.shared.mailToActionSheetData = MailToActionSheetData(value: url.absoluteString)

            }
        }
        
    }
}
