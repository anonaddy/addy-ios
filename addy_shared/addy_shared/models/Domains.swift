//
//  Domains.swift
//  addy_shared
//
//  Created by Stijn van de Water on 20/05/2024.
//

public struct DomainsArray: Codable {
    public var data: [Domains]
}

struct SingleDomain: Codable {
    let data: Domains
}

public struct Domains:Identifiable, Codable {
    public let id: String
    let user_id: String
    public let domain: String
    public let description: String?
    public let from_name: String?
    public var aliases_count: Int?
    public let default_recipient: Recipients?
    public var active: Bool
    public var catch_all: Bool
    public let domain_verified_at: String?
    public let domain_mx_validated_at: String?
    public let domain_sending_verified_at: String?
    public let created_at: String
    public let updated_at: String
}

public struct DomainOptions: Codable {
    public let data, sharedDomains: [String]
    public let defaultAliasDomain, defaultAliasFormat: String
}
