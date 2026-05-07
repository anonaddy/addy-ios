//
//  BlocklistEntries.swift
//  addy
//
//  Created by Stijn van de Water on 09/03/2026.
//

import Foundation

public struct BlocklistEntriesArray: Codable {
    public var data: [BlocklistEntries]
    public var links: Links?
    public var meta: Meta?
}

struct SingleBlocklistEntry: Codable {
    let data: BlocklistEntries
}

public struct BlocklistEntries: Identifiable, Codable {
    public let id: String
    let user_id: String
    public let value: String
    public let type: String
    public let blocked: Int?
    public let last_blocked: String?
    public let created_at: String
    let updated_at: String
}

public struct NewBlocklistEntry: Codable {
    let type: String
    let value: String

    public init(type: String, value: String) {
        self.type = type
        self.value = value
    }
}
