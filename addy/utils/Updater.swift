//
//  Updater.swift
//  addy
//
//  Created by Stijn van de Water on 12/06/2024.
//

import addy_shared
import Foundation

public struct UpdateCheckResult {
    public let isUpdateAvailable: Bool
    public let latestVersion: String?
    public let isAppAhead: Bool
    public let error: String?

    public init(isUpdateAvailable: Bool, latestVersion: String?, isAppAhead: Bool, error: String?) {
        self.isUpdateAvailable = isUpdateAvailable
        self.latestVersion = latestVersion
        self.isAppAhead = isAppAhead
        self.error = error
    }
}

class Updater {
    func isUpdateAvailable() async throws -> UpdateCheckResult {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

        do {
            let feed = try await AppMaintenanceRepository.shared.getGithubTags()
            if let version = feed?.entries?.first?.title {
                let comparison = compareVersions(version, appVersion)
                let isUpdateAvailable = comparison == .orderedDescending
                let isAppAhead = comparison == .orderedAscending
                return UpdateCheckResult(isUpdateAvailable: isUpdateAvailable, latestVersion: version, isAppAhead: isAppAhead, error: nil)
            } else {
                return UpdateCheckResult(isUpdateAvailable: false, latestVersion: nil, isAppAhead: false, error: nil)
            }
        } catch {
            return UpdateCheckResult(isUpdateAvailable: false, latestVersion: nil, isAppAhead: false, error: error.localizedDescription)
        }
    }

    private func compareVersions(_ v1: String, _ v2: String) -> ComparisonResult {
        let cleanV1 = v1.trimmingCharacters(in: CharacterSet(charactersIn: "vV "))
        let cleanV2 = v2.trimmingCharacters(in: CharacterSet(charactersIn: "vV "))
        return cleanV1.compare(cleanV2, options: .numeric)
    }
}
