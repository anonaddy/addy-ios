//
//  Login.swift
//  addy_shared
//
//  Created by Stijn van de Water on 25/09/2024.
//

import Foundation


public struct Login: Decodable {
    public let api_key: String
    public let name: String
    public let created_at: String
    public let expires_at: String?
}

//422
public struct LoginMfaRequired: Decodable {
    public let message: String
    public let mfa_key: String
    public let csrf_token: String
}


//401
public struct LoginError: Decodable {
    public let message: String
}
