//
//  Labels.swift
//  addy
//
//  Created by Stijn van de Water on 24/06/2026.
//

import Foundation

public struct LabelsArray: Codable {
    public var data: [Labels]
}

struct SingleLabel: Codable {
    let data: Labels
}

public struct Labels: Codable, Identifiable, Hashable {
    public var id: String
    public var user_id: String
    public var name: String
    public var colour: String
    public var aliases_count: Int?
    public var created_at: String
    public var updated_at: String
}

public struct NewLabel: Codable {
    let name: String
    let colour: String

    public init(name: String, colour: String) {
        self.name = name
        self.colour = colour
    }
}

public struct UpdateLabel: Codable {
    let name: String
    let colour: String

    public init(name: String, colour: String) {
        self.name = name
        self.colour = colour
    }
}
