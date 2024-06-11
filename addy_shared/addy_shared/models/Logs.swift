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

public enum LogImportance: Int, Encodable, Decodable {
    case critical = 0
    case warning = 1
    case info = 2
}
