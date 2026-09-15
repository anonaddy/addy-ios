//
//  AppDelegate.swift
//  addy
//
//  Created by Stijn van de Water on 12/06/2024.
//

import Foundation
import SwiftUI

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var window: UIWindow?

    func application(_: UIApplication, continue userActivity: NSUserActivity, restorationHandler _: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if SpotlightManager.shared.handleSpotlightActivity(userActivity) {
            return true
        }

        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL
        else {
            return false
        }

        return MainViewState.shared.handleIncomingURL(url)
    }

    func application(_: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        if let shortcutItem = options.shortcutItem {
            QuickActionsManager.shared.handleQaItem(shortcutItem)
        }

        let sceneConfiguration = UISceneConfiguration(name: "Custom Configuration", sessionRole: connectingSceneSession.role)
        sceneConfiguration.delegateClass = CustomSceneDelegate.self

        return sceneConfiguration
    }

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self

        BackgroundWorkerHelper.shared.register()

        return true
    }

    func userNotificationCenter(_: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        #if DEBUG
            print("User tapped on a notification with identifier (\(response.actionIdentifier))")
        #endif

        NotificationActionHelper().handleNotificationActions(response: response)

        completionHandler()
    }

    /* 
     when a notification arrives and your app is in the foreground, the system calls this method. The completion handler is then called with the .list, .banner and .sound options, which means the alert dialog or banner is presented to the user and the sound associated with the notification is played. This also triggers the userNotificationCenter(_:didReceive:withCompletionHandler:) method.
     */

    func userNotificationCenter(_: UNUserNotificationCenter, willPresent _: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.list, .banner, .sound])
    }
}

class CustomSceneDelegate: UIResponder, UIWindowSceneDelegate {
    func windowScene(_: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler _: @escaping (Bool) -> Void) {
        QuickActionsManager.shared.handleQaItem(shortcutItem)
    }

    func sceneDidEnterBackground(_: UIScene) {
        #if DEBUG
            print("Scene hit background")
        #endif

        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        BackgroundWorkerHelper.shared.scheduleAppRefresh()
    }

    /**
     NOTE: Please note that even thought addy.io is able to parse mailto: URI's, it cannot be the default mail handler on iOS due to limitation with Apple's OS
     https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_developer_mail-client
     */
    func scene(_: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            _ = MainViewState.shared.handleIncomingURL(url)
        }
    }

    func scene(_: UIScene, continue userActivity: NSUserActivity) {
        if SpotlightManager.shared.handleSpotlightActivity(userActivity) {
            return
        }
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL {
            _ = MainViewState.shared.handleIncomingURL(url)
        }
    }

    /// This function is called when your app launches.
    /// Check to see if our app was launched with a universal link.
    func scene(_: UIScene, willConnectTo _: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        for userActivity in connectionOptions.userActivities {
            if SpotlightManager.shared.handleSpotlightActivity(userActivity) {
                break
            }
            if userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL {
                _ = MainViewState.shared.handleIncomingURL(url)
                break
            }
        }

        if let urlContext = connectionOptions.urlContexts.first {
            _ = MainViewState.shared.handleIncomingURL(urlContext.url)
        }
    }
}
