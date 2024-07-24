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
    
    var body: some Scene {
        WindowGroup {
            
            Group {
                if appState.apiKey != nil {
                    MainView()
                        .environmentObject(MainViewState.shared)
                        .transition(.asymmetric(insertion: AnyTransition.scale(scale: 1.1).combined(with: .opacity), removal: AnyTransition.opacity.animation(.easeInOut(duration: 0.5))))
                                    .animation(.easeInOut(duration: 0.5), value: appState.apiKey)
                                    .onOpenURL {url in
                                        
                                        if url.pathComponents.count > 2 && url.pathComponents[1] == "deactivate" {
                                            let id = url.pathComponents[2]
                                            MainViewState.shared.aliasToDisable = id
                                            MainViewState.shared.selectedTab = .aliases
                                        }
                                    }
                    
                } else {
                    SetupView()
                        .environmentObject(appState)
                        .transition(.opacity)
                                    .animation(.easeInOut(duration: 0.5), value: appState.apiKey)
                }
            }
            .transition(.asymmetric(insertion: AnyTransition.scale(scale: 1.1).combined(with: .opacity), removal: AnyTransition.opacity.animation(.easeInOut(duration: 0.5))))
            .animation(.easeInOut(duration: 0.5), value: appState.apiKey)
        }
    }
}
