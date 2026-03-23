//
//  FailedDeliveriesViewModel.swift
//  addy
//
//  Created by Stijn van de Water on 03/06/2024.
//

import addy_shared
import Combine
import SwiftUI

// Marked as @MainActor to resolve "Capture of 'self' with non-Sendable type" warnings
// and handle all @Published updates safely on the main thread.
@MainActor
class FailedDeliveriesViewModel: ObservableObject {
    @Published var failedDeliveries: FailedDeliveriesArray? = nil

    @Published var isLoading = false
    @Published var networkError: String = ""

    init() {
        Task {
            await self.getFailedDeliveries()
        }
    }

    func getFailedDeliveries() async {
        if !isLoading {
            self.isLoading = true
            self.networkError = ""
            
            let networkHelper = NetworkHelper()
            do {
                let failedDeliveries = try await networkHelper.getFailedDeliveries()
                self.isLoading = false
                self.failedDeliveries = failedDeliveries
            } catch {
                self.isLoading = false
                self.networkError = String(format: String(localized: "details_about_error_s", bundle: Bundle(for: SharedData.self)), "\(error.localizedDescription)")
                
                LoggingHelper().addLog(
                    importance: LogImportance.critical,
                    error: error.localizedDescription,
                    method: "getFailedDeliveries",
                    extra: nil
                )
            }
        }
    }
}
