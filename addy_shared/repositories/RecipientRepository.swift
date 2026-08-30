//
//  RecipientRepository.swift
//  addy_shared
//
//  Created by Stijn van de Water on 22/08/2026.
//

import Foundation

/// Protocol defining recipient management, GPG encryption, and reply/send permissions.
public protocol RecipientRepositoryProtocol: AnyObject, Sendable {
    /// Retrieves recipients with optional verified-only filter.
    func getRecipients(verifiedOnly: Bool) async throws -> [Recipients]
    /// Retrieves a specific recipient by ID.
    func getRecipient(recipientId: String) async throws -> Recipients
    /// Adds a new recipient email address.
    func addRecipient(address: String) async throws -> Recipients
    /// Deletes a recipient by ID.
    func deleteRecipient(recipientId: String) async throws -> String
    /// Resends verification email to a recipient.
    func resendVerificationEmail(recipientId: String) async throws -> String
    /// Activates a recipient.
    func activateRecipient(recipientId: String) async throws -> Recipients
    /// Deactivates a recipient.
    func deactivateRecipient(recipientId: String) async throws -> String
    /// Allows recipient to reply and send emails.
    func allowReplySend(recipientId: String) async throws -> Recipients
    /// Disallows recipient from replying and sending emails.
    func disallowReplySend(recipientId: String) async throws -> String
    /// Enables PGP encryption for recipient.
    func enableEncryption(recipientId: String) async throws -> Recipients
    /// Disables PGP encryption for recipient.
    func disableEncryption(recipientId: String) async throws -> String
    /// Adds a public GPG encryption key for recipient.
    func addEncryptionKey(recipientId: String, keyData: String) async throws -> Recipients
    /// Removes the public GPG encryption key for recipient.
    func removeEncryptionKey(recipientId: String) async throws -> String
    /// Enables protected headers for encrypted emails.
    func enableProtectedHeaders(recipientId: String) async throws -> Recipients
    /// Disables protected headers for encrypted emails.
    func disableProtectedHeaders(recipientId: String) async throws -> String
    /// Enables PGP/Inline mode for recipient.
    func enablePgpInline(recipientId: String) async throws -> Recipients
    /// Disables PGP/Inline mode for recipient.
    func disablePgpInline(recipientId: String) async throws -> String
    /// Enables removing PGP keys from email body.
    func enableRemovePgpKeys(recipientId: String) async throws -> Recipients
    /// Disables removing PGP keys from email body.
    func disableRemovePgpKeys(recipientId: String) async throws -> String
    /// Enables removing PGP signatures from email body.
    func enableRemovePgpSignatures(recipientId: String) async throws -> Recipients
    /// Disables removing PGP signatures from email body.
    func disableRemovePgpSignatures(recipientId: String) async throws -> String
    /// Updates recipient description.
    func updateDescription(recipientId: String, description: String?) async throws -> Recipients
}

public extension RecipientRepositoryProtocol {
    func getRecipients(verifiedOnly: Bool = false) async throws -> [Recipients] {
        return try await getRecipients(verifiedOnly: verifiedOnly)
    }

    func updateDescription(recipientId: String, description: String? = nil) async throws -> Recipients {
        return try await updateDescription(recipientId: recipientId, description: description)
    }
}

/// Repository for managing recipient email addresses, GPG encryption, and permissions.
public final class RecipientRepository: RecipientRepositoryProtocol, @unchecked Sendable {
    public static let shared = RecipientRepository()

    private let apiClient: APIClientProtocol

