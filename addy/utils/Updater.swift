//
//  Updater.swift
//  addy
//
//  Created by Stijn van de Water on 12/06/2024.
//

import Foundation
import addy_shared

class Updater {
    func isUpdateAvailable(callback: @escaping (Bool, String?, Bool) -> Void) {
        let appVersion = "v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")"

        
        let networkHelper = NetworkHelper()
        networkHelper.getGithubTags { feed, _ in
            if let version = feed?.entries?.first?.title {
                let serverVersionCodeAsInt = Int(version.replacingOccurrences(of: "v", with: "").replacingOccurrences(of: ".", with: ""))!
                let appVersionCodeAsInt = Int(appVersion.replacingOccurrences(of: "v", with: "").replacingOccurrences(of: ".", with: ""))!
                callback(serverVersionCodeAsInt > appVersionCodeAsInt, version, appVersionCodeAsInt > serverVersionCodeAsInt)
            } else {
                callback(false, nil, false)
            }
        }
    }
}
