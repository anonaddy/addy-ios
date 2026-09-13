//
//  FindAliasIntent.swift
//  addy
//
//  Created by Stijn van de Water on 13/09/2026.
//

import addy_shared
import AppIntents
import SwiftUI
import UniformTypeIdentifiers

struct FindAliasIntent: AppIntent {
    // MARK: Used for AppIntent Protocol https://developer.apple.com/documentation/appintents/appintent

    static var title: LocalizedStringResource = "app_intent_find_alias"
    static var description: IntentDescription = .init(
        "app_intent_find_alias_desc",
        categoryName: "app_intent_category_name",
        searchKeywords: ["find", "search", "lookup", "alias", "email"],
        resultValueName: "app_intent_alias_output"
    )
    static var openAppWhenRun: Bool = false

    @Parameter(
        title: "app_intent_find_alias_parameter_query",
        description: "app_intent_find_alias_parameter_query_desc",
        requestValueDialog: IntentDialog("app_intent_find_alias_parameter_query_prompt")
    )
    var searchQuery: String

    static var authenticationPolicy = IntentAuthenticationPolicy.requiresLocalDeviceAuthentication

    // MARK: END

    /*
     When the system runs the intent, it calls `perform()`.
     Intents run on an arbitrary queue. Intents that manipulate UI need to annotate `perform()` with `@MainActor`
     so that the UI operations run on the main actor.
     */

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        guard SettingsManager(encrypted: true).getSettingsString(key: .apiKey) != nil else {
            return .result(value: "", dialog: "app_setup_required")
        }

        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return .result(value: "", dialog: IntentDialog("app_intent_find_alias_empty_query"))
        }

        do {
            let request = AliasSortFilterRequest(
                onlyActiveAliases: false,
                onlyDeletedAliases: false,
                onlyInactiveAliases: false,
                onlyWatchedAliases: false,
                onlyPinnedAliases: false,
                sort: "created_at",
                sortDesc: true,
                filter: trimmedQuery,
                label: nil
            )

            let response = try await AliasRepository.shared.getAliases(
                aliasSortFilterRequest: request,
                page: 1,
                size: 5
            )

            guard let firstMatch = response.data.first else {
                let notFoundString = LocalizedStringResource("app_intent_alias_not_found\(trimmedQuery)")
                return .result(value: "", dialog: IntentDialog(notFoundString))
            }

            UIPasteboard.general.setValue(firstMatch.email, forPasteboardType: UTType.plainText.identifier)

            let foundString = LocalizedStringResource("app_intent_alias_found\(firstMatch.email)")
            return .result(value: firstMatch.email, dialog: IntentDialog(foundString))
        } catch {
            return .result(value: "", dialog: "error_retrieving_aliases")
        }
    }

    static var parameterSummary: some ParameterSummary {
        Summary("app_intent_parameter_summary_searchQuery\(\.$searchQuery)")
    }
}
