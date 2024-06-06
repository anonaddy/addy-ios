//
//  Rules.swift
//  addy_shared
//
//  Created by Stijn van de Water on 06/06/2024.
//

import Foundation

public struct Action: Codable {
    public let type: String
    public let value: String
}

public struct Condition: Codable {
    public let type: String
    public let match: String
    public let values: [String]
}

struct SingleRule: Codable {
    let data: Rules
}
 
public struct RulesArray: Codable {
    public var data: [Rules]
}

public struct Rules: Identifiable, Codable {
    public let id: String
    let user_id: String
    public var name: String
    let order: Int
    public var conditions: [Condition]
    public var actions: [Action]
    var `operator`: String
    var forwards: Bool
    var replies: Bool
    var sends: Bool
    let active: Bool
    let created_at: String
    let updated_at: String
}
