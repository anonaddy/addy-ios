//
//  UserResource.swift
//  addy_shared
//
//  Created by Stijn van de Water on 07/05/2024.
//

import Foundation

public enum SUBSCRIPTIONS: String {
    case FREE = "free"
    case LITE = "lite"
    case PRO = "pro"
}

struct SingleUserResource: Codable {
    var data: UserResource
}

public struct UserResourceExtended: Codable {
    public var default_recipient_email: String

    // This is all neccesary to be able to init this class

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        default_recipient_email = try container.decode(String.self, forKey: .default_recipient_email)
    }

    public init(default_recipient_email: String) {
        self.default_recipient_email = default_recipient_email
    }
    
    private enum CodingKeys: String, CodingKey {
        case default_recipient_email
    }
}



public struct UserResource: Codable {
    var id: String
    public var username: String
    var from_name: String?
    var email_subject: String?
    var banner_location: String
    var bandwidth: Int64
    var username_count: Int
    var username_limit: Int
    var default_username_id: String
    public var default_recipient_id: String
    var default_alias_domain: String
    var default_alias_format: String
    public var subscription: String?
    var subscription_ends_at: String?
    var bandwidth_limit: Int64
    public var recipient_count: Int
    public var recipient_limit: Int
    var active_domain_count: Int
    var active_domain_limit: Int
    var active_shared_domain_alias_count: Int
    var active_shared_domain_alias_limit: Int
    var active_rule_count: Int
    var active_rule_limit: Int
    public var total_emails_forwarded: Int
    public var total_emails_blocked: Int
    public var total_emails_replied: Int
    public var total_emails_sent: Int
    var total_aliases: Int
    var total_active_aliases: Int
    var total_inactive_aliases: Int
    var total_deleted_aliases: Int
    var created_at: String
    var updated_at: String
    
    
    
    
    public func hasUserFreeSubscription() -> Bool {
        
        // If user has a subscription
        if let userSubscription = subscription {
            // If free
            if userSubscription == SUBSCRIPTIONS.FREE.rawValue {
                return true
            }
        }
        return false;
        
    }
}
