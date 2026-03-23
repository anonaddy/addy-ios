//
//  BlocklistEntriesArray.swift
//  addy
//
//  Created by Stijn van de Water on 09/03/2026.
//


import Foundation

public struct BlocklistEntriesArray: Codable {
    public var data: [BlocklistEntries]
}

struct SingleBlocklistEntry: Codable {
    let data: BlocklistEntries
}

public struct BlocklistEntries: Identifiable, Codable {
    public let created_at: String
    public let id: String
    public let type: String
    let updated_at: String
    let user_id: String
    public let value: String
}

public struct NewBlocklistEntry: Codable {
    let type: String
    let value: String

    public init(type: String, value: String) {
        self.type = type
        self.value = value
    }
}
