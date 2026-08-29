//
//  CreateAliasViewModel.swift
//  addy_watchkit
//
//  Created by Stijn van de Water on 07/02/2026.
//

import addy_shared
import Combine
import SwiftUI

@MainActor
class CreateAliasViewModel: ObservableObject {
    @Published var alias: Aliases?
    @Published var isLoading = false
    @Published var networkError: String = ""
    @Published var showAlert = false

    private let aliasRepository: AliasRepositoryProtocol

    init(aliasRepository: AliasRepositoryProtocol = AliasRepository.shared) {
        self.aliasRepository = aliasRepository
    }

    func checkUserAndCreate(
        skipAliasCreateGuide: Bool,
        appState: AppState,
        mainViewState: MainViewState
    ) async {
        guard appState.apiKey != nil else { return }

        if skipAliasCreateGuide {
            createAlias(domain: mainViewState.userResource?.default_alias_domain)
        }
    }

    func createAlias(domain: String? = nil) {
        guard !isLoading else { return }
        isLoading = true
        networkError = ""

        Task {
            do {
                guard let userResource = CacheHelper.getBackgroundServiceCacheUserResource() else {
                    isLoading = false
                    return
                }

                let result = try await aliasRepository.addAlias(
                    domain: domain ?? userResource.default_alias_domain,
                    description: String(localized: "created_on_apple_watch"),
                    format: userResource.default_alias_format == "custom" ? "random_characters" : userResource.default_alias_format,
                    localPart: "", recipients: nil
                )

                isLoading = false
                self.alias = result

            } catch {
                isLoading = false
                guard !Task.isCancelled, !(error is CancellationError), (error as? URLError)?.code != .cancelled else { return }
                self.networkError = error.localizedDescription
                self.showAlert = true
                HapticHelper.playHapticFeedback(hapticType: .error)

                LoggingHelper().addLog(
                    importance: LogImportance.critical,
                    error: error.localizedDescription,
                    method: "createAlias", extra: nil
                )
            }
        }
    }
}
