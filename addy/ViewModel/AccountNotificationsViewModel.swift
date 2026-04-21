//
//  AccountNotificationsViewModel 2.swift
//  addy
//
//  Created by Stijn van de Water on 23/08/2024.
//

import addy_shared
import Combine
import SwiftUI

/// Marked as @MainActor to ensure all updates to @Published properties
/// and the Task lifecycle happen safely on the main thread.
@MainActor
class AccountNotificationsViewModel: ObservableObject {
    @Published var accountNotifications: AccountNotificationsArray? = nil

    @Published var isLoading = false
    @Published var networkError: String = ""

    init() {
        Task {
            await self.getAccountNotifications()
        }
    }

    func getAccountNotifications() async {
        if !isLoading {
            // Context is already main thread, so manual dispatch is removed
            isLoading = true
            networkError = ""

            let networkHelper = NetworkHelper()
            do {
                let notifications = try await networkHelper.getAllAccountNotifications()
                isLoading = false
                accountNotifications = notifications
            } catch {
                isLoading = false
                networkError = String(format: String(localized: "details_about_error_s", bundle: Bundle(for: SharedData.self)), "\(error.localizedDescription)")

                LoggingHelper().addLog(
                    importance: LogImportance.critical,
                    error: error.localizedDescription,
                    method: "getAccountNotifications",
                    extra: nil
                )
            }
        }
    }
}
