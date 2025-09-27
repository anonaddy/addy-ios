//
//  Login.swift
//  addy_shared
//
//  Created by Stijn van de Water on 25/09/2024.
//

import Foundation

public struct Login: Decodable {
    public let api_key: String
    let name: String
    let created_at: String
    let expires_at: String?
}

// 422
public struct LoginMfaRequired: Decodable {
    let message: String
    public let mfa_key: String
    public let csrf_token: String
}

// 401
struct LoginError: Decodable {
    let message: String
}
