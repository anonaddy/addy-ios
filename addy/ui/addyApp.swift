//
//  addyApp.swift
//  addy
//
//  Created by Stijn van de Water on 06/05/2024.
//

import SwiftUI
import SwiftData
import addy_shared

class AppState: ObservableObject {
    @Published var apiKey: String? = SettingsManager(encrypted: true).getSettingsString(key: .apiKey)
}

@main
struct addyApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            
            Group {      // or VStack
                if appState.apiKey != nil {
                    SplashView()
                        .environmentObject(appState)
                        .transition(.asymmetric(insertion: AnyTransition.scale(scale: 1.1).combined(with: .opacity), removal: AnyTransition.opacity.animation(.easeInOut(duration: 0.5))))
                                    .animation(.easeInOut(duration: 0.5), value: appState.apiKey)
                    
                } else {
                    SetupView()
                        .environmentObject(appState)
                        .transition(.opacity)
                                    .animation(.easeInOut(duration: 0.5), value: appState.apiKey)
                }
            }
            .transition(.asymmetric(insertion: AnyTransition.scale(scale: 1.1).combined(with: .opacity), removal: AnyTransition.opacity.animation(.easeInOut(duration: 0.5))))
            .animation(.easeInOut(duration: 0.5), value: appState.apiKey)
            
            //TODO make animation fancier
        }
    }
}
