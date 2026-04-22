//
//  NetworkHelper.swift
//  addy
//
//  Created by Stijn van de Water on 07/05/2024.
//

import FeedKit
import Foundation

public class NetworkHelper {
    private let loggingHelper: LoggingHelper
    private let encryptedSettingsManager: SettingsManager
    private let settingsManager: SettingsManager

    public init() {
        loggingHelper = LoggingHelper()
        encryptedSettingsManager = SettingsManager(encrypted: true)
        settingsManager = SettingsManager(encrypted: false)
        AddyIo.API_BASE_URL = encryptedSettingsManager.getSettingsString(key: .baseUrl) ?? AddyIo.API_BASE_URL
    }

    private func getHeaders(apiKey: String? = nil) -> [String: String] {
        let apiKeyToSend = apiKey ?? encryptedSettingsManager.getSettingsString(key: .apiKey)
        return [
            "Authorization": "Bearer \(apiKeyToSend ?? "")",
            "Content-Type": "application/json",
            "X-Requested-With": "XMLHttpRequest",
            "Accept": "application/json",
            "User-Agent": getUserAgent(),
        ]
    }

    public func createAppResetDueToInvalidAPIKeyNotification() {
        SharedNotificationHelper.createAppResetDueToInvalidAPIKeyNotification()
    }

    private func getUserAgent() -> String {
        let userAgent = "\(SharedData.shared.userAgent.userAgentApplicationID) (\(SharedData.shared.userAgent.userAgentApplicationBuildType)) / \(SharedData.shared.userAgent.userAgentVersion) (\(SharedData.shared.userAgent.userAgentVersionCode))"

        #if DEBUG
            print("User-Agent: \(userAgent)")
        #endif

        return userAgent
    }

