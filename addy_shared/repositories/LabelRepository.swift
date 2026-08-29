//
//  LabelRepository.swift
//  addy_shared
//
//  Created by Stijn van de Water on 22/08/2026.
//

import Foundation

/// Protocol defining label CRUD operations.
public protocol LabelRepositoryProtocol: AnyObject, Sendable {
    /// Retrieves all labels with optional search filter.
    func getLabels(filter: String?) async throws -> LabelsArray
    /// Creates a new label.
    func createLabel(label: NewLabel) async throws -> Labels
    /// Updates an existing label's name and color.
    func updateLabel(labelId: String, name: String, colour: String) async throws -> String
    /// Deletes a label by ID.
    func deleteLabel(labelId: String) async throws -> String
}

public extension LabelRepositoryProtocol {
    func getLabels(filter: String? = nil) async throws -> LabelsArray {
        return try await getLabels(filter: filter)
    }
}

/// Repository for managing account labels.
public final class LabelRepository: LabelRepositoryProtocol, @unchecked Sendable {
    public static let shared = LabelRepository()

    private let apiClient: APIClientProtocol

    public init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    public func getLabels(filter: String? = nil) async throws -> LabelsArray {
        var queryItems: [URLQueryItem]? = nil
        if let filter = filter, !filter.isEmpty {
            queryItems = [URLQueryItem(name: "filter[search]", value: filter)]
        }
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_LABELS,
            method: .get,
            queryItems: queryItems
        )
        return try await apiClient.request(endpoint)
    }

    public func createLabel(label: NewLabel) async throws -> Labels {
        let json: [String: Any] = ["name": label.name, "colour": label.colour]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_LABELS,
            method: .post,
            body: jsonData
        )
        let single: SingleLabel = try await apiClient.request(endpoint)
        return single.data
    }

    public func updateLabel(labelId: String, name: String, colour: String) async throws -> String {
        let labelData = try JSONEncoder().encode(UpdateLabel(name: name, colour: colour))
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_LABELS)/\(labelId)",
            method: .patch,
            body: labelData
        )
        let (data, response) = try await apiClient.requestRaw(endpoint)
        if response.statusCode == 200 {
            return String(response.statusCode)
        }
        throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
    }

    public func deleteLabel(labelId: String) async throws -> String {
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_LABELS)/\(labelId)",
            method: .delete
        )
        let (data, response) = try await apiClient.requestRaw(endpoint)
        if response.statusCode == 204 {
            return String(response.statusCode)
        }
        throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
    }
}
