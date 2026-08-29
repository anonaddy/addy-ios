//
//  FailedDeliveriesRepository.swift
//  addy_shared
//
//  Created by Stijn van de Water on 22/08/2026.
//

import Foundation

/// Protocol defining failed delivery tracking and remediation operations.
public protocol FailedDeliveriesRepositoryProtocol: AnyObject, Sendable {
    /// Retrieves paginated failed deliveries with optional type filter.
    func getFailedDeliveries(page: Int?, size: Int?, filter: String?) async throws -> FailedDeliveriesArray
    /// Downloads the raw .eml payload of a failed delivery.
    func downloadFailedDelivery(failedDeliveryId: String) async throws -> URL
    /// Resends a failed delivery with optional recipient overrides.
    func resendFailedDelivery(failedDeliveryId: String, recipientIds: [String]?) async throws -> String
    /// Deletes a failed delivery record.
    func deleteFailedDelivery(failedDeliveryId: String) async throws -> String
    /// Updates local cache and counts for widget and background notifications.
    func cacheFailedDeliveryCountForWidgetAndBackgroundService(previousId: String?) async -> (Int, String?)?
}

public extension FailedDeliveriesRepositoryProtocol {
    func getFailedDeliveries(page: Int? = nil, size: Int? = 25, filter: String? = nil) async throws -> FailedDeliveriesArray {
        return try await getFailedDeliveries(page: page, size: size, filter: filter)
    }

    func resendFailedDelivery(failedDeliveryId: String, recipientIds: [String]? = nil) async throws -> String {
        return try await resendFailedDelivery(failedDeliveryId: failedDeliveryId, recipientIds: recipientIds)
    }

    func cacheFailedDeliveryCountForWidgetAndBackgroundService(previousId: String? = nil) async -> (Int, String?)? {
        return await cacheFailedDeliveryCountForWidgetAndBackgroundService(previousId: previousId)
    }
}

/// Repository for managing failed deliveries.
public final class FailedDeliveriesRepository: FailedDeliveriesRepositoryProtocol, @unchecked Sendable {
    public static let shared = FailedDeliveriesRepository()

    private let apiClient: APIClientProtocol
    private let settingsManager: SettingsManager

    public init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
        self.settingsManager = SettingsManager(encrypted: false)
    }

    public func getFailedDeliveries(page: Int? = nil, size: Int? = 25, filter: String? = nil) async throws -> FailedDeliveriesArray {
        var queryItems: [URLQueryItem] = []

        if let size = size {
            queryItems.append(URLQueryItem(name: "page[size]", value: "\(size)"))
        }
        if let page = page {
            queryItems.append(URLQueryItem(name: "page[number]", value: "\(page)"))
        }
        if let filter = filter {
            queryItems.append(URLQueryItem(name: "filter[email_type]", value: filter))
        }

        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_FAILED_DELIVERIES,
            method: .get,
            queryItems: queryItems
        )
        return try await apiClient.request(endpoint)
    }

    public func downloadFailedDelivery(failedDeliveryId: String) async throws -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsURL.appendingPathComponent("\(failedDeliveryId).eml")

        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_FAILED_DELIVERIES)/\(failedDeliveryId)/download",
            method: .get
        )
        return try await apiClient.download(endpoint, destination: destinationURL)
    }

    public func resendFailedDelivery(failedDeliveryId: String, recipientIds: [String]? = nil) async throws -> String {
        let json: [String: Any] = ["recipient_ids": recipientIds ?? []]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_FAILED_DELIVERIES)/\(failedDeliveryId)/resend",
            method: .post,
            body: jsonData
        )
        let (data, response) = try await apiClient.requestRaw(endpoint)
        if response.statusCode == 204 {
            return String(response.statusCode)
        }
        throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
    }

    public func deleteFailedDelivery(failedDeliveryId: String) async throws -> String {
        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_FAILED_DELIVERIES)/\(failedDeliveryId)",
            method: .delete
        )
        let (data, response) = try await apiClient.requestRaw(endpoint)
        if response.statusCode == 204 {
            return String(response.statusCode)
        }
        throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
    }

    public func cacheFailedDeliveryCountForWidgetAndBackgroundService(previousId: String?) async -> (Int, String?)? {
        do {
            let filterType = settingsManager.getSettingsString(key: .notifyFailedDeliveriesType) ?? "all"
            let filter = filterType == "all" ? nil : filterType

            let result = try await getFailedDeliveries(size: 25, filter: nil)

            var newDeliveriesCount = 0
            if let previousId = previousId {
                for delivery in result.data {
                    if delivery.id == previousId { break }
                    if filter == nil || delivery.type == filter {
                        newDeliveriesCount += 1
                    }
                }
            } else {
                if let first = result.data.first, filter == nil || first.type == filter {
                    newDeliveriesCount = 1
                }
            }

            return (newDeliveriesCount, result.data.first?.id)
        } catch {
            return nil
        }
    }
}
