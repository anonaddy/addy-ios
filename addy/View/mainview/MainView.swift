//
//  MainView.swift
//  addy
//
//  Created by Stijn van de Water on 08/05/2024.
//

import SwiftUI
import addy_shared
import ScalingHeaderScrollView

class MainViewState: ObservableObject {
    @Published var apiKey: String? = SettingsManager(encrypted: true).getSettingsString(key: .apiKey)
    @Published var encryptedSettingsManager = SettingsManager(encrypted: true)
    
    @Published var userResourceData: String? {
        didSet {
            userResourceData.map { encryptedSettingsManager.putSettingsString(key: .userResource, string: $0) }
        }
    }
    
    var userResource: UserResource? {
        get {
            if let jsonString = userResourceData,
               let jsonData = jsonString.data(using: .utf8) {
                let decoder = JSONDecoder()
                return try? decoder.decode(UserResource.self, from: jsonData)
            }
            return nil
        }
        set {
            if let newValue = newValue {
                let encoder = JSONEncoder()
                if let jsonData = try? encoder.encode(newValue),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    userResourceData = jsonString
                }
            }
        }
    }
    
    
    @Published var userResourceExtendedData: String? {
        didSet {
            userResourceExtendedData.map { encryptedSettingsManager.putSettingsString(key: .userResourceExtended, string: $0) }
        }
    }
    
    var userResourceExtended: UserResourceExtended? {
        get {
            if let jsonString = userResourceExtendedData,
               let jsonData = jsonString.data(using: .utf8) {
                let decoder = JSONDecoder()
                return try? decoder.decode(UserResourceExtended.self, from: jsonData)
            }
            return nil
        }
        set {
            if let newValue = newValue {
                let encoder = JSONEncoder()
                if let jsonData = try? encoder.encode(newValue),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    userResourceExtendedData = jsonString
                }
            }
        }
    }

}


struct MainView: View {
    @StateObject private var mainViewState = MainViewState()
    @StateObject var aliasesData = AliasesViewModel()

    
    var body: some View {
        if (mainViewState.userResourceData == nil || mainViewState.userResourceExtendedData == nil){
            SplashView().environmentObject(mainViewState)
        } else {
            TabView {
                NavigationView {
                    HomeView()
//                        .navigationDestination(for: Aliases.self){
//                            alias in AliasDetailView(alias: alias)
//                        }
                        .navigationTitle(String(localized: "home"))
                        .environmentObject(mainViewState)
                        .toolbar(content: {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button(action: {
                                    print("Search button tapped")
                                }) {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundStyle(.white)
                                }
                            }
                        })
                }
                .tabItem {
                    Label(String(localized: "home"), systemImage: "house")
                }.tag(0)
                NavigationView {
                    AliasesView()
                        .environmentObject(mainViewState)
                        .environmentObject(aliasesData)
                }
                .tabItem {
                    Label(String(localized: "aliases"), systemImage: "at.circle")
                }.tag(1)
                NavigationView {
                    RecipientsView()
                        .navigationTitle(String(localized: "recipients"))
                        .environmentObject(mainViewState)
                }
                .tabItem {
                    Label(String(localized: "recipients"), systemImage: "person.2")
                }.tag(1)
            }

        }
        
    }

}




#Preview {
    MainView()
}
