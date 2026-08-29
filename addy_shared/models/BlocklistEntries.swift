//
//  BlocklistEntries.swift
//  addy
//
//  Created by Stijn van de Water on 09/03/2026.
//

import Foundation
struct SingleBlocklistEntry: Codable, Sendable {
    let data: BlocklistEntries
}

public struct BlocklistEntries: Identifiable, Codable, Sendable {
    public let id: String
    let user_id: String
    public let value: String
    public let type: String
    public let blocked: Int?
    public let last_blocked: String?
    public let created_at: String
    let updated_at: String
}

public struct NewBlocklistEntry: Codable, Sendable {
    public let type: String
    public let value: String

    public init(type: String, value: String) {
        self.type = type
        self.value = value
    }
}
