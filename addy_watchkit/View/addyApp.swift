import addy_shared
import SwiftUI

@main
struct AddyApp: App {
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
