//
//  SharedNotificationHelper.swift
//  addy_shared
//
//  Created by Stijn van de Water on 26/06/2024.
//

import Foundation
import UserNotifications

class SharedNotificationHelper {
    
    static func createAppResetDueToInvalidAPIKeyNotification(){
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notification_app_reset", bundle: Bundle(for: SharedNotificationHelper.self), comment: "")
        content.subtitle = NSLocalizedString("notification_app_reset_desc", bundle: Bundle(for: SharedNotificationHelper.self), comment: "")
        content.sound = .default
        
        // show this notification five seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // choose a random identifier
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        // add our notification request
        UNUserNotificationCenter.current().add(request)
    }
    
}
