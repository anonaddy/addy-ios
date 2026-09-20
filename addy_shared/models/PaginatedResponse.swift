//
//  PaginatedResponse.swift
//  addy_shared
//
//  Created by Stijn van de Water on 23/08/2026.
//

import Foundation

public struct Meta: Codable, Sendable {
    public let current_page: Int
    let from: Int?
    public let last_page: Int
    let links: [Link]
    let path: String
    let per_page: Int
    let to: Int?
    public let total: Int
}

struct Link: Codable, Sendable {
    let url: String?
    let label: String
    let active: Bool
}

public struct Links: Codable, Sendable {
    let first: String?
    let last: String?
    let prev: String?
    let next: String?
}

public struct PaginatedResponse<T: Codable & Sendable>: Codable, Sendable {
    public var data: [T]
    public var links: Links?
    public var meta: Meta?

    public init(data: [T], links: Links? = nil, meta: Meta? = nil) {
        self.data = data
        self.links = links
        self.meta = meta
    }
}

public struct ArrayResponse<T: Codable & Sendable>: Codable, Sendable {
    public var data: [T]

    public init(data: [T]) {
        self.data = data
    }
}

// Unified response typealiases
public typealias AliasesArray = PaginatedResponse<Aliases>
public typealias BulkAliasesArray = ArrayResponse<Aliases>
public typealias DomainsArray = ArrayResponse<Domains>
public typealias UsernamesArray = ArrayResponse<Usernames>
public typealias LabelsArray = ArrayResponse<Labels>
public typealias BlocklistEntriesArray = PaginatedResponse<BlocklistEntries>
public typealias FailedDeliveriesArray = PaginatedResponse<FailedDeliveries>
public typealias RulesArray = ArrayResponse<Rules>
public typealias AccountNotificationsArray = ArrayResponse<AccountNotifications>
public typealias RecipientsArray = ArrayResponse<Recipients>
