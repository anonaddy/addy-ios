//
//  Usernames.swift
//  addy_shared
//
//  Created by Stijn van de Water on 01/06/2024.
//

public struct UsernamesArray: Codable {
    public var `data`: [Usernames]
}

struct SingleUsername: Codable {
    let `data`: Usernames
}

public struct Usernames:Identifiable, Codable {
    public let id: String
    let user_id: String
    public let username: String
    public let description: String?
    public let from_name: String?
    public var aliases_count: Int?
    public let default_recipient: Recipients?
    public var active: Bool
    public var catch_all: Bool
    public var can_login: Bool
    public let created_at: String
    public let updated_at: String
}
