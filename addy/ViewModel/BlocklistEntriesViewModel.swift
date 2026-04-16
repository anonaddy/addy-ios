//
//  ManageBlocklistViewModel.swift
//  addy
//
//  Created by Stijn van de Water on 09/03/2026.
//

import addy_shared
import Combine
import SwiftUI

// 1. Mark the class as @MainActor to resolve Sendable/Self capture issues
@MainActor
class BlocklistEntriesViewModel: ObservableObject {
    @Published var blocklistEntries: BlocklistEntriesArray? = nil
    @Published var isLoading = false
    @Published var hasArrivedAtTheLastPage = true
    @Published var networkError: String = ""

    init() {
        Task {
            await self.getblocklistEntries(forceReload: true)
        }
    }

    func getblocklistEntries(forceReload: Bool) async {
        if !isLoading {
            // 2. No more DispatchQueue.main.async needed!
            // @MainActor handles the context switching automatically.
            self.isLoading = true
            self.networkError = ""
            
            let networkHelper = NetworkHelper()
            do {
                let pageToLoad = forceReload ? 1 : ((blocklistEntries?.meta?.current_page ?? 0) + 1)
                let entries = try await networkHelper.getAllBlocklistEntries(
                    page: pageToLoad,
                    size: 100
                )
                self.isLoading = false

                if let entries = entries {
                    if self.blocklistEntries == nil || forceReload {
                        self.blocklistEntries = entries
                    } else {
                        self.blocklistEntries?.meta = entries.meta
                        self.blocklistEntries?.links = entries.links
                        self.blocklistEntries?.data.append(contentsOf: entries.data)
                    }

                    self.hasArrivedAtTheLastPage = entries.meta?.current_page == entries.meta?.last_page || self.blocklistEntries?.data.isEmpty == true
                } else {
                    self.hasArrivedAtTheLastPage = true
                }

            } catch {
                self.isLoading = false
                
                // Using your specific localized string format
                self.networkError = String(format: String(localized: "details_about_error_s", bundle: Bundle(for: SharedData.self)), "\(error.localizedDescription)")
                
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
