//
//  RecipientsViewModel.swift
//  addy
//
//  Created by Stijn van de Water on 09/05/2024.
//

import addy_shared
import SwiftUI

/// Marked as @MainActor to resolve "Capture of 'self' with non-Sendable type" warnings
/// and handle all @Published updates safely on the main thread.
@MainActor
class RecipientsViewModel: ObservableObject {
    @Published var recipients: [Recipients]? = nil
    @Published var verifiedOnly = false
    @Published var isLoading = false
    @Published var networkError: String = ""

    private let recipientRepository: RecipientRepositoryProtocol

    init(recipientRepository: RecipientRepositoryProtocol = RecipientRepository.shared) {
        self.recipientRepository = recipientRepository
        Task {
            await self.getRecipients()
        }
    }

    func getRecipients() async {
        if !isLoading {
            isLoading = true
            networkError = ""

            do {
                let recipients = try await recipientRepository.getRecipients(verifiedOnly: verifiedOnly)
                isLoading = false
                self.recipients = recipients
            } catch {
                isLoading = false
                guard !Task.isCancelled, !(error is CancellationError), (error as? URLError)?.code != .cancelled else { return }
                networkError = String(format: String(localized: "details_about_error_s", bundle: Bundle(for: SharedData.self)), "\(error.localizedDescription)")

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
