//
//  Recipients.swift
//  addy_shared
//
//  Created by Stijn van de Water on 08/05/2024.
//

struct RecipientsArray {
    let data: [Recipients]
}

struct SingleRecipient:Codable {
    let data: Recipients
}

public struct Recipients:Codable {
    let id: String
    let user_id: String
    public let email: String
    var can_reply_send: Bool
    var should_encrypt: Bool
    var inline_encryption: Bool
    var protected_headers: Bool
    var fingerprint: String?
    let email_verified_at: String?
    var aliases_count: Int?
    let created_at: String
    let updated_at: String
}
