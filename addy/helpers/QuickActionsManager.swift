//
//  QuickActionsManager.swift
//  addy
//
//  Created by Stijn van de Water on 24/06/2024.
//

import Foundation
import UIKit

class QuickActionsManager: ObservableObject {
    static let instance = QuickActionsManager()

    func handleQaItem(_ shortcutItem: UIApplicationShortcutItem) {
#if DEBUG
        print("SHORTCUT ITEM RECEIVED \(shortcutItem)")
#endif
        if shortcutItem.type == "host.stjin.addy.shortcut_add_alias" {
            MainViewState.shared.isPresentingFailedDeliveriesSheet = true
        } else if shortcutItem.type.starts(with: "host.stjin.addy.shortcut_open_alias_") {
            if let range = shortcutItem.type.range(of: "host.stjin.addy.shortcut_open_alias_") {
                let aliasId = shortcutItem.type[range.upperBound...]
                MainViewState.shared.showAliasWithId = String(aliasId)
                MainViewState.shared.selectedTab = .aliases
            }
            
        }
    }
    
}
