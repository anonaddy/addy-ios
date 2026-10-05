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

    enum CodingKeys: String, CodingKey {
        case ids
        case message
        case data
    }

    public init(ids: [String]? = nil, message: String? = nil) {
        self.ids = ids
        self.message = message
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.data), let dataContainer = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data) {
            self.ids = try dataContainer.decodeIfPresent([String].self, forKey: .ids)
            self.message = try dataContainer.decodeIfPresent(String.self, forKey: .message)
        } else {
            self.ids = try container.decodeIfPresent([String].self, forKey: .ids)
            self.message = try container.decodeIfPresent(String.self, forKey: .message)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(ids, forKey: .ids)
        try container.encodeIfPresent(message, forKey: .message)
    }
}
