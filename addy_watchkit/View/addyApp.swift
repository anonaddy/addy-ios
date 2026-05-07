//
//  addyApp.swift
//  addy
//
//  Created by Stijn van de Water on 01/02/2026.
//

//
//  addyApp.swift
//  addy
//
//  Created by Stijn van de Water on 06/05/2024.
//

import addy_shared
import SwiftData
import SwiftUI

@main
struct addyApp: App {
    @StateObject private var appState = AppState.shared
    @StateObject private var mainViewState = MainViewState.shared

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if appState.apiKey != nil {
                    AliasesView()
                        .environmentObject(mainViewState)
                        .environmentObject(appState)
                } else {
                    SetupView()
                        .environmentObject(appState)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: appState.apiKey)
        }
    }
}
