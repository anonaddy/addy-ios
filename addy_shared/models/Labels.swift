//
//  Labels.swift
//  addy
//
//  Created by Stijn van de Water on 24/06/2026.
//

import Foundation
struct SingleLabel: Codable, Sendable {
    let data: Labels
}

public struct Labels: Codable, Identifiable, Hashable, Sendable {
    public var id: String
    public var user_id: String
    public var name: String
    public var colour: String
    public var aliases_count: Int?
    public var created_at: String
    public var updated_at: String
}

public struct NewLabel: Codable, Sendable {
    public let name: String
    public let colour: String

    public init(name: String, colour: String) {
        self.name = name
        self.colour = colour
    }
}

public typealias UpdateLabel = NewLabel
