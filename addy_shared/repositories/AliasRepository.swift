//
//  AliasRepository.swift
//  addy_shared
//
//  Created by Stijn van de Water on 22/08/2026.
//

import Foundation

/// Protocol defining alias CRUD, filtering, pagination, and toggle operations.
public protocol AliasRepositoryProtocol: AnyObject, Sendable {
    /// Retrieves paginated aliases with sorting and filtering parameters.
    func getAliases(aliasSortFilterRequest: AliasSortFilterRequest, page: Int?, size: Int?, recipient: String?, domain: String?, username: String?) async throws -> AliasesArray
    /// Fetches multiple aliases in a single request by their IDs.
    func bulkGetAliases(aliases: [String]) async throws -> BulkAliasesArray
    /// Retrieves full details for a specific alias by ID.
    func getAlias(aliasId: String) async throws -> Aliases
    /// Creates a new email alias.
    func addAlias(domain: String, description: String, format: String, localPart: String, recipients: [String]?, labelIds: [String]?) async throws -> Aliases
    /// Activates an alias.
    func activateAlias(aliasId: String) async throws -> Aliases
    /// Deactivates an alias.
    func deactivateAlias(aliasId: String) async throws -> String
    /// Restricts forwarding to attached recipients only.
    func activateAttachedRecipientsOnly(aliasId: String) async throws -> Aliases
    /// Allows forwarding to any verified recipient.
    func deactivateAttachedRecipientsOnly(aliasId: String) async throws -> String
    /// Pins an alias to the top of the list.
    func pinAlias(aliasId: String) async throws -> Aliases
    /// Unpins an alias.
    func unpinAlias(aliasId: String) async throws -> String
    /// Restores a soft-deleted alias.
    func restoreAlias(aliasId: String) async throws -> Aliases
    /// Soft-deletes an alias.
    func deleteAlias(aliasId: String) async throws -> String
    /// Permanently removes/forgets a deleted alias.
    func forgetAlias(aliasId: String) async throws -> String
    /// Updates alias description.
    func updateDescription(aliasId: String, description: String?) async throws -> Aliases
    /// Updates alias default from name.
    func updateFromName(aliasId: String, fromName: String?) async throws -> Aliases
    /// Updates recipients attached to this alias.
    func updateRecipients(aliasId: String, recipients: [String]) async throws -> Aliases
    /// Bulk deletes multiple aliases.
    func bulkDeleteAliases(aliasIds: [String]) async throws -> BulkActionResponse
    /// Bulk restores multiple deleted aliases.
    func bulkRestoreAliases(aliasIds: [String]) async throws -> BulkActionResponse
    /// Bulk permanently removes/forgets multiple deleted aliases.
    func bulkForgetAliases(aliasIds: [String]) async throws -> BulkActionResponse
    /// Bulk activates multiple aliases.
    func bulkActivateAliases(aliasIds: [String]) async throws -> BulkActionResponse
    /// Bulk deactivates multiple aliases.
    func bulkDeactivateAliases(aliasIds: [String]) async throws -> BulkActionResponse
    /// Bulk pins multiple aliases.
    func bulkPinAliases(aliasIds: [String]) async throws -> BulkActionResponse
    /// Bulk unpins multiple aliases.
    func bulkUnpinAliases(aliasIds: [String]) async throws -> BulkActionResponse
    /// Bulk updates recipients for multiple aliases.
    func bulkUpdateRecipients(aliasIds: [String], recipientIds: [String]) async throws -> BulkActionResponse
    /// Bulk updates labels assigned to multiple aliases.
    @discardableResult
    func bulkUpdateLabels(aliasIds: [String], labelIds: [String]) async throws -> BulkActionResponse
    /// Caches the most popular aliases locally for widget display.
    func cacheMostPopularAliasesForWidget(amountOfAliasesToCache: Int?) async -> Bool
}

public extension AliasRepositoryProtocol {
    func getAliases(
        aliasSortFilterRequest: AliasSortFilterRequest,
        page: Int? = nil,
        size: Int? = 20,
        recipient: String? = nil,
        domain: String? = nil,
        username: String? = nil
    ) async throws -> AliasesArray {
        return try await getAliases(
            aliasSortFilterRequest: aliasSortFilterRequest,
            page: page,
            size: size,
            recipient: recipient,
            domain: domain,
            username: username
        )
    }

