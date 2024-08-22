//
//  AccountNotifications.swift
//  addy_shared
//
//  Created by Stijn van de Water on 22/08/2024.
//

import Foundation


public struct AccountNotificationsArray: Codable {
    let data: [AccountNotifications]
}

public struct AccountNotifications: Codable {
    let category: String
    let created_at: String
    let id: String
    let link: String
    let link_text: String
    let text: String
    let title: String
}
