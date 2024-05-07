//
//  SharedData.swift
//  addy_shared
//
//  Created by Stijn van de Water on 07/05/2024.
//

import Foundation

class SharedData {
    static let shared = SharedData()
    
    private var encryptedSettingsManager: SettingsManager?
    
    private init() {
        self.encryptedSettingsManager = SettingsManager(encrypted: true)
        
        
        // Get the bundle for the app
        let bundle = Bundle.main

        // Get the app's bundle identifier
        let userAgentApplicationID = bundle.bundleIdentifier ?? "Unknown"

        // Get the app version
        let userAgentVersion = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"

        // Get the app build number (similar to versionCode in Android)
        let userAgentVersionCode = Int(bundle.infoDictionary?["CFBundleVersion"] as? String ?? "0") ?? 0

        #if DEBUG
        // Set the build type. In iOS, you might need to set this manually.
        let userAgentApplicationBuildType = "Debug" // or "Release"
        #else
        // Set the build type. In iOS, you might need to set this manually.
        let userAgentApplicationBuildType = "Release" // or "Release"
        #endif
        // Initialize the UserAgent
        self.userAgent = UserAgent(userAgentApplicationID: userAgentApplicationID,
                              userAgentVersion: userAgentVersion,
                              userAgentVersionCode: userAgentVersionCode,
                              userAgentApplicationBuildType: userAgentApplicationBuildType)
    }
    
    
    public var userAgent: UserAgent

    
    public var userResource: UserResource? {
        get {
            if let jsonString = encryptedSettingsManager?.getSettingsString(key: .userResource),
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
                    encryptedSettingsManager?.putSettingsString(key: .userResource, string: jsonString)
                }
            }
        }
    }
    
    public var userResourceExtended: UserResourceExtended? {
        get {
            if let jsonString = encryptedSettingsManager?.getSettingsString(key: .userResourceExtended),
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
                    encryptedSettingsManager?.putSettingsString(key: .userResourceExtended, string: jsonString)
                }
            }
        }
    }
    
    
    
}
