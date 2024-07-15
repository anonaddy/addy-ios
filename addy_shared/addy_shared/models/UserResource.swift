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


    public init(default_recipient_email: String) {
        self.default_recipient_email = default_recipient_email
    }
}



public struct UserResource: Codable {
    var id: String
    public var username: String
    var from_name: String?
    var email_subject: String?
    var banner_location: String
    public var bandwidth: Int64
    public var username_count: Int
    public var username_limit: Int
    var default_username_id: String
    public var default_recipient_id: String
    public var default_alias_domain: String
    public var default_alias_format: String
    public var subscription: String? // Can be nil on selfhosted
    public var subscription_ends_at: String? // Can be nil on selfhosted
    public var bandwidth_limit: Int64
    public var recipient_count: Int
    public var recipient_limit: Int? // Can be nil on selfhosted
    public var active_domain_count: Int
    public var active_domain_limit: Int? // Can be nil on selfhosted
    var active_shared_domain_alias_count: Int
    var active_shared_domain_alias_limit: Int? // Can be nil on selfhosted
    public var active_rule_count: Int
    public var active_rule_limit: Int? // Can be nil on selfhosted
    public var total_emails_forwarded: Int
    public var total_emails_blocked: Int
    public var total_emails_replied: Int
    public var total_emails_sent: Int
    public var total_aliases: Int
    public var total_active_aliases: Int
    public var total_inactive_aliases: Int
    public var total_deleted_aliases: Int
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
