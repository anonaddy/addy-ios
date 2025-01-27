//
//  FailedDeliveries.swift
//  addy_shared
//
//  Created by Stijn van de Water on 03/06/2024.
//

import Foundation

public struct FailedDeliveriesArray: Codable {
    public var data: [FailedDeliveries]
}

struct SingleFailedDelivery: Codable {
    let data: FailedDeliveries
}

public struct FailedDeliveries:Identifiable, Codable {
    public let id: String
    let user_id: String
    let recipient_id: String?
    public let recipient_email: String?
    let alias_id: String?
    public let alias_email: String?
    public let bounce_type: String
    public let remote_mta: String
    public let sender: String?
    let email_type: String
    let status: String
    public let code: String
    public let is_stored: Bool
    public let attempted_at: String
    public let created_at: String
    let updated_at: String
}
