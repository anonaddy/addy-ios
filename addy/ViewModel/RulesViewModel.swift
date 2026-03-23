//
//  RulesViewModel.swift
//  addy
//
//  Created by Stijn van de Water on 01/06/2024.
//

import addy_shared
import Combine
import SwiftUI

// Marked as @MainActor to resolve "Capture of 'self' with non-Sendable type" warnings
// and handle all @Published updates safely on the main thread.
@MainActor
class RulesViewModel: ObservableObject {
    @Published var rules: RulesArray? = nil
    @Published var recipients: [Recipients] = []

    @Published var isLoading = false
    @Published var networkError: String = ""

    init() {
        Task {
            await self.getRules()
        }
    }

    func getRules() async {
        if !isLoading {
            self.isLoading = true
            self.networkError = ""
            
            let networkHelper = NetworkHelper()
            do {
                // Sequential async calls: Recipients must succeed before fetching rules
                if let recipients = try await networkHelper.getRecipients(verifiedOnly: false) {
                    let rules = try await networkHelper.getRules()
                    
                    self.isLoading = false
                    self.rules = rules
                    self.recipients = recipients
                }
            } catch {
                self.isLoading = false
                self.networkError = String(format: String(localized: "details_about_error_s", bundle: Bundle(for: SharedData.self)), "\(error.localizedDescription)")
                
                LoggingHelper().addLog(
                    importance: LogImportance.critical,
                    error: error.localizedDescription,
                    method: "getRules",
                    extra: nil
                )
            }
        }
    }
}
