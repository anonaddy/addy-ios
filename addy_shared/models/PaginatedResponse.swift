//
//  PaginatedResponse.swift
//  addy_shared
//
//  Created by Stijn van de Water on 23/08/2026.
//

import Foundation

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
