//
//  HomeViewModel.swift
//  addy
//
//  Created by Stijn van de Water on 29/08/2026.
//

import addy_shared
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published var progress: Float = 0.7

    func updateProgress(userResource: UserResource?) {
        guard let userResource = userResource else {
            return
        }
        if (userResource.bandwidth_limit ?? 0) == 0 {
            progress = 1.0
        } else {
            progress = Float(Double(userResource.bandwidth) / Double(userResource.bandwidth_limit ?? 1))
        }
    }

    func bandwidthText(userResource: UserResource) -> String {
        if (userResource.bandwidth_limit ?? 0) == 0 {
            return String(format: String(localized: "home_bandwidth_text"), String(userResource.bandwidth / 1024 / 1024), "∞")
        } else {
            return String(format: String(localized: "home_bandwidth_text"), String(userResource.bandwidth / 1024 / 1024), String((userResource.bandwidth_limit ?? 0) / 1024 / 1024))
        }
    }
}
