//
//  RecipientsViewModel.swift
//  addy
//
//  Created by Stijn van de Water on 09/05/2024.
//

import addy_shared
import Combine
import SwiftUI

// Marked as @MainActor to resolve "Capture of 'self' with non-Sendable type" warnings
// and handle all @Published updates safely on the main thread.
@MainActor
class RecipientsViewModel: ObservableObject {
    @Published var recipients: [Recipients]? = nil

    @Published var verifiedOnly = false
    @Published var isLoading = false
    @Published var networkError: String = ""

    init() {
        Task {
            await self.getRecipients()
        }
    }

    func getRecipients() async {
        if !isLoading {
            self.isLoading = true
            self.networkError = ""
            
            let networkHelper = NetworkHelper()
            do {
                let recipients = try await networkHelper.getRecipients(verifiedOnly: verifiedOnly)
                self.isLoading = false
                self.recipients = recipients
            } catch {
                self.isLoading = false
                self.networkError = String(format: String(localized: "details_about_error_s", bundle: Bundle(for: SharedData.self)), "\(error.localizedDescription)")
                
                LoggingHelper().addLog(
                    importance: LogImportance.critical,
                    error: error.localizedDescription,
                    method: "getRecipients",
                    extra: nil
                )
            }
        }
    }
}
