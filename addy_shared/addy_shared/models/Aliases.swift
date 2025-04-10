//
//  Aliases.swift
//  addy_shared
//
//  Created by Stijn van de Water on 08/05/2024.
//

public struct AliasesArray:Codable {
    public var data: [Aliases]
    public var links: Links?
    public var meta: Meta?
    
    public init(data: [Aliases], links: Links? = nil, meta: Meta? = nil) {
        self.data = data
        self.links = links
        self.meta = meta
    }
}

public struct BulkAliasesArray: Codable {
    public var data: [Aliases]
}

struct SingleAlias: Codable {
    let data: Aliases
}

public struct Aliases: Identifiable, Codable, Hashable {
    public let id: String
    let user_id: String
    let aliasable_id: String?
    let aliasable_type: String?
    public let local_part: String
    let `extension`: String?
    public let domain: String
    public var email: String
    public var active: Bool
    public let description: String?
    public let from_name: String?
    public var attached_recipients_only: Bool
    public let emails_forwarded: Int
    public let emails_blocked: Int
    public let emails_replied: Int
    public let emails_sent: Int
    public let recipients: [Recipients]?
    public let last_forwarded: String?
    public let last_blocked: String?
    public let last_replied: String?
    public let last_sent: String?
    public let created_at: String
    public let updated_at: String
    public var deleted_at: String?
}


public struct Meta:Codable {
    public let current_page: Int
    let from: Int?
    public let last_page: Int
    let links: [Link]
    let path: String
    let per_page: Int
    let to: Int?
    let total: Int
}

struct Link:Codable {
    let url: String?
    let label: String
    let active: Bool
}

public struct Links:Codable {
    let first: String?
    let last: String?
    let prev: String?
    let next: String?
}
