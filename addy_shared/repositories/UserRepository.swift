//
//  UserRepository.swift
//  addy_shared
//
//  Created by Stijn van de Water on 22/08/2026.
//

import Foundation

/// Result of a login attempt.
public enum LoginResult {
    /// Login succeeded, returning login credentials and token.
    case success(Login)
    /// 2FA/MFA is required to complete authentication.
    case mfaRequired(LoginMfaRequired)
}

/// Protocol defining user account, authentication, and subscription operations.
public protocol UserRepositoryProtocol: AnyObject, Sendable {
    /// Retrieves user resource containing account details and quotas.
    func getUserResource() async throws -> UserResource
    /// Validates an API key against a target base URL without changing saved state.
    func verifyApiKey(baseUrl: String, apiKey: String) async throws -> UserResource?
    /// Logs in using username and password.
    func login(baseUrl: String, username: String, password: String, apiExpiration: String) async throws -> LoginResult
    /// Completes MFA login with OTP.
    func loginMfa(baseUrl: String, mfaKey: String, otp: String, apiExpiration: String) async throws -> Login
    /// Registers a new account.
    func registration(username: String, email: String, password: String, apiExpiration: String) async throws -> Void
    /// Verifies registration email using verification query.
    func verifyRegistration(query: String) async throws -> String
    /// Logs out by revoking the active API key on the server.
    func logout() async throws -> Int?
    /// Permanently deletes user account.
    func deleteAccount(password: String) async throws -> String
    /// Retrieves API token expiration and scopes.
    func getApiTokenDetails() async throws -> ApiTokenDetails
    /// Syncs App Store subscription receipt with server.
    func notifyServerForSubscriptionChange(receipt: String) async throws -> UserResource
    /// Caches user resource for widget display.
    func cacheUserResourceForWidget() async -> Bool
}

/// Repository for managing user authentication, registration, profiles, and subscriptions.
public final class UserRepository: UserRepositoryProtocol, @unchecked Sendable {
    public static let shared = UserRepository()

    private let apiClient: APIClientProtocol
    private let encryptedSettingsManager: SettingsManager
    private let loggingHelper: LoggingHelper

