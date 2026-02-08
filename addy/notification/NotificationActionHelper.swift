//
//  NotificationActionHelper.swift
//  addy
//
//  Created by Stijn van de Water on 15/06/2024.
//

import addy_shared
import UserNotifications

enum notificationActions {
    static let openApp = "openApp"
    static let openSettings = "openSettings"
    static let openAlias = "openAlias"
    static let disableAlias = "disableAlias"
    static let stopWatching = "stopWatching"
    static let stopUpdateCheck = "stopUpdateCheck"
    static let openFailedDeliveries = "openFailedDeliveries"
    static let openAccountNotifications = "openAccountNotifications"
    static let stopFailedDeliveriesCheck = "stopFailedDeliveryCheck"
    static let stopAccountNotificationsCheck = "stopAccountNotificationsCheck"
    static let stopApiExpiryCheck = "stopApiExpiryCheck"
    static let openApiExpirationWarning = "openApiExpirationWarning"
    static let openSubscriptionExpirationWarning = "openSubscriptionExpirationWarning"
    static let stopDomainErrorCheck = "stopDomainErrorCheck"
    static let openDomains = "openDomains"
    static let stopSubscriptionExpiryCheck = "stopSubscriptionExpiryCheck"

    // static let STOP_PERIODIC_BACKUPS = "stop_periodic_backups"
}

class NotificationActionHelper {
    func handleNotificationActions(response: UNNotificationResponse) {
        // Notification button actions
        switch response.actionIdentifier {
        case notificationActions.stopUpdateCheck: SettingsManager(encrypted: false).putSettingsBool(key: .notifyUpdates, boolean: false)
        case notificationActions.stopDomainErrorCheck: SettingsManager(encrypted: false).putSettingsBool(key: .notifyDomainError, boolean: false)
        case notificationActions.stopFailedDeliveriesCheck: SettingsManager(encrypted: false).putSettingsBool(key: .notifyFailedDeliveries, boolean: false)
        case notificationActions.stopAccountNotificationsCheck: SettingsManager(encrypted: false).putSettingsBool(key: .notifyAccountNotifications, boolean: false)
        case notificationActions.stopSubscriptionExpiryCheck: SettingsManager(encrypted: false).putSettingsBool(key: .notifySubscriptionExpiry, boolean: false)
        case notificationActions.stopApiExpiryCheck: SettingsManager(encrypted: false).putSettingsBool(key: .notifyApiTokenExpiry, boolean: false)
        case notificationActions.disableAlias:
            if let aliasId = response.notification.request.content.userInfo["aliasId"] as? String {
                MainViewState.shared.aliasToDisable = aliasId
                MainViewState.shared.selectedTab = .aliases
            }
        case notificationActions.stopWatching:
            if let aliasId = response.notification.request.content.userInfo["aliasId"] as? String {
                AliasWatcher().removeAliasToWatch(alias: aliasId)
            }
        default:
            // Notification tap actions
            switch response.notification.request.identifier {
            // It's hard to determine if we open this notification in regular or compact mode.
            // iPad does not mean it cannot run in compact mode (split screen)
            // Hence we always open in sheets.
            case notificationActions.openSettings:
                MainViewState.shared.isPresentingProfileBottomSheet = true
                MainViewState.shared.profileBottomSheetAction = .settings
            case notificationActions.openDomains:
                MainViewState.shared.isPresentingProfileBottomSheet = true
                MainViewState.shared.profileBottomSheetAction = .domains
            case notificationActions.openFailedDeliveries: MainViewState.shared.isPresentingFailedDeliveriesSheet = true
            case notificationActions.openAccountNotifications: MainViewState.shared.isPresentingAccountNotificationsSheet = true
            case notificationActions.openApiExpirationWarning: MainViewState.shared.showApiExpirationWarning = true
            case notificationActions.openSubscriptionExpirationWarning: MainViewState.shared.showSubscriptionExpirationWarning = true
            case notificationActions.openAlias:
                if let aliasId = response.notification.request.content.userInfo["aliasId"] as? String {
                    MainViewState.shared.showAliasWithId = aliasId
                    MainViewState.shared.selectedTab = .aliases
                }
            default:
                break
            }
        }
    }
}
