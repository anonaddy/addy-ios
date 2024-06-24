//
//  NotificationHelper.swift
//  addy_shared
//
//  Created by Stijn van de Water on 12/05/2024.
//

import Foundation
import UserNotifications
import addy_shared


class NotificationHelper{


    
    public func createAliasWatcherNotification(emailDifference: Int, id: String, email: String){
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification_new_emails")
        
        if SettingsManager(encrypted: true).getSettingsBool(key: .privacyMode, default: false){
            content.subtitle = String(format: String(localized: "notification_new_emails_desc"), String(emailDifference), String(localized: "one_of_your_aliases"))
        } else {
            content.subtitle = String(format: String(localized: "notification_new_emails_desc"), String(emailDifference), email)
        }
        
        
        content.sound = .default

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
        content.title = String(localized: "notification_alias_watches_alias_does_not_exist_anymore")
        
        
        if SettingsManager(encrypted: true).getSettingsBool(key: .privacyMode, default: false){
            content.subtitle = String(format: String(localized: "notification_alias_watches_alias_does_not_exist_anymore_desc"), String(localized: "one_of_your_aliases"))
        } else {
            content.subtitle = String(format: String(localized: "notification_alias_watches_alias_does_not_exist_anymore_desc"), email)
        }

        content.sound = .default

        // show this notification five seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

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
        content.title = String(localized: "notification_api_token_about_to_expire")
        content.subtitle = String(format: String(localized: "notification_api_token_about_to_expire_desc"), daysLeft)
        content.sound = .default
        
        let action1 = UNNotificationAction(identifier: notificationActions.stopApiExpiryCheck, title: String(localized: "disable_notifications"), options: [])
        let category = UNNotificationCategory(identifier: notificationActions.openApiExpirationWarning, actions: [action1], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = notificationActions.openApiExpirationWarning


        // show this notification five seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        // choose a random identifier
        let request = UNNotificationRequest(identifier: notificationActions.openApiExpirationWarning, content: content, trigger: trigger)

        // add our notification request
        UNUserNotificationCenter.current().add(request)
        
        
        
    }       
    public func createSubscriptionExpiryNotification(daysLeft: String){
        
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification_subscription_about_to_expire")
        content.subtitle = String(format: String(localized: "notification_subscription_about_to_expire_desc"), daysLeft)
        content.sound = .default
        
        let action1 = UNNotificationAction(identifier: notificationActions.stopSubscriptionExpiryCheck, title: String(localized: "disable_notifications"), options: [])
        let category = UNNotificationCategory(identifier: notificationActions.openSubscriptionExpirationWarning, actions: [action1], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = notificationActions.openSubscriptionExpirationWarning


        // show this notification five seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        // choose a random identifier
        let request = UNNotificationRequest(identifier: notificationActions.openSubscriptionExpirationWarning, content: content, trigger: trigger)

        // add our notification request
        UNUserNotificationCenter.current().add(request)
        
        
        
    }   
    public func createDomainErrorNotification(count: Int){
        
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification_domain_error")
        content.subtitle = String(format: String(localized: "notification_domain_error_desc"), count)
        content.sound = .default

        let action1 = UNNotificationAction(identifier: notificationActions.stopDomainErrorCheck, title: String(localized: "disable_notifications"), options: [])
        let category = UNNotificationCategory(identifier: notificationActions.openDomains, actions: [action1], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = notificationActions.openDomains


        // show this notification five seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        // choose a random identifier
        let request = UNNotificationRequest(identifier: notificationActions.openDomains, content: content, trigger: trigger)

        // add our notification request
        UNUserNotificationCenter.current().add(request)
        
    }
    
    public func createFailedDeliveryNotification(difference: Int){

        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification_new_failed_delivery")
        content.subtitle = String(format: String(localized: "notification_new_failed_delivery_desc"), String(difference))
        content.sound = .default

        let action1 = UNNotificationAction(identifier: notificationActions.stopFailedDeliveriesCheck, title: String(localized: "stop_checking"), options: [])
        let category = UNNotificationCategory(identifier: notificationActions.openFailedDeliveries, actions: [action1], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = notificationActions.openFailedDeliveries


        // show this notification five seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        // choose a random identifier
        let request = UNNotificationRequest(identifier: notificationActions.openFailedDeliveries, content: content, trigger: trigger)

        // add our notification request
        UNUserNotificationCenter.current().add(request)
        
    }
}
