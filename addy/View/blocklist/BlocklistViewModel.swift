//
//  BlocklistViewModel.swift
//  addy
//
//  Created by Stijn van de Water on 09/03/2026.
//

import addy_shared
import Combine
import SwiftUI

/// 1. Mark the class as @MainActor to resolve Sendable/Self capture issues
@MainActor
class BlocklistViewModel: ObservableObject {
    @Published var blocklistEntries: BlocklistEntriesArray? = nil
    @Published var isLoading = false
    @Published var hasArrivedAtTheLastPage = true
    @Published var networkError: String = ""
    @Published var searchQuery: String = ""
    @Published var filter: String? = nil

    var searchCancellable: AnyCancellable?
    private let blocklistRepository: BlocklistRepositoryProtocol

    init(blocklistRepository: BlocklistRepositoryProtocol = BlocklistRepository.shared) {
        self.blocklistRepository = blocklistRepository
        searchCancellable = $searchQuery
            .dropFirst()
            .removeDuplicates()
            .debounce(for: 1.0, scheduler: RunLoop.main)
            .sink(receiveValue: { [weak self] str in
                Task {
                    await self?.searchBlocklistEntries(searchQuery: str)
                }
            })

        Task {
            await self.getBlocklistEntries(forceReload: true)
        }
    }

    func searchBlocklistEntries(searchQuery: String) async {
        isLoading = false
        let trimmedSearchQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedSearchQuery.isEmpty {
            if !self.searchQuery.isEmpty {
                self.searchQuery = ""
                await getBlocklistEntries(forceReload: true)
            }
        } else if trimmedSearchQuery.count >= 3 {
            if self.searchQuery != trimmedSearchQuery {
                self.searchQuery = trimmedSearchQuery
                await getBlocklistEntries(forceReload: true)
            }
        } else {
            // When query is reduced below 3 characters from a previous valid search, reset search
            if !self.searchQuery.isEmpty {
                self.searchQuery = ""
                await getBlocklistEntries(forceReload: true)
            }
        }
    }

    func getBlocklistEntries(forceReload: Bool) async {
        if !isLoading {
            isLoading = true
            networkError = ""

            do {
                let pageToLoad = forceReload ? 1 : ((blocklistEntries?.meta?.current_page ?? 0) + 1)
                let entries = try await blocklistRepository.getBlocklistEntries(
                    page: pageToLoad,
                    size: 100,
                    filter: filter,
                    search: searchQuery
                )
                isLoading = false

                if blocklistEntries == nil || forceReload {
                    blocklistEntries = entries
                } else {
                    blocklistEntries?.meta = entries.meta
                    blocklistEntries?.links = entries.links
                    blocklistEntries?.data.append(contentsOf: entries.data)
                }

                hasArrivedAtTheLastPage = entries.meta?.current_page == entries.meta?.last_page || blocklistEntries?.data.isEmpty == true

            } catch {
                isLoading = false
                guard !Task.isCancelled, !(error is CancellationError), (error as? URLError)?.code != .cancelled else { return }
                networkError = String(format: String(localized: "details_about_error_s", bundle: Bundle(for: SharedData.self)), "\(error.localizedDescription)")

                LoggingHelper().addLog(
                    importance: LogImportance.critical,
                    error: error.localizedDescription,
                    method: "getBlocklistEntries",
                    extra: nil
                )
            }
        }
    }

    func loadMoreContent() {
        if !hasArrivedAtTheLastPage {
            Task {
                await getBlocklistEntries(forceReload: false)
            }
        }
    }
}
