//
//  BulkActionResponse.swift
//  addy_shared
//
//  Created by Stijn van de Water on 29/08/2026.
//

import Foundation

public struct BulkActionResponse: Codable, Sendable {
    public let ids: [String]?
    public let message: String?

    public init(ids: [String]? = nil, message: String? = nil) {
        self.ids = ids
        self.message = message
    }
}
