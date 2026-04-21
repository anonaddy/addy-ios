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

    @Published var filter: String? = nil

    init() {
        Task {
            await self.getblocklistEntries(forceReload: true)
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
                    filter: filter
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
