//
//  AddyShortcuts.swift
//  addy
//
//  Created by Stijn van de Water on 13/07/2024.
//

import Foundation
import AppIntents


struct AddyShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .purple
    
    static var appShortcuts: [AppShortcut] {
        

        AppShortcut(intent: CreateNewAliasIntent(),
                    phrases: [
                       "Add a new alias in \(.applicationName)",
                       "Add an alias in \(.applicationName)",
                    "Create a new alias in \(.applicationName)",
                    "Create an alias in \(.applicationName)",
                    "Generate a new alias in \(.applicationName)",
                       "Create a new alias in \(.applicationName)",
                    ],
                    shortTitle: "app_intent_add_alias",
                    systemImageName: "plus")
    }
    
}
