//
//  UsernameRepository.swift
//  addy_shared
//
//  Created by Stijn van de Water on 22/08/2026.
//

import Foundation

/// Protocol defining additional username management operations.
public protocol UsernameRepositoryProtocol: AnyObject, Sendable {
    /// Retrieves all usernames.
    func getUsernames() async throws -> UsernamesArray
    /// Retrieves details for a specific username.
    func getUsername(usernameId: String) async throws -> Usernames
    /// Adds a new username.
    func addUsername(username: String) async throws -> Usernames
    /// Deletes a username by ID.
    func deleteUsername(usernameId: String) async throws -> String
    /// Activates a username.
    func activateUsername(usernameId: String) async throws -> Usernames
    /// Deactivates a username.
    func deactivateUsername(usernameId: String) async throws -> String
    /// Enables catch-all on a username.
    func enableCatchAll(usernameId: String) async throws -> Usernames
    /// Disables catch-all on a username.
    func disableCatchAll(usernameId: String) async throws -> String
    /// Enables login using this username.
    func enableCanLogin(usernameId: String) async throws -> Usernames
    /// Disables login using this username.
    func disableCanLogin(usernameId: String) async throws -> String
    /// Updates username description.
    func updateDescription(usernameId: String, description: String?) async throws -> Usernames
    /// Updates username default from name.
    func updateFromName(usernameId: String, fromName: String?) async throws -> Usernames
    /// Updates username auto-create regex pattern.
    func updateAutoCreateRegex(usernameId: String, autoCreateRegex: String?) async throws -> Usernames
    /// Updates username default recipient.
    func updateDefaultRecipient(usernameId: String, recipientId: String?) async throws -> Usernames
}

public extension UsernameRepositoryProtocol {
    func updateDescription(usernameId: String, description: String? = nil) async throws -> Usernames {
        return try await updateDescription(usernameId: usernameId, description: description)
    }

    func updateFromName(usernameId: String, fromName: String? = nil) async throws -> Usernames {
        return try await updateFromName(usernameId: usernameId, fromName: fromName)
    }

    func updateAutoCreateRegex(usernameId: String, autoCreateRegex: String? = nil) async throws -> Usernames {
        return try await updateAutoCreateRegex(usernameId: usernameId, autoCreateRegex: autoCreateRegex)
    }

    func updateDefaultRecipient(usernameId: String, recipientId: String? = nil) async throws -> Usernames {
        return try await updateDefaultRecipient(usernameId: usernameId, recipientId: recipientId)
    }
}

/// Repository for managing additional usernames.
public final class UsernameRepository: UsernameRepositoryProtocol, @unchecked Sendable {
    public static let shared = UsernameRepository()

    private let apiClient: APIClientProtocol

    public init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    public func getUsernames() async throws -> UsernamesArray {
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_USERNAMES,
            method: .get
        )
        return try await apiClient.request(endpoint)
    }

    public func getUsername(usernameId: String) async throws -> Usernames {
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_USERNAMES)/\(usernameId)",
            method: .get
        )
        let single: SingleUsername = try await apiClient.request(endpoint)
        return single.data
    }

    public func addUsername(username: String) async throws -> Usernames {
        let json: [String: Any] = ["username": username]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_USERNAMES,
            method: .post,
            body: jsonData
        )
        let single: SingleUsername = try await apiClient.request(endpoint)
        return single.data
    }

    public func deleteUsername(usernameId: String) async throws -> String {
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_USERNAMES)/\(usernameId)",
            method: .delete
        )
        let (data, response) = try await apiClient.requestRaw(endpoint)
        if response.statusCode == 204 {
            return String(response.statusCode)
        }
        throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
    }

    public func activateUsername(usernameId: String) async throws -> Usernames {
        let json: [String: Any] = ["id": usernameId]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_ACTIVE_USERNAMES,
            method: .post,
            body: jsonData
        )
        let single: SingleUsername = try await apiClient.request(endpoint)
        return single.data
    }

    public func deactivateUsername(usernameId: String) async throws -> String {
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_ACTIVE_USERNAMES)/\(usernameId)",
            method: .delete
        )
        let (data, response) = try await apiClient.requestRaw(endpoint)
        if response.statusCode == 204 {
            return String(response.statusCode)
        }
        throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
    }

    public func enableCatchAll(usernameId: String) async throws -> Usernames {
        let json: [String: Any] = ["id": usernameId]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_CATCH_ALL_USERNAMES,
            method: .post,
            body: jsonData
        )
        let single: SingleUsername = try await apiClient.request(endpoint)
        return single.data
    }

    public func disableCatchAll(usernameId: String) async throws -> String {
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_CATCH_ALL_USERNAMES)/\(usernameId)",
            method: .delete
        )
        let (data, response) = try await apiClient.requestRaw(endpoint)
        if response.statusCode == 204 {
            return String(response.statusCode)
        }
        throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
    }

    public func enableCanLogin(usernameId: String) async throws -> Usernames {
        let json: [String: Any] = ["id": usernameId]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_CAN_LOGIN_USERNAMES,
            method: .post,
            body: jsonData
        )
        let single: SingleUsername = try await apiClient.request(endpoint)
        return single.data
    }

    public func disableCanLogin(usernameId: String) async throws -> String {
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_CAN_LOGIN_USERNAMES)/\(usernameId)",
            method: .delete
        )
        let (data, response) = try await apiClient.requestRaw(endpoint)
        if response.statusCode == 204 {
            return String(response.statusCode)
        }
        throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
    }

    public func updateDescription(usernameId: String, description: String?) async throws -> Usernames {
        let json: [String: Any?] = ["description": description]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_USERNAMES)/\(usernameId)",
            method: .patch,
            body: jsonData
        )
        let single: SingleUsername = try await apiClient.request(endpoint)
        return single.data
    }

    public func updateFromName(usernameId: String, fromName: String?) async throws -> Usernames {
        let json: [String: Any?] = ["from_name": fromName]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_USERNAMES)/\(usernameId)",
            method: .patch,
            body: jsonData
        )
        let single: SingleUsername = try await apiClient.request(endpoint)
        return single.data
    }

    public func updateAutoCreateRegex(usernameId: String, autoCreateRegex: String?) async throws -> Usernames {
        let json: [String: Any?] = ["auto_create_regex": autoCreateRegex]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_USERNAMES)/\(usernameId)",
            method: .patch,
            body: jsonData
        )
        let single: SingleUsername = try await apiClient.request(endpoint)
        return single.data
    }

    public func updateDefaultRecipient(usernameId: String, recipientId: String?) async throws -> Usernames {
        let json: [String: Any?] = ["default_recipient": recipientId]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_USERNAMES)/\(usernameId)/default-recipient",
            method: .patch,
            body: jsonData
        )
        let single: SingleUsername = try await apiClient.request(endpoint)
        return single.data
    }
}
