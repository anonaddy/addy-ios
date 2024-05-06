//
//  addyApp.swift
//  addy
//
//  Created by Stijn van de Water on 06/05/2024.
//

import SwiftUI
import SwiftData

@main
struct addyApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {

            if getAPIKey() != nil {
                SplashView()
            } else {
                SetupView()
            }
        }
        .modelContainer(sharedModelContainer)
    }
    
    func getAPIKey() -> String? {
        let key = SettingsManager.Prefs.apiKey
        
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: key,
                                    kSecReturnData as String: kCFBooleanTrue!,
                                    kSecMatchLimit as String: kSecMatchLimitOne]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            if let retrievedData = dataTypeRef as? Data,
               let retrievedValue = String(data: retrievedData, encoding: .utf8) {
                return retrievedValue
            }
        }
    
        return nil
    }
}
