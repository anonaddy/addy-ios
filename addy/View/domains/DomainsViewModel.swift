//
//  DomainsViewModel.swift
//  addy
//
//  Created by Stijn van de Water on 01/06/2024.
//

import addy_shared
import SwiftUI

/// Marked as @MainActor to resolve "Capture of 'self' with non-Sendable type" warnings
/// and remove the need for manual DispatchQueue.main.async calls.
@MainActor
class DomainsViewModel: ObservableObject {
    @Published var domains: DomainsArray? = nil
    @Published var isLoading = false
    @Published var networkError: String = ""

    private let domainRepository: DomainRepositoryProtocol

    init(domainRepository: DomainRepositoryProtocol = DomainRepository.shared) {
        self.domainRepository = domainRepository
        Task {
            await self.getDomains()
        }
    }

    func getDomains() async {
        if !isLoading {
            isLoading = true
            networkError = ""

            do {
                let domains = try await domainRepository.getDomains()
                isLoading = false
                self.domains = domains
            } catch {
                isLoading = false
                guard !Task.isCancelled, !(error is CancellationError), (error as? URLError)?.code != .cancelled else { return }
                networkError = String(format: String(localized: "details_about_error_s", bundle: Bundle(for: SharedData.self)), "\(error.localizedDescription)")

                LoggingHelper().addLog(
                    importance: LogImportance.critical,
                    error: error.localizedDescription,
                    method: "getDomains",
                    extra: nil
                )
            }
        }
    }
}
