//
//  AddyShortcuts.swift
//  addy
//
//  Created by Stijn van de Water on 13/07/2024.
//

import AppIntents

struct AddyShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .purple

    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: CreateNewAliasIntent(),
                    phrases: [
                        "Add a new alias in \(.applicationName)",
                        "Add an alias in \(.applicationName)",
                        "Add alias in \(.applicationName)",
                        "Create a new alias in \(.applicationName)",
                        "Create an alias in \(.applicationName)",
                        "Create alias in \(.applicationName)",
                        "Generate a new alias in \(.applicationName)",
                    ],
                    shortTitle: "app_intent_add_alias",
                    systemImageName: "plus")

        AppShortcut(intent: FindAliasIntent(),
                    phrases: [
                        "Find an alias in \(.applicationName)",
                        "Find alias in \(.applicationName)",
                        "Search alias in \(.applicationName)",
                        "Search for an alias in \(.applicationName)",
                        "Look up an alias in \(.applicationName)",
                        "Get an alias in \(.applicationName)",
                    ],
                    shortTitle: "app_intent_find_alias",
                    systemImageName: "magnifyingglass")
    }
}
