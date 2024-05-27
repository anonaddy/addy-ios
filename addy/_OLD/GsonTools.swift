//
//  GsonTOols.swift
//  addy
//
//  Created by Stijn van de Water on 12/05/2024.
//

import Foundation
import addy_shared

class GsonTools {
    static func jsonToAliasObject(json: String) -> [Aliases]? {
        var loggingHelper = LoggingHelper()

        do {
            let jsonData = json.data(using: .utf8)!
            let aliases = try JSONDecoder().decode([Aliases].self, from: jsonData)
            return aliases
        } catch {
            print("Error: \(error)")
            loggingHelper.addLog(importance: LogImportance.critical, error: error.localizedDescription, method: "jsonToAliasObject", extra: nil)
            return nil
        }
    }
}
