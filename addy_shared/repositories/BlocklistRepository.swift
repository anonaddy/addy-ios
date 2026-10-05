//
//  BlocklistRepository.swift
//  addy_shared
//
//  Created by Stijn van de Water on 22/08/2026.
//

import Foundation

/// Protocol defining blocklist operations.
public protocol BlocklistRepositoryProtocol: AnyObject, Sendable {
    /// Retrieves paginated blocklist entries with optional filtering and search.
    func getBlocklistEntries(page: Int?, size: Int?, filter: String?, search: String?) async throws -> BlocklistEntriesArray
    /// Adds a new entry to the blocklist.
    func addBlocklistEntry(entry: NewBlocklistEntry) async throws -> BlocklistEntries
    /// Deletes an existing blocklist entry by ID.
    func deleteBlocklistEntry(blocklistId: String) async throws -> String
}

public extension BlocklistRepositoryProtocol {
    func getBlocklistEntries(
        page: Int? = nil,
        size: Int? = 100,
        filter: String? = nil,
        search: String? = nil
    ) async throws -> BlocklistEntriesArray {
        return try await getBlocklistEntries(page: page, size: size, filter: filter, search: search)
    }
}

/// Repository for managing blocklist entries.
public final class BlocklistRepository: BlocklistRepositoryProtocol, @unchecked Sendable {
    public static let shared = BlocklistRepository()

    private let apiClient: APIClientProtocol

    public init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    public func getBlocklistEntries(page: Int? = nil, size: Int? = 100, filter: String? = nil, search: String? = nil) async throws -> BlocklistEntriesArray {
        var queryItems: [URLQueryItem] = []

        if let size = size {
            queryItems.append(URLQueryItem(name: "page[size]", value: "\(size)"))
        }
        if let page = page {
            queryItems.append(URLQueryItem(name: "page[number]", value: "\(page)"))
        }
        if let filter = filter, !filter.isEmpty {
            queryItems.append(URLQueryItem(name: "filter[type]", value: filter))
        }
        if let search = search, !search.isEmpty {
            queryItems.append(URLQueryItem(name: "filter[search]", value: search))
        }

        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_BLOCKLIST,
            method: .get,
            queryItems: queryItems
        )
        return try await apiClient.request(endpoint)
    }

    public func addBlocklistEntry(entry: NewBlocklistEntry) async throws -> BlocklistEntries {
        let json: [String: Any] = ["type": entry.type, "value": entry.value]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_BLOCKLIST,
            method: .post,
            body: jsonData
        )
        let single: SingleBlocklistEntry = try await apiClient.request(endpoint)
        return single.data
    }

    public func deleteBlocklistEntry(blocklistId: String) async throws -> String {
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_BLOCKLIST)/\(blocklistId)",
            method: .delete
        )
        let (data, response) = try await apiClient.requestRaw(endpoint)
        if response.statusCode == 204 {
            return String(response.statusCode)
        }
        throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
    }
}
