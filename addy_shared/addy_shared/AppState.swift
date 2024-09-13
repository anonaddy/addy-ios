//
//  AppState.swift
//  addy_shared
//
//  Created by Stijn van de Water on 24/06/2024.
//

import Foundation


public class AppState: ObservableObject {
    public static let shared = AppState() // Shared instance
    @Published public var apiKey: String? = SettingsManager(encrypted: true).getSettingsString(key: .apiKey)
}
