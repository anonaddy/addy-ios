//
//  FavoriteAliasHelper.swift
//  addy
//
//  Created by Stijn van de Water on 05/02/2026.
//


import SwiftUI
import addy_shared
import Combine

class FavoriteAliasHelper: ObservableObject {
    
    private let settingsManager: SettingsManager = SettingsManager(encrypted: true)
    
    // Published property acts as the local cache for SwiftUI views
    @Published var favoriteAliases: Set<String> = []

    // Inject your existing SettingsManager instance
    init() {
        loadFavorites()
    }

    /// Reloads the set from SettingsManager into the @Published property
    private func loadFavorites() {
        if let savedSet = settingsManager.getStringSet(key: SettingsManager.Prefs.watchosFavoriteAliases) {
            self.favoriteAliases = savedSet
        } else {
            self.favoriteAliases = []
        }
    }

    /// Returns the current set (Direct mapping to Kotlin's getFavoriteAliases)
    func getFavoriteAliases() -> Set<String>? {
        return settingsManager.getStringSet(key: SettingsManager.Prefs.watchosFavoriteAliases)
    }

    /// Removes an alias and updates SettingsManager
    func removeAliasAsFavorite(_ alias: String) {
        if favoriteAliases.contains(alias) {
            favoriteAliases.remove(alias)
            settingsManager.putStringSet(key: SettingsManager.Prefs.watchosFavoriteAliases, mutableSet: favoriteAliases)
        }
    }

    /// Adds an alias if limit (< 3) is not reached. Returns true if successful.
    @discardableResult
    func addAliasAsFavorite(_ alias: String) -> Bool {
        if favoriteAliases.count < 3 {
            let (inserted, _) = favoriteAliases.insert(alias)
            // Only save if it was actually new
            if inserted {
                settingsManager.putStringSet(key: SettingsManager.Prefs.watchosFavoriteAliases, mutableSet: favoriteAliases)
                return true
            }
        }
        return false
    }

    /// Clears the setting completely
    func clearFavoriteAliases() {
        favoriteAliases.removeAll()
        settingsManager.removeSetting(key: SettingsManager.Prefs.watchosFavoriteAliases)
    }
}
