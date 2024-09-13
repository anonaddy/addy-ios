//
//  Updater.swift
//  addy
//
//  Created by Stijn van de Water on 12/06/2024.
//

import Foundation
import addy_shared

class Updater {
    func isUpdateAvailable() async throws -> (Bool, String?, Bool, String?) {
        let appVersion = "v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")"
        
        let networkHelper = NetworkHelper()
        do {
            let feed = try await networkHelper.getGithubTags()
            if let version = feed?.entries?.first?.title {
                let serverVersionCodeAsInt = Int(version.replacingOccurrences(of: "v", with: "").replacingOccurrences(of: ".", with: ""))!
                let appVersionCodeAsInt = Int(appVersion.replacingOccurrences(of: "v", with: "").replacingOccurrences(of: ".", with: ""))!
                return (serverVersionCodeAsInt > appVersionCodeAsInt, version, appVersionCodeAsInt > serverVersionCodeAsInt, nil)
            } else {
                return (false, nil, false, nil)
            }
        } catch {
            return (false, nil, false, error.localizedDescription)
        }
    }

}
