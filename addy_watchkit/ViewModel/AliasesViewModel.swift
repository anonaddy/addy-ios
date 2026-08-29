//
//  AliasesViewModel.swift
//  addy
//
//  Created by Stijn van de Water on 03/02/2026.
//

import addy_shared
import Combine
import SwiftUI

@MainActor
class AliasesViewModel: ObservableObject {
    @Published var aliasList: AliasesArray? = nil
    @Published var isLoading = false
    @Published var networkError: String = ""

    private let aliasRepository: AliasRepositoryProtocol

    var aliasSortFilterRequest = AliasSortFilterRequest(
        onlyActiveAliases: true,
        onlyDeletedAliases: false,
        onlyInactiveAliases: false,
        onlyWatchedAliases: false,
        onlyPinnedAliases: false,
        sort: "updated_at",
        sortDesc: true,
        filter: nil, label: nil
    )

    init(aliasRepository: AliasRepositoryProtocol = AliasRepository.shared) {
        self.aliasRepository = aliasRepository
    }

    func getAliases(excludeAliases: [String]? = nil) async {
        self.isLoading = true
        self.networkError = ""

        do {
            let aliasArray = try await aliasRepository.getAliases(aliasSortFilterRequest: aliasSortFilterRequest, size: 15)
            self.isLoading = false

            var aliases = aliasArray
            var aliases2 = aliases.data
            if let excludeAliases = excludeAliases {
                // Remove matching items (no assignment needed)
                aliases2.removeAll { excludeAliases.contains($0.id) }
            }
            // Apply changes back
            aliases.data = aliases2
            self.aliasList = aliases // Fixed: assign modified aliases, not original
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
