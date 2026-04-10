//
//  AliasViewModel.swift
//  addy
//
//  Created by Stijn van de Water on 03/02/2026.
//

import Foundation
import Combine
import addy_shared
import SwiftUI


class AliasViewModel: ObservableObject {
    @Published var aliasList: AliasesArray? = nil
    @Published var isLoading = false
    @Published var networkError: String = ""

    
    var aliasSortFilterRequest = AliasSortFilterRequest(
        onlyActiveAliases: true,
        onlyDeletedAliases: false,
        onlyInactiveAliases: false,
        onlyWatchedAliases: false,
        onlyPinnedAliases: false,
        sort: "updated_at",
        sortDesc: true,
        filter: nil
    )
    
    func getAliases(excludeAliases: [String]? = nil) async {
            DispatchQueue.main.async {
                self.isLoading = true
                self.networkError = ""
            }

            let networkHelper = NetworkHelper()

                do {
                    let aliasArray = try await networkHelper.getAliases(aliasSortFilterRequest: aliasSortFilterRequest, size: 15)
                    DispatchQueue.main.async {
                        self.isLoading = false

                        if let aliasArray = aliasArray {
                            var aliases = aliasArray
                            var aliases2 = aliases.data
                            if let excludeAliases = excludeAliases {
                                // Remove matching items (no assignment needed)
                                aliases2.removeAll { excludeAliases.contains($0.id) }
                            }
                            // Apply changes back
                            aliases.data = aliases2
                            self.aliasList = aliases  // Fixed: assign modified aliases, not original
                        } else {
                            self.networkError = String(
                                format: String(localized: "details_about_error_s", bundle: Bundle(for: SharedData.self)),
                                "\(String(localized: "error_unknown_refer_to_logs", bundle: Bundle(for: SharedData.self)))"
                            )
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.networkError = error.localizedDescription
                    }
                    LoggingHelper().addLog(
                        importance: LogImportance.critical,
                        error: error.localizedDescription,
                        method: "getAliases", extra: nil
                    )
                }
            
        
    }

}
