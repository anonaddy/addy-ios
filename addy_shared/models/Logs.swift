//
//  Logs.swift
//  addy
//
//  Created by Stijn van de Water on 07/05/2024.
//

import Foundation

public struct Logs: Codable, Identifiable {
    public var id = UUID() // Add this line

    /*
     importance
     0 = Critical (red)
     1 = Warning (yellow)
     2 = Info (green)
      */
    public var importance: LogImportance = .info
    public var dateTime: String
    public var method: String?
    public var message: String
    public var extra: String?
}

public func logsToString(_ logs: [Logs]) -> String? {
    let encoder = JSONEncoder()
    // Correct property: dateEncodingStrategy
    encoder.dateEncodingStrategy = .iso8601

    guard let data = try? encoder.encode(logs) else { return nil }
    return String(data: data, encoding: .utf8)
}

public func stringToLogs(_ jsonString: String) -> [Logs] {
    let decoder = JSONDecoder()
    // Correct property: dateDecodingStrategy (Notice the "De")
    decoder.dateDecodingStrategy = .iso8601

    guard let data = jsonString.data(using: .utf8),
          let logs = try? decoder.decode([Logs].self, from: data)
    else {
        return []
    }
    return logs
}

public enum LogImportance: Int, Encodable, Decodable {
    case critical = 0
    case warning = 1
    case info = 2
}
