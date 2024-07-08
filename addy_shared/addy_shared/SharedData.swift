//
//  SharedData.swift
//  addy_shared
//
//  Created by Stijn van de Water on 07/05/2024.
//

import Foundation

public class SharedData {
    static let shared = SharedData()
        
    private init() {
        
        // Get the bundle for the app
        let bundle = Bundle.main

        // Get the app's bundle identifier
        let userAgentApplicationID = bundle.bundleIdentifier ?? "UNKNOWN"

        // Get the app version
        let userAgentVersion = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "UNKNOWN"

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
    
    
    var userAgent: UserAgent
    
}
