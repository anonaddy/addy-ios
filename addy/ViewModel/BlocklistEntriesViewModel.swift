//
//  BlocklistEntriesViewModel.swift
//  addy
//
//  Created by Stijn van de Water on 09/03/2026.
//

import addy_shared
import Combine
import SwiftUI

/// 1. Mark the class as @MainActor to resolve Sendable/Self capture issues
@MainActor
class BlocklistEntriesViewModel: ObservableObject {
    @Published var blocklistEntries: BlocklistEntriesArray? = nil
    @Published var isLoading = false
    @Published var hasArrivedAtTheLastPage = true
    @Published var networkError: String = ""
    @Published var searchQuery: String = ""

    var searchCancellable: AnyCancellable?

    @Published var filter: String? = nil

    init() {
        searchCancellable = $searchQuery
            .dropFirst()
            .removeDuplicates()
            .debounce(for: 1.0, scheduler: RunLoop.main)
            .sink(receiveValue: { [weak self] str in
                Task {
                    await self?.searchblocklistEntries(searchQuery: str)
                }
            })

        Task {
            await self.getblocklistEntries(forceReload: true)
        }
    }

    func searchblocklistEntries(searchQuery: String) async {
        // When something is being searched cancel the loading to make sure that the networkCall will succeed
        isLoading = false
        let trimmedSearchQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedSearchQuery == "" {
            // Reset Data....
            self.searchQuery = ""
            await getblocklistEntries(forceReload: true)
        } else {
            if trimmedSearchQuery.count >= 3 {
                // search Data
                self.searchQuery = trimmedSearchQuery
                await getblocklistEntries(forceReload: true)
            }
            // Don't search for searchTerms for < 3 chars
        }
    }

    func getblocklistEntries(forceReload: Bool) async {
        if !isLoading {
            // 2. No more DispatchQueue.main.async needed!
            // @MainActor handles the context switching automatically.
            isLoading = true
            networkError = ""

            let networkHelper = NetworkHelper()
            do {
                let pageToLoad = forceReload ? 1 : ((blocklistEntries?.meta?.current_page ?? 0) + 1)
                let entries = try await networkHelper.getAllBlocklistEntries(
                    page: pageToLoad,
                    size: 100,
                    filter: filter,
                    search: searchQuery
                )
                isLoading = false

                if let entries = entries {
                    if blocklistEntries == nil || forceReload {
                        blocklistEntries = entries
                    } else {
                        blocklistEntries?.meta = entries.meta
                        blocklistEntries?.links = entries.links
                        blocklistEntries?.data.append(contentsOf: entries.data)
                    }

                    hasArrivedAtTheLastPage = entries.meta?.current_page == entries.meta?.last_page || blocklistEntries?.data.isEmpty == true
                } else {
                    hasArrivedAtTheLastPage = true
                }

            } catch {
                isLoading = false

                // Using your specific localized string format
                networkError = String(format: String(localized: "details_about_error_s", bundle: Bundle(for: SharedData.self)), "\(error.localizedDescription)")

                LoggingHelper().addLog(
                    importance: LogImportance.critical,
                    error: error.localizedDescription,
                    method: "getblocklistEntries",
                    extra: nil
                )
            }
        }
    }

    func loadMoreContent() {
        if !hasArrivedAtTheLastPage {
            Task {
                await getblocklistEntries(forceReload: false)
            }
        }
    }
}
