//
//  RulesRepository.swift
//  addy_shared
//
//  Created by Stijn van de Water on 22/08/2026.
//

import Foundation

/// Protocol defining rules operations.
public protocol RulesRepositoryProtocol: AnyObject, Sendable {
    /// Retrieves all configured routing and action rules.
    func getRules() async throws -> RulesArray
    /// Retrieves a specific rule by ID.
    func getRule(ruleId: String) async throws -> Rules
    /// Creates a new rule.
    func createRule(rule: Rules) async throws -> Rules
    /// Updates an existing rule.
    func updateRule(ruleId: String, rule: Rules) async throws -> String
    /// Reorders rules by sending an ordered array of rule objects.
    func reorderRules(rules: [Rules]) async throws -> String
    /// Deletes a rule by ID.
    func deleteRule(ruleId: String) async throws -> String
    /// Activates a rule by ID.
    func activateRule(ruleId: String) async throws -> Rules
    /// Deactivates a rule by ID.
    func deactivateRule(ruleId: String) async throws -> String
}

/// Repository for managing routing rules.
public final class RulesRepository: RulesRepositoryProtocol, @unchecked Sendable {
    public static let shared = RulesRepository()

    private let apiClient: APIClientProtocol

    public init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    public func getRules() async throws -> RulesArray {
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_RULES,
            method: .get
        )
        return try await apiClient.request(endpoint)
    }

    public func getRule(ruleId: String) async throws -> Rules {
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_RULES)/\(ruleId)",
            method: .get
        )
        let single: SingleRule = try await apiClient.request(endpoint)
        return single.data
    }

    public func createRule(rule: Rules) async throws -> Rules {
        let ruleData = try JSONEncoder().encode(rule)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_RULES,
            method: .post,
            body: ruleData
        )
        let single: SingleRule = try await apiClient.request(endpoint)
        return single.data
    }

    public func updateRule(ruleId: String, rule: Rules) async throws -> String {
        let ruleData = try JSONEncoder().encode(rule)
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_RULES)/\(ruleId)",
            method: .patch,
            body: ruleData
        )
        let (data, response) = try await apiClient.requestRaw(endpoint)
        if response.statusCode == 200 {
            return String(response.statusCode)
        }
        throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
    }

    public func reorderRules(rules: [Rules]) async throws -> String {
        let array: [String] = rules.map { $0.id }
        let json: [String: Any] = ["ids": array]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_REORDER_RULES,
            method: .post,
            body: jsonData
        )
        let (data, response) = try await apiClient.requestRaw(endpoint)
        if response.statusCode == 200 {
            return String(response.statusCode)
        }
        throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
    }

    public func deleteRule(ruleId: String) async throws -> String {
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_RULES)/\(ruleId)",
            method: .delete
        )
        let (data, response) = try await apiClient.requestRaw(endpoint)
        if response.statusCode == 204 {
            return String(response.statusCode)
        }
        throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
    }

    public func activateRule(ruleId: String) async throws -> Rules {
        let json: [String: Any] = ["id": ruleId]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_ACTIVE_RULES,
            method: .post,
            body: jsonData
        )
        let single: SingleRule = try await apiClient.request(endpoint)
        return single.data
    }

    public func deactivateRule(ruleId: String) async throws -> String {
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_ACTIVE_RULES)/\(ruleId)",
            method: .delete
        )
        let (data, response) = try await apiClient.requestRaw(endpoint)
        if response.statusCode == 204 {
            return String(response.statusCode)
        }
        throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
    }
}
