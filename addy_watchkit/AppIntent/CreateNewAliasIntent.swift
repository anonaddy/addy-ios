//
//  CreateNewAliasIntent.swift
//  addy_watchkit
//
//  Created by Stijn van de Water on 07/02/2026.
//

import addy_shared
import AppIntents

struct CreateNewAliasIntent: AppIntent {
    /// Human-readable title shown in the Shortcuts app
    static var title: LocalizedStringResource = "app_intent_add_alias"

    /// Core logic executed when the intent runs
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        if let userResource = getUserResource() {
            do {
                let alias = try await AliasRepository.shared.addAlias(
                    domain: userResource.default_alias_domain,
                    description: String(localized: "created_on_apple_watch"),
                    format: userResource.default_alias_format == "custom" ? "random_characters" : userResource.default_alias_format,
                    localPart: "",
                    recipients: nil
                )
                let localizedString = LocalizedStringResource("app_intent_alias_added\(alias.email)")
                return .result(value: alias.email, dialog: IntentDialog(localizedString))
            } catch {
                return .result(value: "", dialog: "error_adding_alias")
            }

        } else {
            // Return an empty result, indicating that the intent is complete.
            return .result(value: "", dialog: "app_setup_required")
        }
    }

    func getUserResource() -> UserResource? {
        return CacheHelper.getBackgroundServiceCacheUserResource()
    }
}
