//
//  AliasesViewModel.swift
//  addy
//
//  Created by Stijn van de Water on 09/05/2024.
//

import addy_shared
import Combine
import SwiftUI

@MainActor
class AliasesViewModel: ObservableObject {
    @Published var aliasSortFilterRequest = AliasSortFilterRequest(
        onlyActiveAliases: false,
        onlyDeletedAliases: false,
        onlyInactiveAliases: false,
        onlyWatchedAliases: false,
        sort: "created_at",
        sortDesc: false,
        filter: ""
    )

    var defaultSortFilterRequest = AliasSortFilterRequest(
        onlyActiveAliases: false,
        onlyDeletedAliases: false,
        onlyInactiveAliases: false,
        onlyWatchedAliases: false,
        sort: "created_at",
        sortDesc: false,
        filter: ""
    )

    @Published var searchQuery = ""

    var searchCancellable: AnyCancellable?

    @Published var aliasList: AliasesArray? = nil

    @Published var isLoading = false
    @Published var hasArrivedAtTheLastPage = true
    @Published var networkError: String = ""

    init() {
        // Since the class is @MainActor, this closure is also executed on the MainActor
        searchCancellable = $searchQuery
            .dropFirst()
            .removeDuplicates()
            .debounce(for: 1.0, scheduler: RunLoop.main)
            .sink(receiveValue: { [weak self] str in
                Task {
                    await self?.searchAliases(searchQuery: str)
                }
            })
    }

    func searchAliases(searchQuery: String) async {
        // When something is being searched cancel the loading to make sure that the networkCall will succeed
        isLoading = false
        let trimmedSearchQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedSearchQuery == "" {
            // Reset Data....
            aliasSortFilterRequest.filter = ""
            await self.getAliases(forceReload: true)
        } else {
            if trimmedSearchQuery.count >= 3 {
                // search Data
                aliasSortFilterRequest.filter = trimmedSearchQuery
                await self.getAliases(forceReload: true)
            }
            // Don't search for searchTerms for < 3 chars
        }
    }

    func getAliases(forceReload: Bool) async {
        if !isLoading {
            self.isLoading = true
            self.networkError = ""

            if forceReload {
                // This will make sure that the meta resets and jumps back to 0
                self.aliasList = nil
            }

            #if DEBUG
                print("page is \(aliasList?.meta?.current_page ?? 0)")
            #endif

            let networkHelper = NetworkHelper()

            /**
             * CHECK IF WATCHED ONLY IS TRUE
             * If true simply bulk-obtain all the watched aliases
             */
            if aliasSortFilterRequest.onlyWatchedAliases {
                let aliasWatcher = AliasWatcher()
                let aliasesToWatch: [String] = Array(aliasWatcher.getAliasesToWatch())

                if !aliasesToWatch.isEmpty {
                    do {
                        let BulkAliasesArray = try await networkHelper.bulkGetAlias(aliases: aliasesToWatch)

                        self.isLoading = false

                        if let BulkAliasesArray = BulkAliasesArray {
                            let aliasArray = AliasesArray(data: BulkAliasesArray.data)
                            self.aliasList = aliasArray

                            // Since the bulkGetAlias func always returns everything we are always at the last page
                            self.hasArrivedAtTheLastPage = true
                        } else {
                            self.networkError = String(format: String(localized: "details_about_error_s", bundle: Bundle(for: SharedData.self)), "\(String(localized: "error_unknown_refer_to_logs", bundle: Bundle(for: SharedData.self)))")
                        }
                    } catch {
                        self.isLoading = false
                        self.networkError = error.localizedDescription
                        
                        LoggingHelper().addLog(
                            importance: LogImportance.critical,
                            error: error.localizedDescription,
                            method: "getAliases", extra: nil
                        )
                    }
                } else {
                    self.hasArrivedAtTheLastPage = true
                    self.isLoading = false
                    // This could be triggered if you remove the last watched alias and then refresh
                    self.aliasList = AliasesArray(data: [])
                }

            } else {
                do {
                    let aliasArray = try await networkHelper.getAliases(aliasSortFilterRequest: aliasSortFilterRequest, page: (aliasList?.meta?.current_page ?? 0) + 1, size: 25)
                    
                    self.isLoading = false

                    if let aliasArray = aliasArray {
                        if self.aliasList == nil {
                            // If aliasList is empty, assign it
                            self.aliasList = aliasArray
                        } else {
                            // If aliasList is not empty, set the meta and links and append retrieved aliases
                            self.aliasList?.meta = aliasArray.meta
                            self.aliasList?.links = aliasArray.links
                            self.aliasList?.data.append(contentsOf: aliasArray.data)
                        }

                        self.hasArrivedAtTheLastPage = aliasArray.meta?.current_page == aliasArray.meta?.last_page || self.aliasList?.data.isEmpty == true

                    } else {
                        self.hasArrivedAtTheLastPage = true
                        self.networkError = String(format: String(localized: "details_about_error_s", bundle: Bundle(for: SharedData.self)), "\(String(localized: "error_unknown_refer_to_logs", bundle: Bundle(for: SharedData.self)))")
                    }
                } catch {
                    self.isLoading = false
                    self.networkError = error.localizedDescription
                    
                    LoggingHelper().addLog(
                        importance: LogImportance.critical,
                        error: error.localizedDescription,
                        method: "getAliases", extra: nil
                    )
                }
            }
        }
    }

    func loadMoreContent() {
        if !hasArrivedAtTheLastPage {
            Task {
                await getAliases(forceReload: false)
            }
        }
    }
}
