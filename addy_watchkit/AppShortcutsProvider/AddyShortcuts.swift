//
//  AddyShortcuts.swift
//  addy
//
//  Created by Stijn van de Water on 07/02/2026.
//


import AppIntents

struct AddyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartTaskIntent(),
            phrases: [
                "Add a new alias in \(.applicationName)",
                "Add an alias in \(.applicationName)",
                "Create a new alias in \(.applicationName)",
                "Create an alias in \(.applicationName)",
                "Generate a new alias in \(.applicationName)",
                "Create a new alias in \(.applicationName)",
            ],
            shortTitle: "app_intent_add_alias",
            systemImageName: "plus.circle.fill"
        )
    }
}
