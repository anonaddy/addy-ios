//
//  Domains.swift
//  addy_shared
//
//  Created by Stijn van de Water on 20/05/2024.
//

struct DomainsArray: Codable {
    let data: [Domains]
}

struct SingleDomain: Codable {
    let data: Domains
}

struct Domains: Codable {
    let id: String
    let user_id: String
    let domain: String
    let description: String?
    let from_name: String?
    var aliases_count: Int?
    let default_recipient: Recipients?
    var active: Bool
    var catch_all: Bool
    let domain_verified_at: String?
    let domain_mx_validated_at: String?
    let domain_sending_verified_at: String?
    let created_at: String
    let updated_at: String
}

public struct DomainOptions: Codable {
    public let data, sharedDomains: [String]
    public let defaultAliasDomain, defaultAliasFormat: String
}
