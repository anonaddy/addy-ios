//
//  NotificationHelper.swift
//  addy_shared
//
//  Created by Stijn van de Water on 12/05/2024.
//

import addy_shared
import Foundation
import UIKit
import UserNotifications

class NotificationHelper {
    func createAliasWatcherNotification(emailDifference: Int, id: String, email: String) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification_new_emails")

        if SettingsManager(encrypted: true).getSettingsBool(key: .privacyMode) {
            content.subtitle = String(format: String(localized: "notification_new_emails_desc"), String(emailDifference), String(localized: "one_of_your_aliases"))
        } else {
            content.subtitle = String(format: String(localized: "notification_new_emails_desc"), String(emailDifference), email)
        }

        content.sound = .default
        content.userInfo = ["aliasId": id]

        let action1 = UNNotificationAction(identifier: NotificationActions.disableAlias, title: String(localized: "deactivate_alias"), options: [.foreground])
        let action2 = UNNotificationAction(identifier: NotificationActions.stopWatching, title: String(localized: "stop_watching"), options: [])
        let category = UNNotificationCategory(identifier: NotificationActions.openAlias, actions: [action1, action2], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = NotificationActions.openAlias

        // show this notification five seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        // choose a random identifier
        let request = UNNotificationRequest(identifier: NotificationActions.openAlias, content: content, trigger: trigger)

        // add our notification request
        UNUserNotificationCenter.current().add(request)
        UNUserNotificationCenter.current().setBadgeCount(UIApplication.shared.applicationIconBadgeNumber + 1)
    }

    func createOpenAliasFromWatchkitNotification(id: String, email: String) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification_open_alias_from_watchkit")

        if SettingsManager(encrypted: true).getSettingsBool(key: .privacyMode) {
            content.subtitle = String(format: String(localized: "notification_open_alias_from_watchkit_desc"), String(localized: "one_of_your_aliases"))
        } else {
            content.subtitle = String(format: String(localized: "notification_open_alias_from_watchkit_desc"), email)
        }

        content.sound = .default
        content.userInfo = ["aliasId": id]

        content.categoryIdentifier = NotificationActions.openAlias

        // show this notification five seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        // choose a random identifier
        let request = UNNotificationRequest(identifier: NotificationActions.openAlias, content: content, trigger: trigger)

