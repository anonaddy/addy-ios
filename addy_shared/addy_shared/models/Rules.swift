//
//  Rules.swift
//  addy_shared
//
//  Created by Stijn van de Water on 06/06/2024.
//

import Foundation

public struct Action: Identifiable, Hashable, Codable {
    public var id: Self { self }

    public var type: String
    public var value: String
    
    public init(type: String, value: String) {
        self.type = type
        self.value = value
    }
}

public struct Condition: Identifiable, Hashable, Codable {
    public var id: Self { self }

    public let type: String
    public let match: String
    public let values: [String]
    
    public init(type: String, match: String, values: [String]) {
        self.type = type
        self.match = match
        self.values = values
    }
}

struct SingleRule: Codable {
    var data: Rules
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
    public var `operator`: String
    public var forwards: Bool
    public var replies: Bool
    public var sends: Bool
    public let active: Bool
    public let applied: Int
    let last_applied: String?
    let created_at: String
    let updated_at: String
    
    // This is all neccesary to be able to init this class
    public init(id: String, user_id: String, name: String, order: Int, conditions: [Condition], actions: [Action], `operator`:String,forwards: Bool, replies: Bool, sends: Bool, active: Bool, applied: Int, last_applied: String?, created_at: String, updated_at: String) {
        self.id = id
        self.user_id = user_id
        self.name = name
        self.order = order
        self.conditions = conditions
        self.actions = actions
        self.`operator` = `operator`
        self.forwards = forwards
        self.replies = replies
        self.sends = sends
        self.active = active
        self.applied = applied
        self.last_applied = last_applied
        self.created_at = created_at
        self.updated_at = updated_at
    }
}
