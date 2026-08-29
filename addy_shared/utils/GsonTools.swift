//
//  GsonTools.swift
//  addy_shared
//
//  Created by Stijn van de Water on 19/07/2024.
//

import Foundation

public class GsonTools {
    public static func decode<T: Decodable>(_ type: T.Type = T.self, from json: String) -> T? {
        let loggingHelper = LoggingHelper()
        do {
            guard let jsonData = json.data(using: .utf8) else { return nil }
            return try JSONDecoder().decode(type, from: jsonData)
        } catch {
            loggingHelper.addLog(importance: LogImportance.critical, error: error.localizedDescription, method: "decode<\(T.self)>", extra: nil)
            return nil
        }
    }

    public static func jsonToAliasObject(json: String) -> [Aliases]? {
        return decode([Aliases].self, from: json)
    }

    public static func jsonToUserResourceObject(json: String) -> UserResource? {
        return decode(UserResource.self, from: json)
    }
}
