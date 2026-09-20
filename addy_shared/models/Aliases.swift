//
//  Aliases.swift
//  addy_shared
//
//  Created by Stijn van de Water on 08/05/2024.
//
struct SingleAlias: Codable, Sendable {
    let data: Aliases
}

public struct Aliases: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    let user_id: String
    let aliasable_id: String?
    let aliasable_type: String?
    public let local_part: String
    let `extension`: String?
    public let domain: String
    public var email: String
    public var active: Bool
    public var pinned: Bool
    public let description: String?
    public let from_name: String?
    public var attached_recipients_only: Bool
    public let emails_forwarded: Int
    public let emails_blocked: Int
    public let emails_replied: Int
    public let emails_sent: Int
    public let recipients: [Recipients]?
    public var labels: [Labels]?
    public let last_forwarded: String?
    public let last_blocked: String?
    public let last_replied: String?
    public let last_sent: String?
    public let created_at: String
    public let updated_at: String
    public var deleted_at: String?
}


