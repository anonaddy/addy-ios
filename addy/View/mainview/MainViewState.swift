//
//  MainViewState.swift
//  addy
//
//  Created by Stijn van de Water on 20/07/2024.
//

import SwiftUI
import addy_shared



class MainViewState: ObservableObject {
    

    static let shared = MainViewState() // Shared instance
    
    // MARK: NOTIFICATION AND SHORTCUT ACTIONS
    @Published var aliasToDisable: String? = nil
    @Published var showAliasWithId: String? = nil
    // MARK: END NOTIFICATION AND SHORTCUT ACTIONS
    
    // MARK: SHORTCUT ACTIONS
    @Published var showAddAliasBottomSheet = false
    // MARK: END SHORTCUT ACTIONS
    
    // MARK: Share sheet AND MailTo tap action
    @Published var mailToActionSheetData: MailToActionSheetData? = nil
    // MARK: END Share sheet AND MailTo tap action

    
    @Published var isPresentingProfileBottomSheet = false
    @Published var profileBottomSheetAction: Destination? = nil
    @Published var isPresentingFailedDeliveriesSheet = false
    @Published var isPresentingSubscriptionSheet = false
    @Published var isPresentingAccountNotificationsSheet = false

    @Published var selectedTab: Destination = .home

    @Published var newFailedDeliveries : Int? = nil
    @Published var newAccountNotifications : Int = 0
    @Published var updateAvailable : Bool = false
    @Published var permissionsRequired : Bool = false
    @Published var backgroundAppRefreshDenied : Bool = false

    @Published var showApiExpirationWarning = false
    @Published var showSubscriptionExpirationWarning = false
    
    @Published var isUnlocked = false
    

    @Published var encryptedSettingsManager = SettingsManager(encrypted: true)
    @Published var settingsManager = SettingsManager(encrypted: false)
    
    @Published var userResourceData: String? {
        didSet {
            userResourceData.map { encryptedSettingsManager.putSettingsString(key: .userResource, string: $0) }
        }
    }
    
    var userResource: UserResource? {
        get {
            if let jsonString = userResourceData,
               let jsonData = jsonString.data(using: .utf8) {
                let decoder = JSONDecoder()
                return try? decoder.decode(UserResource.self, from: jsonData)
            }
            return nil
        }
        set {
            if let newValue = newValue {
                let encoder = JSONEncoder()
                if let jsonData = try? encoder.encode(newValue),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    userResourceData = jsonString
                }
            }
        }
    }
    
    
    @Published var userResourceExtendedData: String? {
        didSet {
            userResourceExtendedData.map { encryptedSettingsManager.putSettingsString(key: .userResourceExtended, string: $0) }
        }
    }
    
    var userResourceExtended: UserResourceExtended? {
        get {
            if let jsonString = userResourceExtendedData,
               let jsonData = jsonString.data(using: .utf8) {
                let decoder = JSONDecoder()
                return try? decoder.decode(UserResourceExtended.self, from: jsonData)
            }
            return nil
        }
        set {
            if let newValue = newValue {
                let encoder = JSONEncoder()
                if let jsonData = try? encoder.encode(newValue),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    userResourceExtendedData = jsonString
                }
            }
        }
    }
    
}
