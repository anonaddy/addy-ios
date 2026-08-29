//
//  FailedDeliveriesViewModel.swift
//  addy
//
//  Created by Stijn van de Water on 03/06/2024.
//

import addy_shared
import SwiftUI

/// Marked as @MainActor to resolve "Capture of 'self' with non-Sendable type" warnings
/// and handle all @Published updates safely on the main thread.
@MainActor
class FailedDeliveriesViewModel: ObservableObject {
    @Published var failedDeliveries: FailedDeliveriesArray? = nil
    @Published var isLoading = false
    @Published var hasArrivedAtTheLastPage = true
    @Published var networkError: String = ""
    @Published var filter: String? = nil

    private let failedDeliveriesRepository: FailedDeliveriesRepositoryProtocol

    init(failedDeliveriesRepository: FailedDeliveriesRepositoryProtocol = FailedDeliveriesRepository.shared) {
        self.failedDeliveriesRepository = failedDeliveriesRepository
        Task {
            await self.getFailedDeliveries(forceReload: true)
        }
    }

    func getFailedDeliveries(forceReload: Bool) async {
        if !isLoading {
            isLoading = true
            networkError = ""

            do {
                let pageToLoad = forceReload ? 1 : ((failedDeliveries?.meta?.current_page ?? 0) + 1)
                let failedDeliveriesArray = try await failedDeliveriesRepository.getFailedDeliveries(
                    page: pageToLoad,
                    size: 25,
                    filter: filter
                )
                isLoading = false

                if failedDeliveries == nil || forceReload {
                    failedDeliveries = failedDeliveriesArray
                } else {
                    failedDeliveries?.meta = failedDeliveriesArray.meta
                    failedDeliveries?.links = failedDeliveriesArray.links
                    failedDeliveries?.data.append(contentsOf: failedDeliveriesArray.data)
                }

                hasArrivedAtTheLastPage = failedDeliveriesArray.meta?.current_page == failedDeliveriesArray.meta?.last_page || failedDeliveries?.data.isEmpty == true

            } catch {
                isLoading = false
                guard !Task.isCancelled, !(error is CancellationError), (error as? URLError)?.code != .cancelled else { return }
                networkError = String(format: String(localized: "details_about_error_s", bundle: Bundle(for: SharedData.self)), "\(error.localizedDescription)")

                LoggingHelper().addLog(
                    importance: LogImportance.critical,
                    error: error.localizedDescription,
                    method: "getFailedDeliveries",
                    extra: nil
                )
            }
        }
    }

    func loadMoreContent() {
        if !hasArrivedAtTheLastPage {
            Task {
                await getFailedDeliveries(forceReload: false)
            }
        }
    }
}
