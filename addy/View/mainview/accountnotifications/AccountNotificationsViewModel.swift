//
//  AccountNotificationsViewModel.swift
//  addy
//
//  Created by Stijn van de Water on 23/08/2024.
//

import addy_shared
import SwiftUI

/// Marked as @MainActor to ensure all updates to @Published properties
/// and the Task lifecycle happen safely on the main thread.
@MainActor
class AccountNotificationsViewModel: ObservableObject {
    @Published var accountNotifications: AccountNotificationsArray? = nil
    @Published var isLoading = false
    @Published var networkError: String = ""

    private let appMaintenanceRepository: AppMaintenanceRepositoryProtocol

    init(appMaintenanceRepository: AppMaintenanceRepositoryProtocol = AppMaintenanceRepository.shared) {
        self.appMaintenanceRepository = appMaintenanceRepository
        Task {
            await self.getAccountNotifications()
        }
    }

    func getAccountNotifications() async {
        if !isLoading {
            isLoading = true
            networkError = ""

            do {
                let notifications = try await appMaintenanceRepository.getAllAccountNotifications()
                isLoading = false
                accountNotifications = notifications
            } catch {
                isLoading = false
                guard !Task.isCancelled, !(error is CancellationError), (error as? URLError)?.code != .cancelled else { return }
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
