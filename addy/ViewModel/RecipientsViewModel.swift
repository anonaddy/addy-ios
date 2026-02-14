//
//  RecipientsViewModel.swift
//  addy
//
//  Created by Stijn van de Water on 09/05/2024.
//

import addy_shared
import Combine
import SwiftUI

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
            DispatchQueue.main.async {
                self.isLoading = true
                self.networkError = ""
            }
            let networkHelper = NetworkHelper()
            do {
                let recipients = try await networkHelper.getRecipients(verifiedOnly: verifiedOnly)
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.recipients = recipients
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.networkError = String(format: String(localized: "details_about_error_s", bundle: Bundle(for: SharedData.self)), "\(error.localizedDescription)")
                }
                LoggingHelper().addLog(
                    importance: LogImportance.critical,
                    error: error.localizedDescription,
                    method: "getRecipients", extra: nil
                )
            }
        }
    }
}
