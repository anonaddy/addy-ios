//
//  LabelsViewModel.swift
//  addy
//
//  Created by Stijn van de Water on 24/06/2026.
//

import addy_shared
import Combine
import SwiftUI

@MainActor
class LabelsViewModel: ObservableObject {
    @Published var labels: LabelsArray? = nil
    @Published var isLoading = false
    @Published var networkError: String = ""
    @Published var searchQuery: String = ""

    var searchCancellable: AnyCancellable?

    init() {
        searchCancellable = $searchQuery
            .dropFirst()
            .removeDuplicates()
            .debounce(for: 1.0, scheduler: RunLoop.main)
            .sink(receiveValue: { [weak self] str in
                Task {
                    await self?.searchLabels(searchQuery: str)
                }
            })

        Task {
            await self.getLabels()
        }
    }

    func searchLabels(searchQuery: String) async {
        isLoading = false
        let trimmedSearchQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedSearchQuery == "" {
            self.searchQuery = ""
            await getLabels()
        } else {
            if trimmedSearchQuery.count >= 3 {
                self.searchQuery = trimmedSearchQuery
                await getLabels()
            }
        }
    }

    func getLabels() async {
        if !isLoading {
            isLoading = true
            networkError = ""

            let networkHelper = NetworkHelper()
            do {
                let fetchedLabels = try await networkHelper.getLabels(filter: searchQuery)
                isLoading = false
                self.labels = fetchedLabels
            } catch {
                isLoading = false
                networkError = String(format: String(localized: "details_about_error_s", bundle: Bundle(for: SharedData.self)), "\(error.localizedDescription)")

                LoggingHelper().addLog(
                    importance: LogImportance.critical,
                    error: error.localizedDescription,
                    method: "getLabels",
                    extra: nil
                )
            }
        }
    }
}
