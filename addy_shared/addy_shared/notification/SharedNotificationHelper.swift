//
//  SharedNotificationHelper.swift
//  addy_shared
//
//  Created by Stijn van de Water on 24/06/2024.
//

import Foundation

public struct SharedNotificationHelper {
    
    public static func createAppResetDueToInvalidAPIKeyNotification(){
        
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification_app_reset")
        content.subtitle = String(localized: "notification_app_reset_desc")
        content.sound = .default
        
        // show this notification five seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // choose a random identifier
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        // add our notification request
        UNUserNotificationCenter.current().add(request)
    }
}
