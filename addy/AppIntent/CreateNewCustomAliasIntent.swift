//
//  CreateNewCustomAliasIntent.swift
//  addy
//
//  Created by Stijn van de Water on 13/07/2024.
//


import AppIntents
import SwiftUI
import addy_shared
import UniformTypeIdentifiers

    
struct CreateNewCustomAliasIntent: AppIntent {
    
    static var title: LocalizedStringResource = "app_intent_add_alias_custom"
    static var description: IntentDescription = .init("app_intent_add_alias_desc", categoryName: "app_intent_category_name", searchKeywords: ["add", "create", "alias", "email"])
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "app_intent_add_alias_parameter_domain",
      description: "app_intent_add_alias_parameter_domain_desc",
               default: nil)
    var domain: String?
    
    @Parameter(title: "app_intent_add_alias_parameter_custom",
      description: "app_intent_add_alias_parameter_custom_desc",
               default: nil)
    var localPart: String
    
    static var authenticationPolicy = IntentAuthenticationPolicy.requiresLocalDeviceAuthentication

    
    /**
     When the system runs the intent, it calls `perform()`.
     
     Intents run on an arbitrary queue. Intents that manipulate UI need to annotate `perform()` with `@MainActor`
     so that the UI operations run on the main actor.
     */
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {

        if let userResource = getUseResource() {
            do {
                if let alias = try await NetworkHelper().addAlias(domain: domain ?? userResource.default_alias_domain, description: "", format: "custom", localPart: localPart, recipients: nil) {
                    
                    UIPasteboard.general.setValue(alias.email,forPasteboardType: UTType.plainText.identifier)

                    if UIPasteboard.general.hasStrings{
                        let localizedString = LocalizedStringResource("app_intent_alias_added\(alias.email)")
                        return .result(dialog: IntentDialog(localizedString))
                    } else {
                        let localizedString = LocalizedStringResource("app_intent_alias_added_no_copy\(alias.email)")
                        return .result(dialog: IntentDialog(localizedString))
                    }
                    
                } else {
                    return .result(dialog: "error_adding_alias")
                }
            } catch {
                return .result(dialog: "error_adding_alias")
            }
            
        } else {
              /// Return an empty result, indicating that the intent is complete.
            return .result(dialog: "app_setup_required")
        }

    }
    
    static var parameterSummary: some ParameterSummary {
        Summary("app_intent_parameter_summary_domain\(\.$domain)_custom\(\.$localPart)")
        
    }
    
    func getUseResource() -> UserResource?{
        let encryptedSettingsManager = SettingsManager(encrypted: true)

        if let jsonString = encryptedSettingsManager.getSettingsString(key: .userResource),
           let jsonData = jsonString.data(using: .utf8) {
            let decoder = JSONDecoder()
            return try? decoder.decode(UserResource.self, from: jsonData)
        }
        return nil
    }
}


