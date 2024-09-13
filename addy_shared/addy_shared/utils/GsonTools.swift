//
//  GsonTools.swift
//  addy_shared
//
//  Created by Stijn van de Water on 19/07/2024.
//


import Foundation

public class GsonTools {
    public static func jsonToAliasObject(json: String) -> [Aliases]? {
        let loggingHelper = LoggingHelper()

        do {
            let jsonData = json.data(using: .utf8)!
            let aliases = try JSONDecoder().decode([Aliases].self, from: jsonData)
            return aliases
        } catch {
            loggingHelper.addLog(importance: LogImportance.critical, error: error.localizedDescription, method: "jsonToAliasObject", extra: nil)
            return nil
        }
    }
    
    public static func jsonToUserResourceObject(json: String) -> UserResource? {
        let loggingHelper = LoggingHelper()

        do {
            let jsonData = json.data(using: .utf8)!
            let userResource = try JSONDecoder().decode(UserResource.self, from: jsonData)
            return userResource
        } catch {
            loggingHelper.addLog(importance: LogImportance.critical, error: error.localizedDescription, method: "jsonToUserResourceObject", extra: nil)
            return nil
        }
    }
}