    public init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    public func getRecipients(verifiedOnly: Bool = false) async throws -> [Recipients] {
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_RECIPIENTS,
            method: .get
        )
        let recipientsArray: RecipientsArray = try await apiClient.request(endpoint)
        if verifiedOnly {
            return recipientsArray.data.filter { $0.email_verified_at != nil }
        }
        return recipientsArray.data
    }

    public func getRecipient(recipientId: String) async throws -> Recipients {
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_RECIPIENTS)/\(recipientId)",
            method: .get
        )
        let single: SingleRecipient = try await apiClient.request(endpoint)
        return single.data
    }

    public func addRecipient(address: String) async throws -> Recipients {
        let json: [String: Any] = ["email": address]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_RECIPIENTS,
            method: .post,
            body: jsonData
        )
        let single: SingleRecipient = try await apiClient.request(endpoint)
        return single.data
    }

    public func deleteRecipient(recipientId: String) async throws -> String {
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_RECIPIENTS)/\(recipientId)",
            method: .delete
        )
        let (data, response) = try await apiClient.requestRaw(endpoint)
        if response.statusCode == 204 {
            return String(response.statusCode)
        }
        throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
    }

    public func resendVerificationEmail(recipientId: String) async throws -> String {
        let json: [String: Any] = ["recipient_id": recipientId]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_RECIPIENT_RESEND,
            method: .post,
            body: jsonData
        )
        let (data, response) = try await apiClient.requestRaw(endpoint)
        if response.statusCode == 200 {
            return String(response.statusCode)
        }
        throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
    }

    public func activateRecipient(recipientId: String) async throws -> Recipients {
        let json: [String: Any] = ["id": recipientId]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_ACTIVE_RECIPIENTS,
            method: .post,
            body: jsonData
        )
        let single: SingleRecipient = try await apiClient.request(endpoint)
        return single.data
    }

    public func deactivateRecipient(recipientId: String) async throws -> String {
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_ACTIVE_RECIPIENTS)/\(recipientId)",
            method: .delete
        )
        let (data, response) = try await apiClient.requestRaw(endpoint)
        if response.statusCode == 204 {
            return String(response.statusCode)
        }
        throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
    }

    public func allowReplySend(recipientId: String) async throws -> Recipients {
        let json: [String: Any] = ["id": recipientId]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_ALLOWED_RECIPIENTS,
            method: .post,
            body: jsonData
        )
        let single: SingleRecipient = try await apiClient.request(endpoint)
        return single.data
    }

    public func disallowReplySend(recipientId: String) async throws -> String {
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_ALLOWED_RECIPIENTS)/\(recipientId)",
            method: .delete
        )
        let (data, response) = try await apiClient.requestRaw(endpoint)
        if response.statusCode == 204 {
            return String(response.statusCode)
        }
        throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
    }

    public func enableEncryption(recipientId: String) async throws -> Recipients {
        let json: [String: Any] = ["id": recipientId]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_ENCRYPTED_RECIPIENTS,
            method: .post,
            body: jsonData
        )
        let single: SingleRecipient = try await apiClient.request(endpoint)
        return single.data
    }

    public func disableEncryption(recipientId: String) async throws -> String {
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_ENCRYPTED_RECIPIENTS)/\(recipientId)",
            method: .delete
        )
        let (data, response) = try await apiClient.requestRaw(endpoint)
        if response.statusCode == 204 {
            return String(response.statusCode)
        }
        throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
    }

    public func addEncryptionKey(recipientId: String, keyData: String) async throws -> Recipients {
        let json: [String: Any] = [
            "key_data": keyData,
        ]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_RECIPIENT_KEYS)/\(recipientId)",
            method: .patch,
            body: jsonData
        )
        let single: SingleRecipient = try await apiClient.request(endpoint)
        return single.data
    }

    public func removeEncryptionKey(recipientId: String) async throws -> String {
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_RECIPIENT_KEYS)/\(recipientId)",
            method: .delete
        )
        let (data, response) = try await apiClient.requestRaw(endpoint)
        if response.statusCode == 204 {
            return String(response.statusCode)
        }
        throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
    }

    public func enableProtectedHeaders(recipientId: String) async throws -> Recipients {
        let json: [String: Any] = ["id": recipientId]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_PROTECTED_HEADERS_RECIPIENTS,
            method: .post,
            body: jsonData
        )
        let single: SingleRecipient = try await apiClient.request(endpoint)
        return single.data
    }

    public func disableProtectedHeaders(recipientId: String) async throws -> String {
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_PROTECTED_HEADERS_RECIPIENTS)/\(recipientId)",
            method: .delete
        )
        let (data, response) = try await apiClient.requestRaw(endpoint)
        if response.statusCode == 204 {
            return String(response.statusCode)
        }
        throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
    }

    public func enablePgpInline(recipientId: String) async throws -> Recipients {
        let json: [String: Any] = ["id": recipientId]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_INLINE_ENCRYPTED_RECIPIENTS,
            method: .post,
            body: jsonData
        )
        let single: SingleRecipient = try await apiClient.request(endpoint)
        return single.data
    }

    public func disablePgpInline(recipientId: String) async throws -> String {
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_INLINE_ENCRYPTED_RECIPIENTS)/\(recipientId)",
            method: .delete
        )
        let (data, response) = try await apiClient.requestRaw(endpoint)
        if response.statusCode == 204 {
            return String(response.statusCode)
        }
        throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
    }

    public func enableRemovePgpKeys(recipientId: String) async throws -> Recipients {
        let json: [String: Any] = ["id": recipientId]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_REMOVE_PGP_KEYS_RECIPIENTS,
            method: .post,
            body: jsonData
        )
        let single: SingleRecipient = try await apiClient.request(endpoint)
        return single.data
    }

    public func disableRemovePgpKeys(recipientId: String) async throws -> String {
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_REMOVE_PGP_KEYS_RECIPIENTS)/\(recipientId)",
            method: .delete
        )
        let (data, response) = try await apiClient.requestRaw(endpoint)
        if response.statusCode == 204 {
            return String(response.statusCode)
        }
        throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
    }

    public func enableRemovePgpSignatures(recipientId: String) async throws -> Recipients {
        let json: [String: Any] = ["id": recipientId]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_REMOVE_PGP_SIGNATURES_RECIPIENTS,
            method: .post,
            body: jsonData
        )
        let single: SingleRecipient = try await apiClient.request(endpoint)
        return single.data
    }

    public func disableRemovePgpSignatures(recipientId: String) async throws -> String {
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_REMOVE_PGP_SIGNATURES_RECIPIENTS)/\(recipientId)",
            method: .delete
        )
        let (data, response) = try await apiClient.requestRaw(endpoint)
        if response.statusCode == 204 {
            return String(response.statusCode)
        }
        throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
    }

    public func updateDescription(recipientId: String, description: String?) async throws -> Recipients {
        let json: [String: Any?] = ["description": description]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_RECIPIENTS)/\(recipientId)",
            method: .patch,
            body: jsonData
        )
        let single: SingleRecipient = try await apiClient.request(endpoint)
        return single.data
    }
}
