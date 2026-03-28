//
//  FailedDeliveries.swift
//  addy_shared
//
//  Created by Stijn van de Water on 03/06/2024.
//

import Foundation

public struct FailedDeliveriesArray: Codable {
    public var data: [FailedDeliveries]
    public var links: Links?
    public var meta: Meta?
}

struct SingleFailedDelivery: Codable {
    let data: FailedDeliveries
}

public struct FailedDeliveries: Identifiable, Codable {
    public let id: String
    let user_id: String
    let recipient_id: String?
    public let recipient_email: String?
    let alias_id: String?
    public let alias_email: String?
    public let bounce_type: String
    public let remote_mta: String
    public let sender: String?
    public let email_type: String
    let status: String
    public let code: String
    public let is_stored: Bool
    public let quarantined: Bool
    public let resent: Bool
    public let attempted_at: String
    public let created_at: String
    let updated_at: String

    public func getEmailTypeLabel() -> String {
        switch self.email_type {
        case "F":
            return String(localized: "forwarded", bundle: Bundle(for: SharedData.self))
        case "R":
            return String(localized: "replies", bundle: Bundle(for: SharedData.self))
        case "S":
            return String(localized: "sent", bundle: Bundle(for: SharedData.self))
        case "RP":
            return String(localized: "reset_password", bundle: Bundle(for: SharedData.self))
        case "FDN":
            return String(localized: "failed_delivery", bundle: Bundle(for: SharedData.self))
        case "DMI":
            return String(localized: "domain_mx_invalid", bundle: Bundle(for: SharedData.self))
        case "DRU":
            return String(localized: "default_recipient_updated", bundle: Bundle(for: SharedData.self))
        case "NRV":
            return String(localized: "new_recipient_verified", bundle: Bundle(for: SharedData.self))
        case "FLA":
            return String(localized: "failed_login_attempt", bundle: Bundle(for: SharedData.self))
        case "TES":
            return String(localized: "token_expiring_soon", bundle: Bundle(for: SharedData.self))
        case "UR":
            return String(localized: "username_reminder", bundle: Bundle(for: SharedData.self))
        case "VR":
            return String(localized: "verify_recipient", bundle: Bundle(for: SharedData.self))
        case "VU":
            return String(localized: "verify_user", bundle: Bundle(for: SharedData.self))
        case "DRSA":
            return String(localized: "disallowed_reply_send_attempt", bundle: Bundle(for: SharedData.self))
        case "DUS":
            return String(localized: "domain_unverified_for_sending", bundle: Bundle(for: SharedData.self))
        case "GKE":
            return String(localized: "pgp_key_expired", bundle: Bundle(for: SharedData.self))
        case "NBL":
            return String(localized: "near_bandwidth_limit", bundle: Bundle(for: SharedData.self))
        case "RSL":
            return String(localized: "reached_reply_send_limit", bundle: Bundle(for: SharedData.self))
        case "SRSA":
            return String(localized: "spam_reply_send_attempt", bundle: Bundle(for: SharedData.self))
        case "AIF":
            return String(localized: "aliases_import_finished", bundle: Bundle(for: SharedData.self))
        default:
            return String(localized: "forwarded", bundle: Bundle(for: SharedData.self))
        }
    }
}

