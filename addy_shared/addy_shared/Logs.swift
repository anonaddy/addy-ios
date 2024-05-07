//
//  Logs.swift
//  addy
//
//  Created by Stijn van de Water on 07/05/2024.
//

struct Logs: Encodable, Decodable {
    /*
    importance
    0 = Critical (red)
    1 = Warning (yellow)
    2 = Info (green)
     */
    var importance: LogImportance = .info
    var dateTime: String?
    var method: String?
    var message: String?
    var extra: String?
}

public enum LogImportance: Int, Encodable, Decodable {
    case critical = 0
    case warning = 1
    case info = 2
}
