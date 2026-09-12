//
//  RulesViewModel.swift
//  addy
//
//  Created by Stijn van de Water on 01/06/2024.
//

import addy_shared
import SwiftUI

/// Marked as @MainActor to resolve "Capture of 'self' with non-Sendable type" warnings
/// and handle all @Published updates safely on the main thread.
@MainActor
class RulesViewModel: ObservableObject {
    @Published var rules: RulesArray? = nil
    @Published var recipients: [Recipients] = []
    @Published var isLoading = false
    @Published var networkError: String = ""

    private let rulesRepository: RulesRepositoryProtocol
    private let recipientRepository: RecipientRepositoryProtocol
    private let userRepository: UserRepositoryProtocol

    init(
        rulesRepository: RulesRepositoryProtocol = RulesRepository.shared,
        recipientRepository: RecipientRepositoryProtocol = RecipientRepository.shared,
        userRepository: UserRepositoryProtocol = UserRepository.shared
    ) {
        self.rulesRepository = rulesRepository
        self.recipientRepository = recipientRepository
        self.userRepository = userRepository
        Task {
            await self.getRules()
        }
    }

    func getRules() async {
        if !isLoading {
            isLoading = true
            networkError = ""

            do {
                // Concurrent async calls
                async let fetchedRecipients = recipientRepository.getRecipients(verifiedOnly: false)
                async let fetchedRules = rulesRepository.getRules()
                let (recipients, rules) = try await (fetchedRecipients, fetchedRules)

                isLoading = false
                self.rules = rules
                self.recipients = recipients
            } catch {
                isLoading = false
                guard !Task.isCancelled, !(error is CancellationError), (error as? URLError)?.code != .cancelled else { return }
                networkError = String(format: String(localized: "details_about_error_s", bundle: Bundle(for: SharedData.self)), "\(error.localizedDescription)")

                LoggingHelper().addLog(
                    importance: LogImportance.critical,
                    error: error.localizedDescription,
                    method: "getRules",
                    extra: nil
                )
            }
        }
    }

    func deleteRule(ruleId: String) async throws -> String {
        return try await rulesRepository.deleteRule(ruleId: ruleId)
    }

    func reorderRules(rules: [Rules]) async throws -> String {
        return try await rulesRepository.reorderRules(rules: rules)
    }

    func activateRule(ruleId: String) async throws -> Rules {
        return try await rulesRepository.activateRule(ruleId: ruleId)
    }

    func deactivateRule(ruleId: String) async throws -> String {
        return try await rulesRepository.deactivateRule(ruleId: ruleId)
    }

    func getUserResource() async throws -> UserResource {
        return try await userRepository.getUserResource()
    }
}