    private func performRequest(request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: #function,
                extra: error.failureURLString
            )
            throw error
        }
        return (data, httpResponse)
    }

    private func handleNetworkResponseError(httpResponse: HTTPURLResponse, data: Data, request: URLRequest, method: String = #function) -> Swift.Error {
        if httpResponse.statusCode == 401 {
            loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: method,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")"
            )

            createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            return URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        } else {
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: method,
                extra: ErrorHelper.getErrorMessage(data: data)
            )
            return URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }

    private func logNetworkHelperCall(method: String = #function, file: String = #file, line: Int = #line) {
        #if DEBUG
            print("\(method) called from \((file as NSString).lastPathComponent):\(line)")
        #endif
    }



    /// Using @escaping as logging errors is not a thing before the app is set-up (they cannot be seen)
    public func registration(username: String, email: String, password: String, apiExpiration: String, completion: @escaping (String?) -> Void) async {
        logNetworkHelperCall()

        #if DEBUG
            let defaultBaseUrl = String(localized: "dev_base_url")
        #else
            let defaultBaseUrl = String(localized: "default_base_url")
        #endif

        // Set base URL
        AddyIo.API_BASE_URL = defaultBaseUrl

        let url = URL(string: AddyIo.API_URL_REGISTER)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()

        let json: [String: Any?] = ["username": username,
                                    "email": email,
                                    "password": password,
                                    "device_name": "addy.io for iOS",
                                    "expiration": apiExpiration == "never" ? nil : apiExpiration]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                let error = URLError(.badServerResponse)
                loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: error.localizedDescription,
                    method: "registration",
                    extra: error.failureURLString
                )
                completion(error.localizedDescription)
                return
            }

            switch httpResponse.statusCode {
            case 204: // Successful registration
                completion(nil)
            case 422:
                let decoder = JSONDecoder()
                let addyIoData = try decoder.decode(LoginError.self, from: data)
                completion(addyIoData.message)
            default:
                let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
                print(errorMessage)
                loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "registration",
                    extra: ErrorHelper.getErrorMessage(data: data)
                )
                completion(errorMessage)
            }
        } catch {
            print(error)
            loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "registration",
                extra: nil
            )
            completion(error.localizedDescription)
        }
    }

    /// Using @escaping as logging errors is not a thing before the app is set-up (they cannot be seen)
    public func verifyRegistration(query: String, completion: @escaping (String?, String?) -> Void) async {
        logNetworkHelperCall()

        // Set base URL
        #if DEBUG
            let defaultBaseUrl = String(localized: "dev_base_url")
        #else
            let defaultBaseUrl = String(localized: "default_base_url")
        #endif

        // Set base URL
        AddyIo.API_BASE_URL = defaultBaseUrl

        let url = URL(string: "\(AddyIo.API_URL_LOGIN_VERIFY)?\(query)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                let error = URLError(.badServerResponse)
                loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: error.localizedDescription,
                    method: "verifyRegistration",
                    extra: error.failureURLString
                )
                completion(nil, error.localizedDescription)
                return
            }

            switch httpResponse.statusCode {
            case 200: // Successful verification
                let decoder = JSONDecoder()
                let addyIoData = try decoder.decode(Login.self, from: data)
                completion(addyIoData.api_key, nil)
            case 422, 404, 403: // Successful verification
                let decoder = JSONDecoder()
                let addyIoData = try decoder.decode(LoginError.self, from: data)
                completion(nil, addyIoData.message)
            default:
                let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
                print(errorMessage)
                loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "verifyRegistration",
                    extra: ErrorHelper.getErrorMessage(data: data)
                )
                completion(nil, errorMessage)
            }
        } catch {
            print(error)
            loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "verifyRegistration",
                extra: nil
            )
            completion(nil, error.localizedDescription)
        }
    }

    public func login(baseUrl: String, username: String, password: String, apiExpiration: String, completion: @escaping (Login?, LoginMfaRequired?, String?) -> Void) async {
        logNetworkHelperCall()

        // Set base URL
        AddyIo.API_BASE_URL = baseUrl

        let url = URL(string: AddyIo.API_URL_LOGIN)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()

        let json: [String: Any?] = ["username": username,
                                    "password": password,
                                    "device_name": "addy.io for iOS",
                                    "expiration": apiExpiration == "never" ? nil : apiExpiration]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                let error = URLError(.badServerResponse)
                loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: error.localizedDescription,
                    method: "login",
                    extra: error.failureURLString
                )
                completion(nil, nil, error.localizedDescription)
                return
            }

            switch httpResponse.statusCode {
            case 200: // Successful
                let decoder = JSONDecoder()
                let addyIoData = try decoder.decode(Login.self, from: data)
                completion(addyIoData, nil, nil)
            case 422: // MFA REQUIRED
                let decoder = JSONDecoder()
                let addyIoData = try decoder.decode(LoginMfaRequired.self, from: data)
                completion(nil, addyIoData, nil)
            case 401: // Login data incorrect
                let decoder = JSONDecoder()
                let addyIoData = try decoder.decode(LoginError.self, from: data)
                completion(nil, nil, addyIoData.message)
            case 403: // MFA required but is hardware key and thus not supported OR the email address has not been validated
                let decoder = JSONDecoder()
                let addyIoData = try decoder.decode(LoginError.self, from: data)
                completion(nil, nil, addyIoData.message)
            default:
                let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
                print(errorMessage)
                loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "login",
                    extra: ErrorHelper.getErrorMessage(data: data)
                )
                completion(nil, nil, errorMessage)
            }
        } catch {
            print(error)
            loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "login",
                extra: nil
            )
            completion(nil, nil, error.localizedDescription)
        }
    }

    public func deleteAccount(password: String, completion: @escaping (String) -> Void) async {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_DELETE_ACCOUNT)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["password": password]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        do {
            let (data, httpResponse) = try await performRequest(request: request)

            switch httpResponse.statusCode {
            case 204:
                completion(String(httpResponse.statusCode))
            case 422:
                completion(String(httpResponse.statusCode))
            default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
            }
        } catch {
            print(error)
            loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "login",
                extra: nil
            )
            completion(error.localizedDescription)
        }
    }

    public func logout() async throws -> Int? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_LOGOUT)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 204:
            return httpResponse.statusCode
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    /// Using @escaping as logging errors is not a thing before the app is set-up (they cannot be seen)
    public func loginMfa(baseUrl: String, mfa_key: String, otp: String, xCsrfToken: String, apiExpiration: String, completion: @escaping (Login?, String?) -> Void) async {
        logNetworkHelperCall()

        // Set base URL
        AddyIo.API_BASE_URL = baseUrl

        let url = URL(string: AddyIo.API_URL_LOGIN_MFA)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = [
            "Content-Type": "application/json",
            "X-Requested-With": "XMLHttpRequest",
            "Accept": "application/json",
            "User-Agent": getUserAgent(),
            "X-CSRF-TOKEN": xCsrfToken,
        ]

        let json: [String: Any?] = ["mfa_key": mfa_key,
                                    "otp": otp,
                                    "device_name": "addy.io for iOS",
                                    "expiration": apiExpiration == "never" ? nil : apiExpiration]

        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                let error = URLError(.badServerResponse)
                loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: error.localizedDescription,
                    method: "loginMfa",
                    extra: error.failureURLString
                )
                completion(nil, error.localizedDescription)
                return
            }

            switch httpResponse.statusCode {
            case 200: // Successful
                let decoder = JSONDecoder()
                let addyIoData = try decoder.decode(Login.self, from: data)
                completion(addyIoData, nil)
            case 401: // Invalid mfa_key or mfa_key expired
                let decoder = JSONDecoder()
                let addyIoData = try decoder.decode(LoginError.self, from: data)
                completion(nil, addyIoData.message)
            default:
                let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
                print(errorMessage)
                loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "loginMfa",
                    extra: ErrorHelper.getErrorMessage(data: data)
                )
                completion(nil, errorMessage)
            }
        } catch {
            print(error)
            loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "loginMfa",
                extra: nil
            )
            completion(nil, error.localizedDescription)
        }
    }

    public func verifyApiKey(baseUrl: String, apiKey: String) async throws -> UserResource? {
        logNetworkHelperCall()

        // Set base URL
        AddyIo.API_BASE_URL = baseUrl

        let url = URL(string: AddyIo.API_URL_ACCOUNT_DETAILS)!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders(apiKey: apiKey)

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleUserResource.self, from: data)
            return addyIoData.data
        case 401:
            return nil
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print("Error: \(httpResponse.statusCode) - \(errorMessage)")
            loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "getUserResource",
                extra: ErrorHelper.getErrorMessage(data: data)
            )
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }

    public func getAddyIoInstanceVersion() async throws -> Version? {
        logNetworkHelperCall()
        let url = URL(string: AddyIo.API_URL_APP_VERSION)!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            return try decoder.decode(Version.self, from: data)
        case 404:
            // Not found, aka the addy.io version is <0.6.0 (this endpoint was introduced in 0.6.0)
            // Send an empty version as callback to let the checks run in SplashActivity
            return Version(major: 0, minor: 0, patch: 0, version: "")
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func getUserResource() async throws -> UserResource? {
        logNetworkHelperCall()
        let url = URL(string: AddyIo.API_URL_ACCOUNT_DETAILS)!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleUserResource.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func getRecipients(verifiedOnly: Bool) async throws -> [Recipients]? {
        logNetworkHelperCall()
        let url = URL(string: AddyIo.API_URL_RECIPIENTS)!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(RecipientsArray.self, from: data)

            var recipientList: [Recipients] = []

            if verifiedOnly {
                for recipient in addyIoData.data {
                    if recipient.email_verified_at != nil {
                        recipientList.append(recipient)
                    }
                }
            } else {
                recipientList.append(contentsOf: addyIoData.data)
            }

            return recipientList
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func getUsernames() async throws -> UsernamesArray? {
        logNetworkHelperCall()
        let url = URL(string: AddyIo.API_URL_USERNAMES)!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            return try decoder.decode(UsernamesArray.self, from: data)
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func getRules() async throws -> RulesArray? {
        logNetworkHelperCall()
        let url = URL(string: AddyIo.API_URL_RULES)!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            return try decoder.decode(RulesArray.self, from: data)
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func getDomains() async throws -> DomainsArray? {
        logNetworkHelperCall()
        let url = URL(string: AddyIo.API_URL_DOMAINS)!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            return try decoder.decode(DomainsArray.self, from: data)
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func getFailedDeliveries(page: Int? = nil, size: Int? = 25, filter: String? = nil) async throws -> FailedDeliveriesArray? {
        logNetworkHelperCall()
        var parameters: [URLQueryItem] = []

        if let size = size {
            parameters.append(URLQueryItem(name: "page[size]", value: "\(size)"))
        }

        if let page = page {
            parameters.append(URLQueryItem(name: "page[number]", value: "\(page)"))
        }

        if let filter = filter {
            parameters.append(URLQueryItem(name: "filter[email_type]", value: filter))
        }

        var urlComponents = URLComponents(string: AddyIo.API_URL_FAILED_DELIVERIES)!
        urlComponents.queryItems = parameters

        var request = URLRequest(url: urlComponents.url!)
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            return try decoder.decode(FailedDeliveriesArray.self, from: data)
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func downloadFailedDelivery(failedDeliveryId: String) async throws -> URL {
        logNetworkHelperCall()

        let url = URL(string: "\(AddyIo.API_URL_FAILED_DELIVERIES)/\(failedDeliveryId)/download")!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()

        let (temporaryURL, response) = try await URLSession.shared.download(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "downloadFailedDelivery",
                extra: error.failureURLString
            )
            throw error
        }

        switch httpResponse.statusCode {
        case 200:
            // Create a permanent URL for the downloaded file
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent("\(failedDeliveryId).eml")

            // Move the temporary file to a permanent location
            do {
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    try FileManager.default.removeItem(at: fileURL)
                }
                try FileManager.default.moveItem(at: temporaryURL, to: fileURL)
                return fileURL
            } catch {
                loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: "Failed to move file: \(error.localizedDescription)",
                    method: "downloadFailedDelivery",
                    extra: nil
                )
                throw error
            }
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: Data(), request: request)
        }
    }

    public func getDomainOptions() async throws -> DomainOptions? {
        logNetworkHelperCall()
        let url = URL(string: AddyIo.API_URL_DOMAIN_OPTIONS)!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            return try decoder.decode(DomainOptions.self, from: data)
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func getSpecificUsername(usernameId: String) async throws -> Usernames? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_USERNAMES)/\(usernameId)")!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleUsername.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func getApiTokenDetails() async throws -> ApiTokenDetails? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_API_TOKEN_DETAILS)")!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            return try decoder.decode(ApiTokenDetails.self, from: data)
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func getSpecificDomain(domainId: String) async throws -> Domains? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_DOMAINS)/\(domainId)")!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleDomain.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func getSpecificRecipient(recipientId: String) async throws -> Recipients? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_RECIPIENTS)/\(recipientId)")!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleRecipient.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func getChartData() async throws -> AddyChartData? {
        logNetworkHelperCall()
        let url = URL(string: AddyIo.API_URL_CHART_DATA)!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            return try decoder.decode(AddyChartData.self, from: data)
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func resendVerificationEmail(recipientId: String) async throws -> String {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_RECIPIENT_RESEND)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["recipient_id": recipientId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            return "200"
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func getSpecificAlias(aliasId: String) async throws -> Aliases? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_ALIAS)/\(aliasId)")!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleAlias.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func getSpecificRule(ruleId: String) async throws -> Rules? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_RULES)/\(ruleId)")!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleRule.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func updateRule(ruleId: String, rule: Rules) async throws -> String {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_RULES)/\(ruleId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = getHeaders()
        let ruleData = try? JSONEncoder().encode(rule)
        request.httpBody = ruleData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            return "200"
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func restoreAlias(aliasId: String) async throws -> Aliases? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_ALIAS)/\(aliasId)/restore")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleAlias.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func addAlias(domain: String, description: String, format: String, localPart: String, recipients: [String]?) async throws -> Aliases? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_ALIAS)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()

        let json: [String: Any] = ["domain": domain,
                                   "description": description,
                                   "format": format,
                                   "local_part": localPart,
                                   "recipient_ids": recipients ?? []]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 201:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleAlias.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func activateSpecificAlias(aliasId: String) async throws -> Aliases? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_ACTIVE_ALIAS)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["id": aliasId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleAlias.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func activateAttachedRecipientsOnly(aliasId: String) async throws -> Aliases? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_ATTACHED_RECIPIENTS_ONLY)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["id": aliasId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleAlias.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func deactivateAttachedRecipientsOnly(aliasId: String) async throws -> String {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_ATTACHED_RECIPIENTS_ONLY)/\(aliasId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 204:
            return "204"
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func activateSpecificRule(ruleId: String) async throws -> Rules? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_ACTIVE_RULES)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["id": ruleId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleRule.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func allowRecipientToReplySend(recipientId: String) async throws -> Recipients? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_ALLOWED_RECIPIENTS)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["id": recipientId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleRecipient.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func enableCatchAllSpecificUsername(usernameId: String) async throws -> Usernames? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_CATCH_ALL_USERNAMES)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["id": usernameId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleUsername.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func enableCatchAllSpecificDomain(domainId: String) async throws -> Domains? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_CATCH_ALL_DOMAINS)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["id": domainId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleDomain.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func disableCatchAllSpecificUsername(usernameId: String) async throws -> String {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_CATCH_ALL_USERNAMES)/\(usernameId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 204:
            return "204"
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func disableCatchAllSpecificDomain(domainId: String) async throws -> String {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_CATCH_ALL_DOMAINS)/\(domainId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 204:
            return "204"
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func enableCanLoginSpecificUsername(usernameId: String) async throws -> Usernames? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_CAN_LOGIN_USERNAMES)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["id": usernameId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleUsername.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func disableCanLoginSpecificUsername(usernameId: String) async throws -> String {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_CAN_LOGIN_USERNAMES)/\(usernameId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 204:
            return "204"
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func activateSpecificUsername(usernameId: String) async throws -> Usernames? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_ACTIVE_USERNAMES)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["id": usernameId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleUsername.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func activateSpecificDomain(domainId: String) async throws -> Domains? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_ACTIVE_DOMAINS)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["id": domainId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleDomain.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func deactivateSpecificUsername(usernameId: String) async throws -> String {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_ACTIVE_USERNAMES)/\(usernameId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 204:
            return "204"
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func deactivateSpecificDomain(domainId: String) async throws -> String {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_ACTIVE_DOMAINS)/\(domainId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 204:
            return "204"
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func deactivateSpecificAlias(aliasId: String) async throws -> String {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_ACTIVE_ALIAS)/\(aliasId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 204:
            return "204"
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func pinSpecificAlias(aliasId: String) async throws -> Aliases? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_PINNED_ALIASES)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["id": aliasId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleAlias.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func unpinSpecificAlias(aliasId: String) async throws -> String {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_PINNED_ALIASES)/\(aliasId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 204:
            return "204"
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func deactivateSpecificRule(ruleId: String) async throws -> String {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_ACTIVE_RULES)/\(ruleId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 204:
            return "204"
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func disallowRecipientToReplySend(recipientId: String) async throws -> String {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_ALLOWED_RECIPIENTS)/\(recipientId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 204:
            return "204"
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func disableEncryptionRecipient(recipientId: String) async throws -> String {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_ENCRYPTED_RECIPIENTS)/\(recipientId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 204:
            return "204"
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func enableEncryptionRecipient(recipientId: String) async throws -> Recipients? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_ENCRYPTED_RECIPIENTS)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["id": recipientId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleRecipient.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func disableProtectedHeadersRecipient(recipientId: String) async throws -> String {
        logNetworkHelperCall()

        let url = URL(string: "\(AddyIo.API_URL_PROTECTED_HEADERS_RECIPIENTS)/\(recipientId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 204:
            return "204"
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func disablePgpInlineRecipient(recipientId: String) async throws -> String {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_INLINE_ENCRYPTED_RECIPIENTS)/\(recipientId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 204:
            return "204"
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func enableProtectedHeadersRecipient(recipientId: String) async throws -> Recipients? {
        logNetworkHelperCall()

        let url = URL(string: AddyIo.API_URL_PROTECTED_HEADERS_RECIPIENTS)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["id": recipientId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleRecipient.self, from: data)
            return addyIoData.data

        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func enablePgpInlineRecipient(recipientId: String) async throws -> Recipients? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_INLINE_ENCRYPTED_RECIPIENTS)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["id": recipientId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleRecipient.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func enableRemovePgpKeysRecipients(recipientId: String) async throws -> Recipients? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_REMOVE_PGP_KEYS_RECIPIENTS)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["id": recipientId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleRecipient.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func disableRemovePgpKeysRecipients(recipientId: String) async throws -> String {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_REMOVE_PGP_KEYS_RECIPIENTS)/\(recipientId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 204:
            return "204"
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func enableRemovePgpSignaturesRecipients(recipientId: String) async throws -> Recipients? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_REMOVE_PGP_SIGNATURES_RECIPIENTS)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["id": recipientId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleRecipient.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func disableRemovePgpSignaturesRecipients(recipientId: String) async throws -> String {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_REMOVE_PGP_SIGNATURES_RECIPIENTS)/\(recipientId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 204:
            return "204"
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func removeEncryptionKeyRecipient(recipientId: String) async throws -> String {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_RECIPIENT_KEYS)/\(recipientId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 204:
            return "204"
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func addEncryptionKeyRecipient(recipientId: String, keyData: String) async throws -> Recipients? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_RECIPIENT_KEYS)/\(recipientId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["key_data": keyData]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleRecipient.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func addRecipient(address: String) async throws -> Recipients? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_RECIPIENTS)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["email": address]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 201:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleRecipient.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func addUsername(username: String) async throws -> Usernames? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_USERNAMES)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["username": username]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 201:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleUsername.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func createRule(rule: Rules) async throws -> Rules? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_RULES)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let ruleData = try JSONEncoder().encode(rule)
        request.httpBody = ruleData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 201:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleRule.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func reorderRules(rules: [Rules]) async throws -> String {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_REORDER_RULES)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()

        var array: [String] = []
        // Sum up the ids
        for rule in rules {
            array.append(rule.id)
        }

        let json: [String: Any] = ["ids": array]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            return "200"
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func addDomain(domain: String) async throws -> (Domains?, String?, String?) {
        logNetworkHelperCall()
        let url = URL(string: AddyIo.API_URL_DOMAINS)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["domain": domain]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 201:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleDomain.self, from: data)
            return (addyIoData.data, "201", nil)
        case 404:
            return (nil, "404", String(data: data, encoding: .utf8))
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func deleteAlias(aliasId: String) async throws -> String {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_ALIAS)/\(aliasId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 204:
            return "204"
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func forgetAlias(aliasId: String) async throws -> String {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_ALIAS)/\(aliasId)/forget")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 204:
            return "204"
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func deleteUsername(usernameId: String) async throws -> String {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_USERNAMES)/\(usernameId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 204:
            return "204"
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func deleteRule(ruleId: String) async throws -> String {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_RULES)/\(ruleId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 204:
            return "204"
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func deleteFailedDelivery(failedDeliveryId: String) async throws -> String {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_FAILED_DELIVERIES)/\(failedDeliveryId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 204:
            return "204"
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func resendFailedDelivery(failedDeliveryId: String, recipientIds: [String]? = nil) async throws -> String {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_FAILED_DELIVERIES)/\(failedDeliveryId)/resend")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["recipient_ids": recipientIds ?? []]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 204:
            return "204"
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func deleteDomain(domainId: String) async throws -> String {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_DOMAINS)/\(domainId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 204:
            return "204"
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func deleteRecipient(recipientId: String) async throws -> String {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_RECIPIENTS)/\(recipientId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 204:
            return "204"
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func updateDescriptionSpecificAlias(aliasId: String, description: String?) async throws -> Aliases? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_ALIAS)/\(aliasId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any?] = ["description": description]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleAlias.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func updateDescriptionSpecificUsername(usernameId: String, description: String?) async throws -> Usernames? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_USERNAMES)/\(usernameId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any?] = ["description": description]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleUsername.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func updateAutoCreateRegexSpecificUsername(usernameId: String, autoCreateRegex: String?) async throws -> Usernames? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_USERNAMES)/\(usernameId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any?] = ["auto_create_regex": autoCreateRegex]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleUsername.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func updateDescriptionSpecificDomain(domainId: String, description: String?) async throws -> Domains? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_DOMAINS)/\(domainId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any?] = ["description": description]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleDomain.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func updateAutoCreateRegexSpecificDomain(domainId: String, autoCreateRegex: String?) async throws -> Domains? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_DOMAINS)/\(domainId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any?] = ["auto_create_regex": autoCreateRegex]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleDomain.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func updateFromNameSpecificAlias(aliasId: String, fromName: String?) async throws -> Aliases? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_ALIAS)/\(aliasId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any?] = ["from_name": fromName]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleAlias.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func updateFromNameSpecificUsername(usernameId: String, fromName: String?) async throws -> Usernames? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_USERNAMES)/\(usernameId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any?] = ["from_name": fromName]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleUsername.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func updateFromNameSpecificDomain(domainId: String, fromName: String?) async throws -> Domains? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_DOMAINS)/\(domainId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any?] = ["from_name": fromName]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleDomain.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func updateRecipientsSpecificAlias(aliasId: String, recipients: [String]) async throws -> Aliases? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_ALIAS_RECIPIENTS)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any?] = ["alias_id": aliasId, "recipient_ids": recipients]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleAlias.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func updateDefaultRecipientForSpecificUsername(usernameId: String, recipientId: String?) async throws -> Usernames? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_USERNAMES)/\(usernameId)/default-recipient")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any?] = ["default_recipient": recipientId ?? ""]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleUsername.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func updateDefaultRecipientForSpecificDomain(domainId: String, recipientId: String?) async throws -> Domains? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_DOMAINS)/\(domainId)/default-recipient")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any?] = ["default_recipient": recipientId ?? ""]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleDomain.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func getAliases(aliasSortFilterRequest: AliasSortFilterRequest, page: Int? = nil, size: Int? = 20, recipient: String? = nil, domain: String? = nil, username: String? = nil) async throws -> AliasesArray? {
        logNetworkHelperCall()
        var parameters: [URLQueryItem] = []

        if aliasSortFilterRequest.onlyActiveAliases {
            parameters.append(URLQueryItem(name: "filter[active]", value: "true"))
        } else if aliasSortFilterRequest.onlyInactiveAliases {
            parameters.append(URLQueryItem(name: "filter[active]", value: "false"))
        } else if aliasSortFilterRequest.onlyDeletedAliases {
            parameters.append(URLQueryItem(name: "filter[deleted]", value: "only"))
        } else if aliasSortFilterRequest.onlyPinnedAliases {
            parameters.append(URLQueryItem(name: "filter[pinned]", value: "true"))
        } else {
            parameters.append(URLQueryItem(name: "filter[deleted]", value: "with"))
        }

        if let size = size {
            parameters.append(URLQueryItem(name: "page[size]", value: "\(size)"))
        }

        if let filter = aliasSortFilterRequest.filter {
            parameters.append(URLQueryItem(name: "filter[search]", value: filter))
        }

        if let page = page {
            parameters.append(URLQueryItem(name: "page[number]", value: "\(page)"))
        }

        if let sort = aliasSortFilterRequest.sort {
            let sortFilter: String = aliasSortFilterRequest.sortDesc ? "-\(sort)" : sort
            parameters.append(URLQueryItem(name: "sort", value: sortFilter))
        }

        if let recipient = recipient {
            parameters.append(URLQueryItem(name: "recipient", value: recipient))
        }
        if let domain = domain {
            parameters.append(URLQueryItem(name: "domain", value: domain))
        }
        if let username = username {
            parameters.append(URLQueryItem(name: "username", value: username))
        }

        var urlComponents = URLComponents(string: AddyIo.API_URL_ALIAS)!
        urlComponents.queryItems = parameters

        var request = URLRequest(url: urlComponents.url!)
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            return try decoder.decode(AliasesArray.self, from: data)
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func bulkGetAlias(aliases: [String]) async throws -> BulkAliasesArray? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_ALIAS)/get/bulk")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["ids": aliases]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            return try decoder.decode(BulkAliasesArray.self, from: data)
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func cacheUserResourceForWidget() async -> Bool {
        logNetworkHelperCall()
        do {
            let userResource = try await getUserResource()
            guard let userResource = userResource else {
                // Result is null, return false to let the caller know the task failed.
                return false
            }

            // Turn the list into a json object
            let data = try JSONEncoder().encode(userResource)
            let jsonString = String(data: data, encoding: .utf8)!

            // Store a copy of the just received data locally
            encryptedSettingsManager.putSettingsString(key: .userResource, string: jsonString)

            // Stored data, return true to let the caller know the task succeeded
            return true
        } catch {
            let errorMessage = "Error: \(error.localizedDescription)"
            print(errorMessage)
            loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "cacheUserResourceForWidget",
                extra: nil
            )

            return false
        }
    }

    public func cacheMostPopularAliasesDataForWidget(amountOfAliasesToCache: Int? = 15) async -> Bool {
        logNetworkHelperCall()
        let aliasSortFilterRequest = AliasSortFilterRequest(
            onlyActiveAliases: true,
            onlyDeletedAliases: false,
            onlyInactiveAliases: false,
            onlyWatchedAliases: false,
            onlyPinnedAliases: false,
            sort: "emails_forwarded",
            sortDesc: true,
            filter: nil
        )
        do {
            let list = try await getAliases(aliasSortFilterRequest: aliasSortFilterRequest, size: amountOfAliasesToCache)
            // Turn the list into a json object
            let data = try JSONEncoder().encode(list?.data)
            let jsonString = String(data: data, encoding: .utf8)!
            // Store a copy of the just received data locally
            encryptedSettingsManager.putSettingsString(key: .backgroundServiceCacheMostActiveAliasesData, string: jsonString)
            return true
        } catch {
            let errorMessage = "Error: \(error.localizedDescription)"
            print(errorMessage)
            loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "cacheMostPopularAliasesDataForWidget",
                extra: nil
            )
            return false
        }
    }

    public func cacheFailedDeliveryCountForWidgetAndBackgroundService() async -> Bool {
        logNetworkHelperCall()
        do {
            let filterType = settingsManager.getSettingsString(key: .notifyFailedDeliveriesType) ?? "all"
            let filter = filterType == "all" ? nil : filterType
            let result = try await getFailedDeliveries(size: 1, filter: filter)
            guard let result = result else {
                // Result is null, return false to let the caller know the task failed.
                return false
            }

            let totalCount = result.meta?.total ?? result.data.count
            encryptedSettingsManager.putSettingsInt(key: .backgroundServiceCacheFailedDeliveriesCount, int: totalCount)

            // Store a copy of the just received data locally
            if let latestId = result.data.first?.id {
                encryptedSettingsManager.putSettingsString(key: .backgroundServiceCacheFailedDeliveriesLatestId, string: latestId)
            } else {
                encryptedSettingsManager.putSettingsString(key: .backgroundServiceCacheFailedDeliveriesLatestId, string: "")
            }

            // Stored data, return true to let the caller know the task succeeded
            return true
        } catch {
            print("Failed to cache failed delivery count for widget and background service: \(error)")
            return false
        }
    }

    /* 
     * BLOCKLIST
     */

    public func getAllBlocklistEntries(page: Int? = nil, size: Int? = 100, filter: String? = nil, search: String? = nil) async throws -> BlocklistEntriesArray? {
        logNetworkHelperCall()
        var parameters: [URLQueryItem] = []

        if let size = size {
            parameters.append(URLQueryItem(name: "page[size]", value: "\(size)"))
        }

        if let page = page {
            parameters.append(URLQueryItem(name: "page[number]", value: "\(page)"))
        }

        if let filter = filter {
            parameters.append(URLQueryItem(name: "filter[type]", value: filter))
        }

        if let search = search, !search.isEmpty {
            parameters.append(URLQueryItem(name: "filter[search]", value: search))
        }

        var urlComponents = URLComponents(string: AddyIo.API_URL_BLOCKLIST)!
        urlComponents.queryItems = parameters

        var request = URLRequest(url: urlComponents.url!)
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            return try decoder.decode(BlocklistEntriesArray.self, from: data)
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func addBlocklistEntry(entry: NewBlocklistEntry) async throws -> BlocklistEntries? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_BLOCKLIST)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["type": entry.type, "value": entry.value]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 201:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleBlocklistEntry.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func deleteBlocklistEntry(blocklistId: String) async throws -> String {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_BLOCKLIST)/\(blocklistId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 204:
            return "204"
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func getGithubTags() async throws -> AtomFeed? {
        logNetworkHelperCall()

        do {
            return try await AtomFeed(urlString: AddyIo.GITHUB_TAGS_RSS_FEED)
        } catch {
            let errorMessage = "Error: \(error.localizedDescription)"
            loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "getGithubTags",
                extra: nil
            )
            throw error
        }
    }

    public func cacheAccountNotificationsCountForWidgetAndBackgroundService() async -> Bool {
        logNetworkHelperCall()
        do {
            let result = try await getAllAccountNotifications()
            guard let result = result else {
                // Result is null, return false to let the caller know the task failed.
                return false
            }

            // Store a copy of the just received data locally
            encryptedSettingsManager.putSettingsInt(key: .backgroundServiceCacheAccountNotificationsCountPrevious, int: encryptedSettingsManager.getSettingsInt(key: .backgroundServiceCacheAccountNotificationsCount))
            encryptedSettingsManager.putSettingsInt(key: .backgroundServiceCacheAccountNotificationsCount, int: result.data.count)

            // Stored data, return true to let the caller know the task succeeded
            return true
        } catch {
            print("Failed to cache account notification count for widget and background service: \(error)")
            return false
        }
    }

    public func getAllAccountNotifications() async throws -> AccountNotificationsArray? {
        logNetworkHelperCall()
        let url = URL(string: AddyIo.API_URL_ACCOUNT_NOTIFICATIONS)!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            return try decoder.decode(AccountNotificationsArray.self, from: data)
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }

    public func notifyServerForSubscriptionChange(receipt: String) async throws -> UserResource? {
        logNetworkHelperCall()
        let url = URL(string: "\(AddyIo.API_URL_NOTIFY_SUBSCRIPTION)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["receiptData": receipt, "platform": "apple"]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let (data, httpResponse) = try await performRequest(request: request)

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleUserResource.self, from: data)
            return addyIoData.data
        default:
            throw handleNetworkResponseError(httpResponse: httpResponse, data: data, request: request)
        }
    }
}
