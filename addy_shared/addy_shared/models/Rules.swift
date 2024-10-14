//
//  Rules.swift
//  addy_shared
//
//  Created by Stijn van de Water on 06/06/2024.
//

import Foundation

// The Action struct represents an action with a unique identifier (UUID), type, and value.
public struct Action: Identifiable, Hashable, Codable {
    // The id is a unique identifier for each action. It's a UUID which is a universally unique identifier.
    public var id: UUID
    // The type of the action.
    public var type: String
    // The value of the action.
    public var value: String
    
    // CodingKeys enum is used to specify which keys we want to decode from the JSON.
    // The id is not included because it's not present in the JSON.
    enum CodingKeys: String, CodingKey {
        case type, value
    }
    
    // This initializer is used when creating a new Action.
    // It generates a new UUID for the id.
    public init(type: String, value: String) {
        self.id = UUID()
        self.type = type
        self.value = value
    }
    
    // This initializer is used when decoding an Action from JSON.
    // It generates a new UUID for the id because the id is not present in the JSON.
    // It decodes the type and value from the JSON.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.type = try container.decode(String.self, forKey: .type)
        
        if let boolValue = try? container.decode(Bool.self, forKey: .value) {
            self.value = String(boolValue)
        } else {
            self.value = try container.decode(String.self, forKey: .value)
        }
    }
}



// The Condition struct represents a condition with a unique identifier (UUID), type, match, and values.
public struct Condition: Identifiable, Hashable, Codable {
    // The id is a unique identifier for each condition. It's a UUID which is a universally unique identifier.
    public var id: UUID
    public let type: String
    public let match: String
    public let values: [String]
    
    // CodingKeys enum is used to specify which keys we want to decode from the JSON.
    // The id is not included because it's not present in the JSON.
    enum CodingKeys: String, CodingKey {
        case type, match, values
    }
    
    // This initializer is used when creating a new Condition.
    // It generates a new UUID for the id.
    public init(type: String, match: String, values: [String]) {
        self.id = UUID()
        self.type = type
        self.match = match
        self.values = values
    }
    
    // This initializer is used when decoding a Condition from JSON.
    // It generates a new UUID for the id because the id is not present in the JSON.
    // It decodes the type, match, and values from the JSON.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.type = try container.decode(String.self, forKey: .type)
        self.match = try container.decode(String.self, forKey: .match)
        self.values = try container.decode([String].self, forKey: .values)
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
