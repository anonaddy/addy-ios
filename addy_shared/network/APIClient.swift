//
//  APIClient.swift
//  addy_shared
//
//  Created by Stijn van de Water on 22/08/2026.
//

import Foundation
import Security

public protocol APIClientProtocol: AnyObject, Sendable {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    func requestRaw(_ endpoint: Endpoint) async throws -> (Data, HTTPURLResponse)
    func download(_ endpoint: Endpoint, destination: URL) async throws -> URL
    func isCertificatePasswordCorrect() -> Bool
    func createAppResetDueToInvalidAPIKeyNotification()
    func mapResponseError(response: HTTPURLResponse, data: Data, requestURL: String) -> NetworkError
}

public final class APIClient: NSObject, URLSessionDelegate, APIClientProtocol, @unchecked Sendable {
    public static let shared = APIClient()

    private let loggingHelper: LoggingHelper
    private let encryptedSettingsManager: SettingsManager
    private let p12: Data?
    private let p12Password: String?
    private var session: URLSession!

    public init(p12: Data? = nil, p12Password: String? = nil) {
        self.loggingHelper = LoggingHelper()
        self.encryptedSettingsManager = SettingsManager(encrypted: true)
        self.p12 = p12 ?? encryptedSettingsManager.getSettingsData(key: .p12)
        self.p12Password = p12Password ?? encryptedSettingsManager.getSettingsString(key: .p12Password)
        super.init()

        let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)

        AddyIo.API_BASE_URL = encryptedSettingsManager.getSettingsString(key: .baseUrl) ?? AddyIo.API_BASE_URL
    }

    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let p12 = p12 else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let password = p12Password ?? ""

        guard let identity = createSecIdentity(from: p12, with: password) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        let certificate: SecCertificate? = copyCertificate(from: identity)
        let credential = URLCredential(identity: identity, certificates: certificate != nil ? [certificate!] : [], persistence: .none)
        completionHandler(.useCredential, credential)
    }

    public func isCertificatePasswordCorrect() -> Bool {
        guard let p12 = p12 else {
            return false
        }
        let password = p12Password ?? ""
        return createSecIdentity(from: p12, with: password) != nil
    }

    private func createSecIdentity(from p12Data: Data, with password: String) -> SecIdentity? {
        let options: [String: Any] = [kSecImportExportPassphrase as String: password]
        var items: CFArray?

        guard SecPKCS12Import(p12Data as CFData, options as CFDictionary, &items) == errSecSuccess,
              let itemsArray = items as? [[String: Any]],
              let firstItem = itemsArray.first,
              let rawIdentity = firstItem[kSecImportItemIdentity as String],
              CFGetTypeID(rawIdentity as CFTypeRef) == SecIdentityGetTypeID() else {
            return nil
        }

        return (rawIdentity as! SecIdentity)
    }

    private func copyCertificate(from identity: SecIdentity) -> SecCertificate? {
        var certificate: SecCertificate?
        _ = SecIdentityCopyCertificate(identity, &certificate)
        return certificate
    }

    public func getHeaders(apiKey: String? = nil) -> [String: String] {
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

    public func getUserAgent() -> String {
        let userAgent = "\(SharedData.shared.userAgent.userAgentApplicationID) (\(SharedData.shared.userAgent.userAgentApplicationBuildType)) / \(SharedData.shared.userAgent.userAgentVersion) (\(SharedData.shared.userAgent.userAgentVersionCode))"
        return userAgent
    }

    public func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let (data, response) = try await requestRaw(endpoint)

        guard (200...299).contains(response.statusCode) else {
            throw mapResponseError(response: response, data: data, requestURL: response.url?.absoluteString ?? "")
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            let decodingErrMsg = "Decoding error for \(T.self): \(error.localizedDescription)"
            loggingHelper.addLog(
                importance: .critical,
                error: decodingErrMsg,
                method: #function,
                extra: String(data: data, encoding: .utf8)
            )
            throw NetworkError.decodingError(message: decodingErrMsg)
        }
    }

    public func requestRaw(_ endpoint: Endpoint) async throws -> (Data, HTTPURLResponse) {
        let headers = getHeaders(apiKey: endpoint.apiKeyOverride)
        let urlRequest = try endpoint.urlRequest(defaultHeaders: headers)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            if (error as? URLError)?.code == .cancelled || error is CancellationError {
                throw CancellationError()
            }
            loggingHelper.addLog(
                importance: .critical,
                error: error.localizedDescription,
                method: #function,
                extra: urlRequest.url?.absoluteString
            )
            throw NetworkError.transportError(message: error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            let error = NetworkError.transportError(message: "Invalid server response")
            loggingHelper.addLog(
                importance: .critical,
                error: error.localizedDescription,
                method: #function,
                extra: urlRequest.url?.absoluteString
            )
            throw error
        }

        if httpResponse.statusCode == 401 {
            let error = handleUnauthorized(data: data, request: urlRequest)
            throw error
        }

        return (data, httpResponse)
    }

    public func download(_ endpoint: Endpoint, destination: URL) async throws -> URL {
        let headers = getHeaders(apiKey: endpoint.apiKeyOverride)
        let urlRequest = try endpoint.urlRequest(defaultHeaders: headers)

        let (tempURL, response): (URL, URLResponse)
        do {
            (tempURL, response) = try await session.download(for: urlRequest)
        } catch {
            if (error as? URLError)?.code == .cancelled || error is CancellationError {
                throw CancellationError()
            }
            loggingHelper.addLog(
                importance: .critical,
                error: error.localizedDescription,
                method: #function,
                extra: urlRequest.url?.absoluteString
            )
            throw NetworkError.transportError(message: error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.transportError(message: "Invalid server response")
        }

        if httpResponse.statusCode == 401 {
            let error = handleUnauthorized(data: Data(), request: urlRequest)
            throw error
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode, message: "Download failed with status: \(httpResponse.statusCode)")
        }

        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: tempURL, to: destination)
        return destination
    }

    private func handleUnauthorized(data: Data, request: URLRequest) -> NetworkError {
        loggingHelper.addLog(
            importance: .critical,
            error: "401, app will reset",
            method: #function,
            extra: "data: \(data.base64EncodedString()), shouldBeHeaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")"
        )

        createAppResetDueToInvalidAPIKeyNotification()
        SettingsManager(encrypted: true).clearSettingsAndCloseApp()
        let errorMessage = ErrorHelper.getErrorMessage(data: data)
        return NetworkError.unauthorized(message: errorMessage)
    }

    public func mapResponseError(response: HTTPURLResponse, data: Data, requestURL: String) -> NetworkError {
        let message = ErrorHelper.getErrorMessage(data: data)
        loggingHelper.addLog(
            importance: .critical,
            error: "HTTP \(response.statusCode) - \(message)",
            method: #function,
            extra: "URL: \(requestURL)"
        )

        switch response.statusCode {
        case 401:
            return .unauthorized(message: message)
        case 403:
            return .forbidden(message: message)
        case 404:
            return .notFound(message: message)
        case 422:
            return .unprocessableEntity(message: message)
        default:
            return .httpError(statusCode: response.statusCode, message: message)
        }
    }
}