        // add our notification request
        UNUserNotificationCenter.current().add(request)
    }

    func createSetupWatchkitNotification(watchName: String) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "setup_wearable_app")
        content.subtitle = String(format: String(localized: "notification_setup_wearable_app_desc"), watchName)
        content.sound = .default
        content.categoryIdentifier = NotificationActions.openApp

        // show this notification five seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        // choose a random identifier
        let request = UNNotificationRequest(identifier: NotificationActions.openApp, content: content, trigger: trigger)

        // add our notification request
        UNUserNotificationCenter.current().add(request)
    }

    func createSetupAppFirstWatchkitNotification() {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification_setup_app_first")
        content.subtitle = String(localized: "notification_setup_app_first_desc")
        content.sound = .default

        // show this notification five seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        // choose a random identifier
        let request = UNNotificationRequest(identifier: NotificationActions.openApp, content: content, trigger: trigger)

        // add our notification request
        UNUserNotificationCenter.current().add(request)
    }

    func createOpenLogsFromWatchkitNotification() {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification_open_logs_from_watchkit")
        content.subtitle = String(localized: "notification_open_logs_from_watchkit_desc")
        content.sound = .default
        content.categoryIdentifier = NotificationActions.openSettings

        // show this notification five seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        // choose a random identifier
        let request = UNNotificationRequest(identifier: NotificationActions.openSettings, content: content, trigger: trigger)

        // add our notification request
        UNUserNotificationCenter.current().add(request)
    }

    func createAliasWatcherAliasDoesNotExistAnymoreNotification(email: String) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification_alias_watches_alias_does_not_exist_anymore")

        if SettingsManager(encrypted: true).getSettingsBool(key: .privacyMode) {
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
        UNUserNotificationCenter.current().setBadgeCount(UIApplication.shared.applicationIconBadgeNumber + 1)
    }

    func createUpdateNotification(version: String) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "new_update_available")
        content.subtitle = String(format: String(localized: "notification_new_update_available_desc"), version)
        content.sound = nil

        let action1 = UNNotificationAction(identifier: NotificationActions.stopUpdateCheck, title: String(localized: "stop_checking"), options: [])
        let category = UNNotificationCategory(identifier: NotificationActions.openSettings, actions: [action1], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = NotificationActions.openSettings

        // show this notification five seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        // choose a random identifier
        let request = UNNotificationRequest(identifier: NotificationActions.openSettings, content: content, trigger: trigger)

        // add our notification request
        UNUserNotificationCenter.current().add(request)
        UNUserNotificationCenter.current().setBadgeCount(UIApplication.shared.applicationIconBadgeNumber + 1)
    }

    func createApiTokenExpiryNotification(daysLeft: String) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification_api_token_about_to_expire")
        content.subtitle = String(format: String(localized: "notification_api_token_about_to_expire_desc"), daysLeft)
        content.sound = .default

        let action1 = UNNotificationAction(identifier: NotificationActions.stopApiExpiryCheck, title: String(localized: "disable_notifications"), options: [])
        let category = UNNotificationCategory(identifier: NotificationActions.openApiExpirationWarning, actions: [action1], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = NotificationActions.openApiExpirationWarning

        // show this notification five seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        // choose a random identifier
        let request = UNNotificationRequest(identifier: NotificationActions.openApiExpirationWarning, content: content, trigger: trigger)

        // add our notification request
        UNUserNotificationCenter.current().add(request)
        UNUserNotificationCenter.current().setBadgeCount(UIApplication.shared.applicationIconBadgeNumber + 1)
    }

    func createSubscriptionExpiryNotification(daysLeft: String) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification_subscription_about_to_expire")
        content.subtitle = String(format: String(localized: "notification_subscription_about_to_expire_desc"), daysLeft)
        content.sound = .default

        let action1 = UNNotificationAction(identifier: NotificationActions.stopSubscriptionExpiryCheck, title: String(localized: "disable_notifications"), options: [])
        let category = UNNotificationCategory(identifier: NotificationActions.openSubscriptionExpirationWarning, actions: [action1], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = NotificationActions.openSubscriptionExpirationWarning

        // show this notification five seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        // choose a random identifier
        let request = UNNotificationRequest(identifier: NotificationActions.openSubscriptionExpirationWarning, content: content, trigger: trigger)

        // add our notification request
        UNUserNotificationCenter.current().add(request)
        UNUserNotificationCenter.current().setBadgeCount(UIApplication.shared.applicationIconBadgeNumber + 1)
    }

    func createDomainErrorNotification(count: Int) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification_domain_error")
        content.subtitle = String(format: String(localized: "notification_domain_error_desc"), count)
        content.sound = .default

        let action1 = UNNotificationAction(identifier: NotificationActions.stopDomainErrorCheck, title: String(localized: "disable_notifications"), options: [])
        let category = UNNotificationCategory(identifier: NotificationActions.openDomains, actions: [action1], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = NotificationActions.openDomains

        // show this notification five seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        // choose a random identifier
        let request = UNNotificationRequest(identifier: NotificationActions.openDomains, content: content, trigger: trigger)

        // add our notification request
        UNUserNotificationCenter.current().add(request)
        UNUserNotificationCenter.current().setBadgeCount(UIApplication.shared.applicationIconBadgeNumber + 1)
    }

    func createFailedDeliveryNotification(difference: Int) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification_new_failed_delivery")
        content.subtitle = String(format: String(localized: "notification_new_failed_delivery_desc"), String(difference))
        content.sound = .default

        let action1 = UNNotificationAction(identifier: NotificationActions.stopFailedDeliveriesCheck, title: String(localized: "stop_checking"), options: [])
        let category = UNNotificationCategory(identifier: NotificationActions.openFailedDeliveries, actions: [action1], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = NotificationActions.openFailedDeliveries

        // show this notification five seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        // choose a random identifier
        let request = UNNotificationRequest(identifier: NotificationActions.openFailedDeliveries, content: content, trigger: trigger)

        // add our notification request
        UNUserNotificationCenter.current().add(request)
        UNUserNotificationCenter.current().setBadgeCount(UIApplication.shared.applicationIconBadgeNumber + 1)
    }

    func createAccountNotification(difference: Int) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification_new_account_notifications")
        content.subtitle = String(format: String(localized: "notification_new_account_notifications_desc"), String(difference))
        content.sound = .default

        let action1 = UNNotificationAction(identifier: NotificationActions.stopAccountNotificationsCheck, title: String(localized: "stop_checking"), options: [])
        let category = UNNotificationCategory(identifier: NotificationActions.openAccountNotifications, actions: [action1], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = NotificationActions.openAccountNotifications

        // show this notification five seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        // choose a random identifier
        let request = UNNotificationRequest(identifier: NotificationActions.openAccountNotifications, content: content, trigger: trigger)

        // add our notification request
        UNUserNotificationCenter.current().add(request)
        UNUserNotificationCenter.current().setBadgeCount(UIApplication.shared.applicationIconBadgeNumber + 1)
    }
}
