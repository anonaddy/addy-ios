//
//  CreateNewAliasIntent.swift
//  addy
//
//  Created by Stijn van de Water on 13/07/2024.
//

import AppIntents
import SwiftUI
import addy_shared
import UniformTypeIdentifiers



    
struct CreateNewAliasIntent: AppIntent {
    
    //MARK: Used for AppIntent Protocol https://developer.apple.com/documentation/appintents/appintent
    static var title: LocalizedStringResource = "app_intent_add_alias"
    static var description: IntentDescription = .init("app_intent_add_alias_desc", categoryName: "app_intent_category_name", searchKeywords: ["add", "create", "alias", "email"], resultValueName: "app_intent_alias_output")
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "app_intent_add_alias_parameter_domain",
      description: "app_intent_add_alias_parameter_domain_desc",
               default: nil)
    var domain: String?
    
    @Parameter(title: "app_intent_add_alias_parameter_description",
      description: "app_intent_add_alias_parameter_description_desc",
               default: nil)
    var description: String?
    
    
    @Parameter(title: "app_intent_add_alias_parameter_format",
      description: "app_intent_add_alias_parameter_format_desc",
               default: nil)
    var format: ShortcutableFormat?
    
    static var authenticationPolicy = IntentAuthenticationPolicy.requiresLocalDeviceAuthentication
    //MARK: END

    
    /**
     When the system runs the intent, it calls `perform()`.
     
     Intents run on an arbitrary queue. Intents that manipulate UI need to annotate `perform()` with `@MainActor`
     so that the UI operations run on the main actor.
     */
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {

        if let userResource = getUserResource() {
            do {
                if let alias = try await NetworkHelper().addAlias(domain: domain ?? userResource.default_alias_domain, description: description ?? "", format: (format != nil) ?
                                                                  (format?.rawValue == "custom" ? " " : format?.rawValue)! :
                                                                    (userResource.default_alias_format == "custom" ? "random_characters" : userResource.default_alias_format), localPart: "", recipients: nil) {
                    
                    UIPasteboard.general.setValue(alias.email,forPasteboardType: UTType.plainText.identifier)

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
    
    public enum ShortcutableFormat: String, AppEnum {
        case random_characters
        case uuid
        case random_words
        
        static var typeDisplayName: LocalizedStringResource = "format"

        public static var typeDisplayRepresentation: TypeDisplayRepresentation = "format"
        
        public static var caseDisplayRepresentations: [ShortcutableFormat: DisplayRepresentation] = [
            .random_characters: "domains_format_random_characters",
            .uuid: "domains_format_uuid",
            .random_words: "domains_format_random_words",
        ]
    }
    
    static var parameterSummary: some ParameterSummary {
        Summary("app_intent_parameter_summary_domain\(\.$domain)_format\(\.$format)_description\(\.$description)")
        
    }
    
    func getUserResource() -> UserResource?{
        let encryptedSettingsManager = SettingsManager(encrypted: true)

        if let jsonString = encryptedSettingsManager.getSettingsString(key: .userResource),
           let jsonData = jsonString.data(using: .utf8) {
            let decoder = JSONDecoder()
            return try? decoder.decode(UserResource.self, from: jsonData)
        }
        return nil
    }
}


