//
//  NotificationActionHelper.swift
//  addy
//
//  Created by Stijn van de Water on 15/06/2024.
//

import UserNotifications
import addy_shared

public struct notificationActions {
    static let openSettings = "openSettings"
    static let openAlias = "openAlias"
    static let disableAlias = "disableAlias"
    static let stopWatching = "stopWatching"
    static let stopUpdateCheck = "stopUpdateCheck"
    static let openFailedDeliveries = "stopUpdateCheck"
    static let stopFailedDeliveriesCheck = "stopFailedDeliveryCheck"
    static let stopApiExpiryCheck = "stopApiExpiryCheck"
    static let openApiExpirationWarning = "openApiExpirationWarning"
    static let stopDomainErrorCheck = "stopDomainErrorCheck"
    static let openDomains = "openDomains"
    static let stopSubscriptionExpiryCheck = "stopSubscriptionExpiryCheck"
    
    static let STOP_PERIODIC_BACKUPS = "stop_periodic_backups"
}


class NotificationActionHelper {
    
    
    public func handleNotificationActions(response: UNNotificationResponse){
        
        // Notification button actions
        switch response.actionIdentifier {
        case notificationActions.stopUpdateCheck: SettingsManager(encrypted: false).putSettingsBool(key: .notifyUpdates, boolean: false)
            break
        case notificationActions.stopDomainErrorCheck: SettingsManager(encrypted: false).putSettingsBool(key: .notifyDomainError, boolean: false)
            break
        case notificationActions.stopFailedDeliveriesCheck: SettingsManager(encrypted: false).putSettingsBool(key: .notifyFailedDeliveries, boolean: false)
            break
        case notificationActions.stopSubscriptionExpiryCheck: SettingsManager(encrypted: false).putSettingsBool(key: .notifySubscriptionExpiry, boolean: false)
            break
        case notificationActions.stopApiExpiryCheck: SettingsManager(encrypted: false).putSettingsBool(key: .notifyApiTokenExpiry, boolean: false)
            break
        case notificationActions.disableAlias:
            if let aliasId = response.notification.request.content.userInfo["aliasId"] as? String {
                MainViewState.shared.aliasToDisable = aliasId
                MainViewState.shared.selectedTab = .aliases
            }
            break
        case notificationActions.stopWatching:
            if let aliasId = response.notification.request.content.userInfo["aliasId"] as? String {
                AliasWatcher().removeAliasToWatch(alias: aliasId)
            }
            break
        default:
            // Notification tap actions
            switch response.notification.request.identifier {
            case notificationActions.openSettings: MainViewState.shared.selectedTab = .settings
                break
            case notificationActions.openDomains: MainViewState.shared.selectedTab = .domains
                break
            case notificationActions.openFailedDeliveries: MainViewState.shared.selectedTab = .failedDeliveries
                break
            case notificationActions.openApiExpirationWarning: MainViewState.shared.showApiExpirationWarning = true
                break
            case notificationActions.openAlias:
                if let aliasId = response.notification.request.content.userInfo["aliasId"] as? String {
                    MainViewState.shared.showAliasWithId = aliasId
                    MainViewState.shared.selectedTab = .aliases
                }
                break
            default:
                break
            }
        }
        
    }
}
