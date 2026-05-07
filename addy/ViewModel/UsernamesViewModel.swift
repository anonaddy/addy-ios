//
//  UsernamesViewModel.swift
//  addy
//
//  Created by Stijn van de Water on 01/06/2024.
//

import addy_shared
import Combine
import SwiftUI

/// Marked as @MainActor to resolve "Capture of 'self' with non-Sendable type" warnings
/// and handle all @Published updates safely on the main thread.
@MainActor
class UsernamesViewModel: ObservableObject {
    @Published var usernames: UsernamesArray? = nil

    @Published var isLoading = false
    @Published var networkError: String = ""

    init() {
        Task {
            await self.getUsernames()
        }
    }

    func getUsernames() async {
        if !isLoading {
            isLoading = true
            networkError = ""

            let networkHelper = NetworkHelper()
            do {
                let usernames = try await networkHelper.getUsernames()
                isLoading = false
                self.usernames = usernames
            } catch {
                isLoading = false
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
}
