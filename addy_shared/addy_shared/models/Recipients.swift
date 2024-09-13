//
//  Recipients.swift
//  addy_shared
//
//  Created by Stijn van de Water on 08/05/2024.
//

public struct RecipientsArray:Codable {
    let data: [Recipients]
}

struct SingleRecipient:Codable {
    let data: Recipients
}

public struct Recipients:Identifiable, Codable, Equatable, Hashable {
    public let id: String
    let user_id: String
    public let email: String
    public var can_reply_send: Bool
    public var should_encrypt: Bool
    public var inline_encryption: Bool
    public var protected_headers: Bool
    public var fingerprint: String?
    public let email_verified_at: String?
    public var aliases_count: Int? // Could be nil as it does not come with a specific alias->recipients endpoint
    public let created_at: String
    public let updated_at: String
}