    func addAlias(
        domain: String,
        description: String = "",
        format: String = "uuid",
        localPart: String = "",
        recipients: [String]? = nil,
        labelIds: [String]? = nil
    ) async throws -> Aliases {
        return try await addAlias(
            domain: domain,
            description: description,
            format: format,
            localPart: localPart,
            recipients: recipients,
            labelIds: labelIds
        )
    }

    func cacheMostPopularAliasesForWidget(amountOfAliasesToCache: Int? = 15) async -> Bool {
        return await cacheMostPopularAliasesForWidget(amountOfAliasesToCache: amountOfAliasesToCache)
    }

    func updateDescription(aliasId: String, description: String? = nil) async throws -> Aliases {
        return try await updateDescription(aliasId: aliasId, description: description)
    }

    func updateFromName(aliasId: String, fromName: String? = nil) async throws -> Aliases {
        return try await updateFromName(aliasId: aliasId, fromName: fromName)
    }
}

/// Repository for managing email aliases and alias-related actions.
public final class AliasRepository: AliasRepositoryProtocol, @unchecked Sendable {
    public static let shared = AliasRepository()

    private let apiClient: APIClientProtocol
    private let encryptedSettingsManager: SettingsManager
    private let loggingHelper: LoggingHelper

    public init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
        self.encryptedSettingsManager = SettingsManager(encrypted: true)
        self.loggingHelper = LoggingHelper()
    }

    public func getAliases(
        aliasSortFilterRequest: AliasSortFilterRequest,
        page: Int? = nil,
        size: Int? = 20,
        recipient: String? = nil,
        domain: String? = nil,
        username: String? = nil
    ) async throws -> AliasesArray {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page[size]", value: String(size ?? 20)),
            URLQueryItem(name: "with", value: "labels"),
        ]

        if let sort = aliasSortFilterRequest.sort, !sort.isEmpty {
            queryItems.append(URLQueryItem(name: "sort", value: aliasSortFilterRequest.sortDesc ? "-\(sort)" : sort))
        }

        if let page = page {
            queryItems.append(URLQueryItem(name: "page[number]", value: String(page)))
        }
        if let filter = aliasSortFilterRequest.filter, !filter.isEmpty {
            queryItems.append(URLQueryItem(name: "filter[search]", value: filter))
        }
        if let label = aliasSortFilterRequest.label, !label.isEmpty {
            queryItems.append(URLQueryItem(name: "filter[label]", value: label))
        }
        if aliasSortFilterRequest.onlyActiveAliases {
            queryItems.append(URLQueryItem(name: "filter[active]", value: "true"))
        }
        if aliasSortFilterRequest.onlyInactiveAliases {
            queryItems.append(URLQueryItem(name: "filter[active]", value: "false"))
        }
        if aliasSortFilterRequest.onlyDeletedAliases {
            queryItems.append(URLQueryItem(name: "filter[deleted]", value: "only"))
        }
        if aliasSortFilterRequest.onlyPinnedAliases {
            queryItems.append(URLQueryItem(name: "filter[pinned]", value: "true"))
        }
        if let recipient = recipient, !recipient.isEmpty {
            queryItems.append(URLQueryItem(name: "filter[recipient]", value: recipient))
        }
        if let domain = domain, !domain.isEmpty {
            queryItems.append(URLQueryItem(name: "filter[domain]", value: domain))
        }
        if let username = username, !username.isEmpty {
            queryItems.append(URLQueryItem(name: "filter[username]", value: username))
        }

        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_ALIAS,
            method: .get,
            queryItems: queryItems
        )
        return try await apiClient.request(endpoint)
    }

    public func bulkGetAliases(aliases: [String]) async throws -> BulkAliasesArray {
        let json: [String: Any] = ["aliases": aliases]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_ALIASES_GET_BULK,
            method: .post,
            body: jsonData
        )
        return try await apiClient.request(endpoint)
    }

    public func getAlias(aliasId: String) async throws -> Aliases {
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_ALIAS)/\(aliasId)",
            method: .get
        )
        let single: SingleAlias = try await apiClient.request(endpoint)
        return single.data
    }

    public func addAlias(
        domain: String,
        description: String,
        format: String,
        localPart: String,
        recipients: [String]?,
        labelIds: [String]? = nil
    ) async throws -> Aliases {
        var json: [String: Any?] = [
            "domain": domain,
            "description": description.isEmpty ? nil : description,
            "format": format.isEmpty ? nil : format,
            "local_part": localPart.isEmpty ? nil : localPart,
        ]
        if let recipients = recipients, !recipients.isEmpty {
            json["recipient_ids"] = recipients
        }
        if let labelIds = labelIds, !labelIds.isEmpty {
            json["label_ids"] = labelIds
        }

        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_ALIAS,
            method: .post,
            body: jsonData
        )
        let single: SingleAlias = try await apiClient.request(endpoint)
        return single.data
    }

    public func activateAlias(aliasId: String) async throws -> Aliases {
        let json: [String: Any] = ["id": aliasId]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_ACTIVE_ALIAS,
            method: .post,
            body: jsonData
        )
        let single: SingleAlias = try await apiClient.request(endpoint)
        return single.data
    }

    public func deactivateAlias(aliasId: String) async throws -> String {
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_ACTIVE_ALIAS)/\(aliasId)",
            method: .delete
        )
        let (data, response) = try await apiClient.requestRaw(endpoint)
        if response.statusCode == 204 {
            return String(response.statusCode)
        }
        throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
    }

    public func activateAttachedRecipientsOnly(aliasId: String) async throws -> Aliases {
        let json: [String: Any] = ["id": aliasId]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_ATTACHED_RECIPIENTS_ONLY,
            method: .post,
            body: jsonData
        )
        let single: SingleAlias = try await apiClient.request(endpoint)
        return single.data
    }

    public func deactivateAttachedRecipientsOnly(aliasId: String) async throws -> String {
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_ATTACHED_RECIPIENTS_ONLY)/\(aliasId)",
            method: .delete
        )
        let (data, response) = try await apiClient.requestRaw(endpoint)
        if response.statusCode == 204 {
            return String(response.statusCode)
        }
        throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
    }

    public func pinAlias(aliasId: String) async throws -> Aliases {
        let json: [String: Any] = ["id": aliasId]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_PINNED_ALIASES,
            method: .post,
            body: jsonData
        )
        let single: SingleAlias = try await apiClient.request(endpoint)
        return single.data
    }

    public func unpinAlias(aliasId: String) async throws -> String {
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_PINNED_ALIASES)/\(aliasId)",
            method: .delete
        )
        let (data, response) = try await apiClient.requestRaw(endpoint)
        if response.statusCode == 204 {
            return String(response.statusCode)
        }
        throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
    }

    public func restoreAlias(aliasId: String) async throws -> Aliases {
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_ALIAS)/\(aliasId)/restore",
            method: .patch
        )
        let single: SingleAlias = try await apiClient.request(endpoint)
        return single.data
    }

    public func deleteAlias(aliasId: String) async throws -> String {
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_ALIAS)/\(aliasId)",
            method: .delete
        )
        let (data, response) = try await apiClient.requestRaw(endpoint)
        if response.statusCode == 204 {
            return String(response.statusCode)
        }
        throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
    }

    public func forgetAlias(aliasId: String) async throws -> String {
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_ALIAS)/\(aliasId)/forget",
            method: .delete
        )
        let (data, response) = try await apiClient.requestRaw(endpoint)
        if response.statusCode == 204 {
            return String(response.statusCode)
        }
        throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
    }

    public func updateDescription(aliasId: String, description: String?) async throws -> Aliases {
        let json: [String: Any?] = ["description": description]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_ALIAS)/\(aliasId)",
            method: .patch,
            body: jsonData
        )
        let single: SingleAlias = try await apiClient.request(endpoint)
        return single.data
    }

    public func updateFromName(aliasId: String, fromName: String?) async throws -> Aliases {
        let json: [String: Any?] = ["from_name": fromName]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_ALIAS)/\(aliasId)",
            method: .patch,
            body: jsonData
        )
        let single: SingleAlias = try await apiClient.request(endpoint)
        return single.data
    }

    public func updateRecipients(aliasId: String, recipients: [String]) async throws -> Aliases {
        let json: [String: Any] = [
            "alias_id": aliasId,
            "recipient_ids": recipients,
        ]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_ALIAS_RECIPIENTS,
            method: .post,
            body: jsonData
        )
        let single: SingleAlias = try await apiClient.request(endpoint)
        return single.data
    }

    public func bulkDeleteAliases(aliasIds: [String]) async throws -> BulkActionResponse {
        let json: [String: Any] = ["ids": aliasIds]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_ALIASES_DELETE_BULK,
            method: .post,
            body: jsonData
        )
        return try await apiClient.request(endpoint)
    }

    public func bulkRestoreAliases(aliasIds: [String]) async throws -> BulkActionResponse {
        let json: [String: Any] = ["ids": aliasIds]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_ALIASES_RESTORE_BULK,
            method: .post,
            body: jsonData
        )
        return try await apiClient.request(endpoint)
    }

    public func bulkForgetAliases(aliasIds: [String]) async throws -> BulkActionResponse {
        let json: [String: Any] = ["ids": aliasIds]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_ALIASES_FORGET_BULK,
            method: .post,
            body: jsonData
        )
        return try await apiClient.request(endpoint)
    }

    public func bulkActivateAliases(aliasIds: [String]) async throws -> BulkActionResponse {
        let json: [String: Any] = ["ids": aliasIds]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_ALIASES_ACTIVATE_BULK,
            method: .post,
            body: jsonData
        )
        return try await apiClient.request(endpoint)
    }

    public func bulkDeactivateAliases(aliasIds: [String]) async throws -> BulkActionResponse {
        let json: [String: Any] = ["ids": aliasIds]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_ALIASES_DEACTIVATE_BULK,
            method: .post,
            body: jsonData
        )
        return try await apiClient.request(endpoint)
    }

    public func bulkPinAliases(aliasIds: [String]) async throws -> BulkActionResponse {
        let json: [String: Any] = ["ids": aliasIds]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_ALIASES_PIN_BULK,
            method: .post,
            body: jsonData
        )
        return try await apiClient.request(endpoint)
    }

    public func bulkUnpinAliases(aliasIds: [String]) async throws -> BulkActionResponse {
        let json: [String: Any] = ["ids": aliasIds]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_ALIASES_UNPIN_BULK,
            method: .post,
            body: jsonData
        )
        return try await apiClient.request(endpoint)
    }

    public func bulkUpdateRecipients(aliasIds: [String], recipientIds: [String]) async throws -> BulkActionResponse {
        let json: [String: Any] = [
            "ids": aliasIds,
            "recipient_ids": recipientIds,
        ]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_ALIASES_RECIPIENTS_BULK,
            method: .post,
            body: jsonData
        )
        return try await apiClient.request(endpoint)
    }

    @discardableResult
    public func bulkUpdateLabels(aliasIds: [String], labelIds: [String]) async throws -> BulkActionResponse {
        let json: [String: Any] = [
            "ids": aliasIds,
            "label_ids": labelIds,
            "aliases": aliasIds,
            "labels": labelIds,
        ]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_ALIASES_LABELS_BULK,
            method: .post,
            body: jsonData
        )
        return try await apiClient.request(endpoint)
    }

    public func cacheMostPopularAliasesForWidget(amountOfAliasesToCache: Int? = 15) async -> Bool {
        let aliasSortFilterRequest = AliasSortFilterRequest(
            onlyActiveAliases: true,
            onlyDeletedAliases: false,
            onlyInactiveAliases: false,
            onlyWatchedAliases: false,
            onlyPinnedAliases: false,
            sort: "emails_forwarded",
            sortDesc: true,
            filter: nil,
            label: nil
        )
        do {
            let list = try await getAliases(aliasSortFilterRequest: aliasSortFilterRequest, size: amountOfAliasesToCache)
            let data = try JSONEncoder().encode(list.data)
            if let jsonString = String(data: data, encoding: .utf8) {
                encryptedSettingsManager.putSettingsString(key: .backgroundServiceCacheMostActiveAliasesData, string: jsonString)
                return true
            }
            return false
        } catch {
            let errorMessage = "Error: \(error.localizedDescription)"
            loggingHelper.addLog(
                importance: .critical,
                error: errorMessage,
                method: "cacheMostPopularAliasesForWidget",
                extra: nil
            )
            return false
        }
    }
}
