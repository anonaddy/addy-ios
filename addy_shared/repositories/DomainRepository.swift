//
//  DomainRepository.swift
//  addy_shared
//
//  Created by Stijn van de Water on 22/08/2026.
//

import Foundation

/// Protocol defining custom domain management operations.
public protocol DomainRepositoryProtocol: AnyObject, Sendable {
    /// Retrieves all custom domains.
    func getDomains() async throws -> DomainsArray
    /// Retrieves details for a specific custom domain.
    func getDomain(domainId: String) async throws -> Domains
    /// Retrieves available default and shared domain options.
    func getDomainOptions() async throws -> DomainOptions
    /// Adds a new custom domain.
    func addDomain(domain: String) async throws -> (domain: Domains?, statusCode: String?, message: String?)
    /// Deletes a custom domain by ID.
    func deleteDomain(domainId: String) async throws -> String
    /// Activates a custom domain.
    func activateDomain(domainId: String) async throws -> Domains
    /// Deactivates a custom domain.
    func deactivateDomain(domainId: String) async throws -> String
    /// Enables catch-all routing on a domain.
    func enableCatchAll(domainId: String) async throws -> Domains
    /// Disables catch-all routing on a domain.
    func disableCatchAll(domainId: String) async throws -> String
    /// Shares domain with family members.
    func shareWithFamily(domainId: String) async throws -> Domains
    /// Stops sharing domain with family members.
    func stopSharingWithFamily(domainId: String) async throws -> String
    /// Updates custom domain description.
    func updateDescription(domainId: String, description: String?) async throws -> Domains
    /// Updates custom domain default from name.
    func updateFromName(domainId: String, fromName: String?) async throws -> Domains
    /// Updates custom domain auto-create regex pattern.
    func updateAutoCreateRegex(domainId: String, autoCreateRegex: String?) async throws -> Domains
    /// Updates custom domain default recipient.
    func updateDefaultRecipient(domainId: String, recipientId: String?) async throws -> Domains
}

public extension DomainRepositoryProtocol {
    func updateDescription(domainId: String, description: String? = nil) async throws -> Domains {
        return try await updateDescription(domainId: domainId, description: description)
    }

    func updateFromName(domainId: String, fromName: String? = nil) async throws -> Domains {
        return try await updateFromName(domainId: domainId, fromName: fromName)
    }

    func updateAutoCreateRegex(domainId: String, autoCreateRegex: String? = nil) async throws -> Domains {
        return try await updateAutoCreateRegex(domainId: domainId, autoCreateRegex: autoCreateRegex)
    }

    func updateDefaultRecipient(domainId: String, recipientId: String? = nil) async throws -> Domains {
        return try await updateDefaultRecipient(domainId: domainId, recipientId: recipientId)
    }
}

/// Repository for managing custom domains and domain options.
public final class DomainRepository: DomainRepositoryProtocol, @unchecked Sendable {
    public static let shared = DomainRepository()

    private let apiClient: APIClientProtocol

    public init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    public func getDomains() async throws -> DomainsArray {
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_DOMAINS,
            method: .get
        )
        return try await apiClient.request(endpoint)
    }

    public func getDomain(domainId: String) async throws -> Domains {
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_DOMAINS)/\(domainId)",
            method: .get
        )
        let single: SingleDomain = try await apiClient.request(endpoint)
        return single.data
    }

    public func getDomainOptions() async throws -> DomainOptions {
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_DOMAIN_OPTIONS,
            method: .get
        )
        return try await apiClient.request(endpoint)
    }

    public func addDomain(domain: String) async throws -> (domain: Domains?, statusCode: String?, message: String?) {
        let json: [String: Any] = ["domain": domain]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_DOMAINS,
            method: .post,
            body: jsonData
        )

        let (data, response) = try await apiClient.requestRaw(endpoint)

        switch response.statusCode {
        case 201:
            let single = try JSONDecoder().decode(SingleDomain.self, from: data)
            return (single.data, "201", nil)
        case 404:
            return (nil, "404", String(data: data, encoding: .utf8))
        default:
            throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
        }
    }

    public func deleteDomain(domainId: String) async throws -> String {
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_DOMAINS)/\(domainId)",
            method: .delete
        )
        let (data, response) = try await apiClient.requestRaw(endpoint)
        if response.statusCode == 204 {
            return String(response.statusCode)
        }
        throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
    }

    public func activateDomain(domainId: String) async throws -> Domains {
        let json: [String: Any] = ["id": domainId]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_ACTIVE_DOMAINS,
            method: .post,
            body: jsonData
        )
        let single: SingleDomain = try await apiClient.request(endpoint)
        return single.data
    }

    public func deactivateDomain(domainId: String) async throws -> String {
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_ACTIVE_DOMAINS)/\(domainId)",
            method: .delete
        )
        let (data, response) = try await apiClient.requestRaw(endpoint)
        if response.statusCode == 204 {
            return String(response.statusCode)
        }
        throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
    }

    public func enableCatchAll(domainId: String) async throws -> Domains {
        let json: [String: Any] = ["id": domainId]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_CATCH_ALL_DOMAINS,
            method: .post,
            body: jsonData
        )
        let single: SingleDomain = try await apiClient.request(endpoint)
        return single.data
    }

    public func disableCatchAll(domainId: String) async throws -> String {
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_CATCH_ALL_DOMAINS)/\(domainId)",
            method: .delete
        )
        let (data, response) = try await apiClient.requestRaw(endpoint)
        if response.statusCode == 204 {
            return String(response.statusCode)
        }
        throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
    }

    public func shareWithFamily(domainId: String) async throws -> Domains {
        let json: [String: Any] = ["id": domainId]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_SHARED_WITH_FAMILY_DOMAINS,
            method: .post,
            body: jsonData
        )
        let single: SingleDomain = try await apiClient.request(endpoint)
        return single.data
    }

    public func stopSharingWithFamily(domainId: String) async throws -> String {
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_SHARED_WITH_FAMILY_DOMAINS)/\(domainId)",
            method: .delete
        )
        let (data, response) = try await apiClient.requestRaw(endpoint)
        if response.statusCode == 204 {
            return String(response.statusCode)
        }
        throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
    }

    public func updateDescription(domainId: String, description: String?) async throws -> Domains {
        let json: [String: Any?] = ["description": description]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_DOMAINS)/\(domainId)",
            method: .patch,
            body: jsonData
        )
        let single: SingleDomain = try await apiClient.request(endpoint)
        return single.data
    }

    public func updateFromName(domainId: String, fromName: String?) async throws -> Domains {
        let json: [String: Any?] = ["from_name": fromName]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_DOMAINS)/\(domainId)",
            method: .patch,
            body: jsonData
        )
        let single: SingleDomain = try await apiClient.request(endpoint)
        return single.data
    }

    public func updateAutoCreateRegex(domainId: String, autoCreateRegex: String?) async throws -> Domains {
        let json: [String: Any?] = ["auto_create_regex": autoCreateRegex]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_DOMAINS)/\(domainId)",
            method: .patch,
            body: jsonData
        )
        let single: SingleDomain = try await apiClient.request(endpoint)
        return single.data
    }

    public func updateDefaultRecipient(domainId: String, recipientId: String?) async throws -> Domains {
        let json: [String: Any?] = ["default_recipient": recipientId]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_DOMAINS)/\(domainId)/default-recipient",
            method: .patch,
            body: jsonData
        )
        let single: SingleDomain = try await apiClient.request(endpoint)
        return single.data
    }
}
