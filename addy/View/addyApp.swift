//
//  addyApp.swift
//  addy
//
//  Created by Stijn van de Water on 06/05/2024.
//

import SwiftUI
import SwiftData
import addy_shared


@main
struct addyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @StateObject private var appState = AppState.shared
    @StateObject private var mainViewState = MainViewState.shared // Needs to be shared so that notifications work
    @StateObject private var setupViewState = SetupViewState.shared // Needs to be shared so that notifications work
    var body: some Scene {
        WindowGroup(for: UUID.self) { _ in
            
            Group {
                if appState.apiKey != nil {
                    MainView()
                        .environmentObject(mainViewState)
                        .transition(.asymmetric(insertion: AnyTransition.scale(scale: 1.1).combined(with: .opacity), removal: AnyTransition.opacity.animation(.easeInOut(duration: 0.5))))
                                    .animation(.easeInOut(duration: 0.5), value: appState.apiKey)
                                    .onOpenURL { url in
                                        // See appdelegate for handling this when app is closed
                                        if url.pathComponents.count > 2 && url.pathComponents[1] == "deactivate" {
                                            let id = url.pathComponents[2]
                                            mainViewState.aliasToDisable = id
                                            mainViewState.selectedTab = .aliases
                                        }
                                    }
                } else {
                    SetupView()
                        .environmentObject(appState)
                        .environmentObject(setupViewState)
                        .transition(.opacity)
                                    .animation(.easeInOut(duration: 0.5), value: appState.apiKey)
                                    .onOpenURL { url in
                                        // See appdelegate for handling this when app is closed
                                        if url.path.contains("/api/auth/verify") {
                                            setupViewState.verifyQuery = url.query()
                                        }
                                    }
                }
            }
            .transition(.asymmetric(insertion: AnyTransition.scale(scale: 1.1).combined(with: .opacity), removal: AnyTransition.opacity.animation(.easeInOut(duration: 0.5))))
            .animation(.easeInOut(duration: 0.5), value: appState.apiKey)
        }
    }
}
