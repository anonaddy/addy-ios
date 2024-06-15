//
//  ApiTokenDetails.swift
//  addy_shared
//
//  Created by Stijn van de Water on 15/06/2024.
//

import Foundation

public struct ApiTokenDetails: Decodable {
    public let created_at: String
    public let expires_at: String?
    public let name: String
}

