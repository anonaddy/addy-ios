//
//  UsernamesViewModel.swift
//  addy
//
//  Created by Stijn van de Water on 01/06/2024.
//

import addy_shared
import SwiftUI

/// Marked as @MainActor to resolve "Capture of 'self' with non-Sendable type" warnings
/// and handle all @Published updates safely on the main thread.
@MainActor
class UsernamesViewModel: ObservableObject {
    @Published var usernames: UsernamesArray? = nil
    @Published var isLoading = false
    @Published var networkError: String = ""

    private let usernameRepository: UsernameRepositoryProtocol
    private let userRepository: UserRepositoryProtocol

    init(
        usernameRepository: UsernameRepositoryProtocol = UsernameRepository.shared,
        userRepository: UserRepositoryProtocol = UserRepository.shared
    ) {
        self.usernameRepository = usernameRepository
        self.userRepository = userRepository
        Task {
            await self.getUsernames()
        }
    }

    func getUsernames() async {
        if !isLoading {
            isLoading = true
            networkError = ""

            do {
                let usernames = try await usernameRepository.getUsernames()
                isLoading = false
                self.usernames = usernames
            } catch {
                isLoading = false
                guard !Task.isCancelled, !(error is CancellationError), (error as? URLError)?.code != .cancelled else { return }
                networkError = String(format: String(localized: "details_about_error_s", bundle: Bundle(for: SharedData.self)), "\(error.localizedDescription)")

                LoggingHelper().addLog(
                    importance: LogImportance.critical,
                    error: error.localizedDescription,
                    method: "getUsernames",
                    extra: nil
                )
            }
        }
    }

    func deleteUsername(usernameId: String) async throws -> String {
        return try await usernameRepository.deleteUsername(usernameId: usernameId)
    }

    func getUserResource() async throws -> UserResource {
        return try await userRepository.getUserResource()
    }
}
