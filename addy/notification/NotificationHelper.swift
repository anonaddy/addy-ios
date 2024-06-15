//
//  NotificationHelper.swift
//  addy_shared
//
//  Created by Stijn van de Water on 12/05/2024.
//

import Foundation
import UserNotifications
import addy_shared

public struct notificationActions {
    static let openSettings = "openSettings"
    static let openAlias = "openAlias"
    static let disableAlias = "disable_alias"


    
    
    static let stopWatching = "stop_watching"
    static let stopUpdateCheck = "stop_update_check"
    static let STOP_FAILED_DELIVERY_CHECK = "stop_failed_delivery_check"
    static let STOP_DOMAIN_ERROR_CHECK = "stop_domain_error_check"
    static let STOP_API_EXPIRY_CHECK = "stop_api_expiry_check"
    static let STOP_SUBSCRIPTION_EXPIRY_CHECK = "stop_subscription_expiry_check"
    static let STOP_PERIODIC_BACKUPS = "stop_periodic_backups"
    static let DISABLE_WEAROS_QUICK_SETUP = "disable_wearos_quick_setup"
}

class NotificationHelper{


    
    public func createAliasWatcherNotification(emailDifference: Int, id: String, email: String){
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification_new_emails")
        
        if SettingsManager(encrypted: true).getSettingsBool(key: .privacyMode, default: false){
            content.subtitle = String(format: String(localized: "notification_new_emails_desc"), String(emailDifference), String(localized: "one_of_your_aliases"))
        } else {
            content.subtitle = String(format: String(localized: "notification_new_emails_desc"), String(emailDifference), email)
        }
        
        
        content.sound = nil
        
        content.userInfo = ["aliasId": id]

        
        let action1 = UNNotificationAction(identifier: notificationActions.disableAlias, title: String(localized: "disable_alias"), options: [.foreground])
        let action2 = UNNotificationAction(identifier: notificationActions.stopWatching, title: String(localized: "stop_watching"), options: [])
        let category = UNNotificationCategory(identifier: notificationActions.openAlias, actions: [action1,action2], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = notificationActions.openAlias


        // show this notification five seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        // choose a random identifier
        let request = UNNotificationRequest(identifier: notificationActions.openAlias, content: content, trigger: trigger)

        // add our notification request
        UNUserNotificationCenter.current().add(request)
        
        
        
    }
    
    public func createAliasWatcherAliasDoesNotExistAnymoreNotification(email: String){
        
        let content = UNMutableNotificationContent()
        content.title = "Feed the cat"
        content.subtitle = "It looks hungry"
        content.sound = UNNotificationSound.default

        // show this notification five seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

        // choose a random identifier
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        // add our notification request
        UNUserNotificationCenter.current().add(request)
        
        
        
    }
    
    public func createUpdateNotification(version: String){
        
        let content = UNMutableNotificationContent()
        content.title = String(localized: "new_update_available")
        content.subtitle = String(format: String(localized: "notification_new_update_available_desc"), version)
        content.sound = nil
        
        let action1 = UNNotificationAction(identifier: notificationActions.stopUpdateCheck, title: String(localized: "stop_checking"), options: [])
        let category = UNNotificationCategory(identifier: notificationActions.openSettings, actions: [action1], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = notificationActions.openSettings


        // show this notification five seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        // choose a random identifier
        let request = UNNotificationRequest(identifier: notificationActions.openSettings, content: content, trigger: trigger)

        // add our notification request
        UNUserNotificationCenter.current().add(request)
        
        
        
    }
    
    
    
    public func createApiTokenExpiryNotification(daysLeft: String){
        
        let content = UNMutableNotificationContent()
        content.title = "Feed the cat"
        content.subtitle = "It looks hungry"
        content.sound = UNNotificationSound.default

        // show this notification five seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

        // choose a random identifier
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        // add our notification request
        UNUserNotificationCenter.current().add(request)
        
        
        
    }       
    public func createSubscriptionExpiryNotification(createSubscriptionExpiryNotification: String){
        
        let content = UNMutableNotificationContent()
        content.title = "Feed the cat"
        content.subtitle = "It looks hungry"
        content.sound = UNNotificationSound.default

        // show this notification five seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

        // choose a random identifier
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        // add our notification request
        UNUserNotificationCenter.current().add(request)
        
        
        
    }   
    public func createDomainErrorNotification(count: Int){
        
        let content = UNMutableNotificationContent()
        content.title = "Feed the cat"
        content.subtitle = "It looks hungry"
        content.sound = UNNotificationSound.default

        // show this notification five seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

        // choose a random identifier
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        // add our notification request
        UNUserNotificationCenter.current().add(request)
        
        
        
    }
    
    public func createFailedDeliveryNotification(difference: Int){
        
        let content = UNMutableNotificationContent()
        content.title = "Feed the cat"
        content.subtitle = "It looks hungry"
        content.sound = UNNotificationSound.default

        // show this notification five seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

        // choose a random identifier
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        // add our notification request
        UNUserNotificationCenter.current().add(request)
        
        
        
    }
}
