//
//  StartTaskIntent.swift
//  addy
//
//  Created by Stijn van de Water on 07/02/2026.
//


import AppIntents
import addy_shared

struct StartTaskIntent: AppIntent {
    // Human-readable title shown in the Shortcuts app
    static var title: LocalizedStringResource = "app_intent_add_alias"

    
    // Core logic executed when the intent runs
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        if let userResource = getUserResource() {
            do {
                if let alias = try await NetworkHelper().addAlias(domain: userResource.default_alias_domain, description: String(localized: "created_on_apple_watch") , format: userResource.default_alias_format == "custom" ? "random_characters" : userResource.default_alias_format, localPart: "", recipients: nil)
                {
                    let localizedString = LocalizedStringResource("app_intent_alias_added\(alias.email)")
                    return .result(value: alias.email, dialog: IntentDialog(localizedString))

                } else {
                    return .result(value: "", dialog: "error_adding_alias")
                }
            } catch {
                return .result(value: "", dialog: "error_adding_alias")
            }

        } else {
            /// Return an empty result, indicating that the intent is complete.
            return .result(value: "", dialog: "app_setup_required")
        }
    }

    func getUserResource() -> UserResource? {
        let encryptedSettingsManager = SettingsManager(encrypted: true)

        if let jsonString = encryptedSettingsManager.getSettingsString(key: .userResource),
           let jsonData = jsonString.data(using: .utf8)
        {
            let decoder = JSONDecoder()
            return try? decoder.decode(UserResource.self, from: jsonData)
        }
        return nil
    }
}