    public init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
        self.encryptedSettingsManager = SettingsManager(encrypted: true)
        self.loggingHelper = LoggingHelper()
    }

    public func getUserResource() async throws -> UserResource {
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_ACCOUNT_DETAILS,
            method: .get
        )
        let single: SingleUserResource = try await apiClient.request(endpoint)
        return single.data
    }

    public func verifyApiKey(baseUrl: String, apiKey: String) async throws -> UserResource? {
        AddyIo.API_BASE_URL = baseUrl

        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_ACCOUNT_DETAILS,
            method: .get,
            apiKeyOverride: apiKey
        )

        let (data, response) = try await apiClient.requestRaw(endpoint)
        if response.statusCode == 200 {
            let decoder = JSONDecoder()
            let userResource = try decoder.decode(SingleUserResource.self, from: data)
            return userResource.data
        } else if response.statusCode == 401 {
            return nil
        } else {
            throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
        }
    }

    public func login(baseUrl: String, username: String, password: String, apiExpiration: String) async throws -> LoginResult {
        AddyIo.API_BASE_URL = baseUrl

        let json: [String: Any?] = [
            "username": username,
            "password": password,
            "device_name": "addy.io for iOS",
            "expiration": apiExpiration == "never" ? nil : apiExpiration,
        ]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_LOGIN,
            method: .post,
            body: jsonData
        )

        let (data, response) = try await apiClient.requestRaw(endpoint)
        let decoder = JSONDecoder()

        switch response.statusCode {
        case 200:
            let loginData = try decoder.decode(Login.self, from: data)
            return .success(loginData)
        case 422:
            let mfaData = try decoder.decode(LoginMfaRequired.self, from: data)
            return .mfaRequired(mfaData)
        case 401, 403:
            let errorData = try? decoder.decode(LoginError.self, from: data)
            throw NetworkError.unauthorized(message: errorData?.message ?? "Invalid login credentials")
        default:
            throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
        }
    }

    public func loginMfa(baseUrl: String, mfaKey: String, otp: String, apiExpiration: String) async throws -> Login {
        AddyIo.API_BASE_URL = baseUrl

        let json: [String: Any?] = [
            "mfa_key": mfaKey,
            "otp": otp,
            "device_name": "addy.io for iOS",
            "expiration": apiExpiration == "never" ? nil : apiExpiration,
        ]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_LOGIN_MFA,
            method: .post,
            body: jsonData
        )

        let (data, response) = try await apiClient.requestRaw(endpoint)
        let decoder = JSONDecoder()

        switch response.statusCode {
        case 200:
            return try decoder.decode(Login.self, from: data)
        case 401:
            let errorData = try? decoder.decode(LoginError.self, from: data)
            throw NetworkError.unauthorized(message: errorData?.message ?? "Invalid MFA OTP")
        default:
            throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
        }
    }

    public func registration(username: String, email: String, password: String, apiExpiration: String) async throws -> Void {
        #if DEBUG
            let defaultBaseUrl = String(localized: "dev_base_url")
        #else
            let defaultBaseUrl = String(localized: "default_base_url")
        #endif

        AddyIo.API_BASE_URL = defaultBaseUrl

        let json: [String: Any?] = [
            "username": username,
            "email": email,
            "password": password,
            "device_name": "addy.io for iOS",
            "expiration": apiExpiration == "never" ? nil : apiExpiration,
        ]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_REGISTER,
            method: .post,
            body: jsonData
        )

        let (data, response) = try await apiClient.requestRaw(endpoint)

        switch response.statusCode {
        case 204:
            return
        case 422:
            let errorData = try? JSONDecoder().decode(LoginError.self, from: data)
            throw NetworkError.unprocessableEntity(message: errorData?.message ?? "Registration validation failed")
        default:
            throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
        }
    }

    public func verifyRegistration(query: String) async throws -> String {
        #if DEBUG
            let defaultBaseUrl = String(localized: "dev_base_url")
        #else
            let defaultBaseUrl = String(localized: "default_base_url")
        #endif

        AddyIo.API_BASE_URL = defaultBaseUrl

        let endpoint = Endpoint(
            urlString: "\(AddyIo.API_URL_LOGIN_VERIFY)?\(query)",
            method: .post
        )

        let (data, response) = try await apiClient.requestRaw(endpoint)

        switch response.statusCode {
        case 200:
            let loginData = try JSONDecoder().decode(Login.self, from: data)
            return loginData.api_key
        case 403, 404, 422:
            let errorData = try? JSONDecoder().decode(LoginError.self, from: data)
            throw NetworkError.unauthorized(message: errorData?.message ?? "Registration verification failed")
        default:
            throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
        }
    }

    public func logout() async throws -> Int? {
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_LOGOUT,
            method: .post
        )
        let (_, response) = try await apiClient.requestRaw(endpoint)
        if response.statusCode == 204 {
            return response.statusCode
        }
        return nil
    }

    public func deleteAccount(password: String) async throws -> String {
        let json: [String: Any] = ["password": password]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_DELETE_ACCOUNT,
            method: .post,
            body: jsonData
        )
        let (data, response) = try await apiClient.requestRaw(endpoint)
        if response.statusCode == 204 || response.statusCode == 422 {
            return String(response.statusCode)
        }
        throw apiClient.mapResponseError(response: response, data: data, requestURL: endpoint.urlString)
    }

    public func getApiTokenDetails() async throws -> ApiTokenDetails {
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_API_TOKEN_DETAILS,
            method: .get
        )
        return try await apiClient.request(endpoint)
    }

    public func notifyServerForSubscriptionChange(receipt: String) async throws -> UserResource {
        let json: [String: Any] = ["receiptData": receipt, "platform": "apple"]
        let jsonData = try JSONSerialization.data(withJSONObject: json)
        let endpoint = Endpoint(
            urlString: AddyIo.API_URL_NOTIFY_SUBSCRIPTION,
            method: .post,
            body: jsonData
        )
        let single: SingleUserResource = try await apiClient.request(endpoint)
        return single.data
    }

    public func cacheUserResourceForWidget() async -> Bool {
        do {
            let userResource = try await getUserResource()
            let data = try JSONEncoder().encode(userResource)
            if let jsonString = String(data: data, encoding: .utf8) {
                encryptedSettingsManager.putSettingsString(key: .userResource, string: jsonString)
                return true
            }
            return false
        } catch {
            let errorMessage = "Error: \(error.localizedDescription)"
            loggingHelper.addLog(
                importance: .critical,
                error: errorMessage,
                method: "cacheUserResourceForWidget",
                extra: nil
            )
            return false
        }
    }
}
