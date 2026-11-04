//
//  AppMaintenanceRepository.swift
//  addy_shared
//
//  Created by Stijn van de Water on 22/08/2026.
//

#if canImport(FeedKit)
import FeedKit
#endif
import Foundation

/// Protocol defining application maintenance, versioning, charts, and notification checks.
public protocol AppMaintenanceRepositoryProtocol: AnyObject, Sendable {
    /// Fetches the version of the connected addy.io instance.
    func getAddyIoInstanceVersion() async throws -> Version
#if canImport(FeedKit)
    /// Fetches GitHub release tags via RSS feed.
    func getGithubTags() async throws -> AtomFeed?
#endif
    /// Fetches all system/account notifications.
    func getAllAccountNotifications() async throws -> AccountNotificationsArray
    /// Caches account notifications count for background service and widgets.
    func cacheAccountNotificationsCountForWidgetAndBackgroundService() async -> Bool
    /// Fetches the status of addy.io services from status.addy.io/json.
    func getServiceStatus(url: String) async throws -> ServiceStatus
    /// Test method to query service status or verify decoding with mock JSON.
    func testServiceStatus(mockJson: String?) async throws -> ServiceStatus
}

public extension AppMaintenanceRepositoryProtocol {
    func getServiceStatus(url: String = AddyIo.STATUS_JSON_URL) async throws -> ServiceStatus {
        try await getServiceStatus(url: url)
    }

    func testServiceStatus(mockJson: String? = nil) async throws -> ServiceStatus {
        try await testServiceStatus(mockJson: mockJson)
    }
}

/// Repository for application maintenance, version checking, and system notifications.
public final class AppMaintenanceRepository: AppMaintenanceRepositoryProtocol, @unchecked Sendable {
    public static let shared = AppMaintenanceRepository()

    private let apiClient: APIClientProtocol
    private let encryptedSettingsManager: SettingsManager
    private let loggingHelper: LoggingHelper

    public init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
        self.encryptedSettingsManager = SettingsManager(encrypted: true)
        self.loggingHelper = LoggingHelper()
    }

    public func getAddyIoInstanceVersion() async throws -> Version {
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_APP_VERSION,
            method: .get
        )
        let (data, response) = try await apiClient.requestRaw(endpoint)
        switch response.statusCode {
        case 200:
            let decoder = JSONDecoder()
            return try decoder.decode(Version.self, from: data)
        case 404:
            // Version <0.6.0
            return Version(major: 0, minor: 0, patch: 0, version: "")
        default:
            throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
        }
    }

#if canImport(FeedKit)
    public func getGithubTags() async throws -> AtomFeed? {
        do {
            return try await AtomFeed(urlString: AddyIo.GITHUB_TAGS_RSS_FEED)
        } catch {
            let errorMessage = "Error: \(error.localizedDescription)"
            loggingHelper.addLog(
                importance: .critical,
                error: errorMessage,
                method: #function,
                extra: nil
            )
            throw error
        }
    }
#endif

    public func getAllAccountNotifications() async throws -> AccountNotificationsArray {
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_ACCOUNT_NOTIFICATIONS,
            method: .get
        )
        return try await apiClient.request(endpoint)
    }

    public func cacheAccountNotificationsCountForWidgetAndBackgroundService() async -> Bool {
        do {
            let result = try await getAllAccountNotifications()
            encryptedSettingsManager.putSettingsInt(
                key: .backgroundServiceCacheAccountNotificationsCountPrevious,
                int: encryptedSettingsManager.getSettingsInt(key: .backgroundServiceCacheAccountNotificationsCount)
            )
            encryptedSettingsManager.putSettingsInt(
                key: .backgroundServiceCacheAccountNotificationsCount,
                int: result.data.count
            )
            return true
        } catch {
            return false
        }
    }

    public func getServiceStatus(url: String = AddyIo.STATUS_JSON_URL) async throws -> ServiceStatus {
        let endpoint = Endpoint(
            urlString: url,
            method: .get
        )
        let (data, response) = try await apiClient.requestRaw(endpoint)
        guard (200...299).contains(response.statusCode) else {
            throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
        }
        let decoder = JSONDecoder()
        return try decoder.decode(ServiceStatus.self, from: data)
    }

    @discardableResult
    public func testServiceStatus(mockJson: String? = nil) async throws -> ServiceStatus {
        if let jsonString = mockJson {
            guard let data = jsonString.data(using: .utf8) else {
                throw NSError(domain: "ServiceStatusTest", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid mock JSON string"])
            }
            let decoder = JSONDecoder()
            return try decoder.decode(ServiceStatus.self, from: data)
        }
        return try await getServiceStatus()
    }
}
