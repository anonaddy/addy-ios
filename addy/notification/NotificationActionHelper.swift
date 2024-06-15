//
//  NotificationActionHelper.swift
//  addy
//
//  Created by Stijn van de Water on 15/06/2024.
//

import UserNotifications
import addy_shared

class NotificationActionHelper {
    
    public func handleNotificationActions(response: UNNotificationResponse){
        switch response.actionIdentifier {
        case notificationActions.openSettings: MainViewState.shared.isShowingAppSettingsView = true
            break
        case notificationActions.stopUpdateCheck: SettingsManager(encrypted: false).putSettingsBool(key: .notifyUpdates, boolean: false)
            break
        case notificationActions.disableAlias:
            if let aliasId = response.notification.request.content.userInfo["aliasId"] as? String {
                MainViewState.shared.aliasToDisable = aliasId
            }
            break
        case notificationActions.openAlias:
            if let aliasId = response.notification.request.content.userInfo["aliasId"] as? String {
                MainViewState.shared.showAliasWithId = aliasId
            }
            break
        case notificationActions.stopWatching:
            if let aliasId = response.notification.request.content.userInfo["aliasId"] as? String {
                AliasWatcher().removeAliasToWatch(alias: aliasId)
            }
            break
        default:
            break
        }
        
    }
}
