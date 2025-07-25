//
//  NetworkHelper.swift
//  addy
//
//  Created by Stijn van de Water on 07/05/2024.
//

import Foundation
import FeedKit

public class NetworkHelper {
    private let loggingHelper: LoggingHelper
    private let encryptedSettingsManager: SettingsManager
    
    
    
    public init() {
        self.loggingHelper = LoggingHelper()
        self.encryptedSettingsManager = SettingsManager(encrypted: true)
        AddyIo.API_BASE_URL = encryptedSettingsManager.getSettingsString(key: .baseUrl) ?? AddyIo.API_BASE_URL
    }
    
    private func getHeaders(apiKey: String? = nil) -> [String:String] {
        let apiKeyToSend = apiKey ?? encryptedSettingsManager.getSettingsString(key: .apiKey)
        return [
            "Authorization": "Bearer \(apiKeyToSend ?? "")",
            "Content-Type": "application/json",
            "X-Requested-With": "XMLHttpRequest",
            "Accept": "application/json",
            "User-Agent": getUserAgent()
        ]
    }
    
    public func createAppResetDueToInvalidAPIKeyNotification(){
        SharedNotificationHelper.createAppResetDueToInvalidAPIKeyNotification()
    }
    
    private func getUserAgent() -> String {
        let userAgent = "\(SharedData.shared.userAgent.userAgentApplicationID) (\(SharedData.shared.userAgent.userAgentApplicationBuildType)) / \(SharedData.shared.userAgent.userAgentVersion) (\(SharedData.shared.userAgent.userAgentVersionCode))"
        
#if DEBUG
        print("User-Agent: \(userAgent)")
#endif
        
        return userAgent
    }
    
    // Using @escaping as logging errors is not a thing before the app is set-up (they cannot be seen)
    public func registration(username: String, email: String, password: String, apiExpiration: String, completion: @escaping (String?) -> Void) async {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        
        
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
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: error.localizedDescription,
                    method: "registration",
                    extra: error.failureURLString)
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
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "registration",
                    extra: ErrorHelper.getErrorMessage(data: data))
                completion(errorMessage)
            }
        } catch {
            print(error)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "registration",
                extra: nil)
            completion(error.localizedDescription)
        }
        
        
    }
    
    // Using @escaping as logging errors is not a thing before the app is set-up (they cannot be seen)
    public func verifyRegistration(query: String, completion: @escaping (String?, String?) -> Void) async {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        
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
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: error.localizedDescription,
                    method: "verifyRegistration",
                    extra: error.failureURLString)
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
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "verifyRegistration",
                    extra: ErrorHelper.getErrorMessage(data: data))
                completion(nil, errorMessage)
            }
        } catch {
            print(error)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "verifyRegistration",
                extra: nil)
            completion(nil, error.localizedDescription)
        }
        
        
    }
    
    public func login(baseUrl: String, username: String, password: String, apiExpiration: String, completion: @escaping (Login?, LoginMfaRequired?, String?) -> Void) async {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        
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
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: error.localizedDescription,
                    method: "login",
                    extra: error.failureURLString)
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
                completion(nil, nil , addyIoData.message)
            case 403: // MFA required but is hardware key and thus not supported OR the email address has not been validated
                let decoder = JSONDecoder()
                let addyIoData = try decoder.decode(LoginError.self, from: data)
                completion(nil, nil , addyIoData.message)
            default:
                let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "login",
                    extra: ErrorHelper.getErrorMessage(data: data))
                completion(nil, nil , errorMessage)
            }
        } catch {
            print(error)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "login",
                extra: nil)
            completion(nil, nil , error.localizedDescription)
        }
        
        
    }
    
    
    
    public func deleteAccount(password: String, completion: @escaping (String) -> Void) async {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_DELETE_ACCOUNT)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["password": password]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                let error = URLError(.badServerResponse)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: error.localizedDescription,
                    method: "deleteAccount",
                    extra: error.failureURLString)
                throw error
            }
            
            switch httpResponse.statusCode {
            case 204:
                completion(String(httpResponse.statusCode))
            case 422:
                completion(String(httpResponse.statusCode))
            case 401:
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: "401, app will reset",
                    method: #function,
                    extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
                
                self.createAppResetDueToInvalidAPIKeyNotification()
                SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
            default:
                let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "deleteAccount",
                    extra: ErrorHelper.getErrorMessage(data: data))
                throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
            }
        } catch {
            print(error)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "login",
                extra: nil)
            completion(error.localizedDescription)
        }
    }
     
    
    public func logout() async throws -> Int? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_LOGOUT)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "logout",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 204:
            return httpResponse.statusCode
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "logout",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    // Using @escaping as logging errors is not a thing before the app is set-up (they cannot be seen)
    public func loginMfa(baseUrl: String, mfa_key: String, otp: String, xCsrfToken: String, apiExpiration: String, completion: @escaping (Login?, String?) -> Void) async {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        
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
            "X-CSRF-TOKEN": xCsrfToken
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
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: error.localizedDescription,
                    method: "loginMfa",
                    extra: error.failureURLString)
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
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "loginMfa",
                    extra: ErrorHelper.getErrorMessage(data: data))
                completion(nil, errorMessage)
            }
        } catch {
            print(error)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "loginMfa",
                extra: nil)
            completion(nil, error.localizedDescription)
        }
        
        
    }
    
    
    public func verifyApiKey(baseUrl: String, apiKey: String) async throws -> UserResource? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        
        // Set base URL
        AddyIo.API_BASE_URL = baseUrl
        
        let url = URL(string: AddyIo.API_URL_ACCOUNT_DETAILS)!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders(apiKey: apiKey)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "verifyApiKey",
                extra: error.failureURLString)
            throw error
        }
        
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
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "getUserResource",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func getAddyIoInstanceVersion() async throws -> Version? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: AddyIo.API_URL_APP_VERSION)!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "getAddyIoInstanceVersion",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(Version.self, from: data)
            return addyIoData
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        case 404:
            // Not found, aka the addy.io version is <0.6.0 (this endpoint was introduced in 0.6.0)
            // Send an empty version as callback to let the checks run in SplashActivity
            return Version(major: 0, minor: 0, patch: 0, version: "")
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "getAddyIoInstanceVersion",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func getUserResource() async throws -> UserResource? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: AddyIo.API_URL_ACCOUNT_DETAILS)!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "getUserResource",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleUserResource.self, from: data)
            return addyIoData.data
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "getUserResource",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func getRecipients(verifiedOnly: Bool) async throws -> [Recipients]? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: AddyIo.API_URL_RECIPIENTS)!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "getRecipients",
                extra: error.failureURLString)
            throw error
        }
        
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
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "getRecipients",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func getUsernames() async throws -> UsernamesArray? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: AddyIo.API_URL_USERNAMES)!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "getUsernames",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(UsernamesArray.self, from: data)
            return addyIoData
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "getUsernames",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    
    
    
    public func getRules() async throws -> RulesArray? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: AddyIo.API_URL_RULES)!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "getRules",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(RulesArray.self, from: data)
            return addyIoData
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "getRules",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func getDomains() async throws -> DomainsArray? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: AddyIo.API_URL_DOMAINS)!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "getDomains",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(DomainsArray.self, from: data)
            return addyIoData
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "getDomains",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func getFailedDeliveries() async throws -> FailedDeliveriesArray? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: AddyIo.API_URL_FAILED_DELIVERIES)!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "getFailedDeliveries",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(FailedDeliveriesArray.self, from: data)
            return addyIoData
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "getFailedDeliveries",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func downloadFailedDelivery(failedDeliveryId: String) async throws -> URL {
    #if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
    #endif
        
        let url = URL(string: "\(AddyIo.API_URL_FAILED_DELIVERIES)/\(failedDeliveryId)/download")!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()
        
        let (temporaryURL, response) = try await URLSession.shared.download(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "downloadFailedDelivery",
                extra: error.failureURLString)
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
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: "Failed to move file: \(error.localizedDescription)",
                    method: "downloadFailedDelivery",
                    extra: nil)
                throw error
            }
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(Data().base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired)
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "downloadFailedDelivery",
                extra: ErrorHelper.getErrorMessage(data: Data()))
            throw URLError(.badServerResponse)
        }
    }
    
    
    public func getDomainOptions() async throws -> DomainOptions? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: AddyIo.API_URL_DOMAIN_OPTIONS)!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "getDomainOptions",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(DomainOptions.self, from: data)
            return addyIoData
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "getDomainOptions",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func getSpecificUsername(usernameId: String) async throws -> Usernames? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_USERNAMES)/\(usernameId)")!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "getSpecificUsername",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleUsername.self, from: data)
            return addyIoData.data
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "getSpecificUsername",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    
    
    public func getApiTokenDetails() async throws -> ApiTokenDetails? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_API_TOKEN_DETAILS)")!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "getApiTokenDetails",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(ApiTokenDetails.self, from: data)
            return addyIoData
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "getApiTokenDetails",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    
    public func getSpecificDomain(domainId: String) async throws -> Domains? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_DOMAINS)/\(domainId)")!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "getSpecificDomain",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleDomain.self, from: data)
            return addyIoData.data
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "getSpecificDomain",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    
    public func getSpecificRecipient(recipientId: String) async throws -> Recipients? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_RECIPIENTS)/\(recipientId)")!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "getSpecificRecipient",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleRecipient.self, from: data)
            return addyIoData.data
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "getSpecificRecipient",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func getChartData() async throws -> AddyChartData? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: AddyIo.API_URL_CHART_DATA)!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "getChartData",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(AddyChartData.self, from: data)
            return addyIoData
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "getChartData",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func resendVerificationEmail(recipientId: String) async throws -> String {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_RECIPIENT_RESEND)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["recipient_id": recipientId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "resendVerificationEmail",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            return "200"
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "resendVerificationEmail",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    
    public func getSpecificAlias(aliasId: String) async throws -> Aliases? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_ALIAS)/\(aliasId)")!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "getSpecificAlias",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleAlias.self, from: data)
            return addyIoData.data
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "getSpecificAlias",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    
    public func getSpecificRule(ruleId: String) async throws -> Rules? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_RULES)/\(ruleId)")!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "getSpecificRule",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleRule.self, from: data)
            return addyIoData.data
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "getSpecificRule",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    
    public func updateRule(ruleId: String, rule: Rules) async throws -> String {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_RULES)/\(ruleId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = getHeaders()
        let ruleData = try? JSONEncoder().encode(rule)
        request.httpBody = ruleData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "updateRule",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            return "200"
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "updateRule",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func restoreAlias(aliasId: String) async throws -> Aliases? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_ALIAS)/\(aliasId)/restore")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = getHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "restoreAlias",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleAlias.self, from: data)
            return addyIoData.data
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "restoreAlias",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func addAlias(domain: String, description: String, format: String, localPart: String, recipients: [String]?) async throws -> Aliases? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
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
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "addAlias",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 201:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleAlias.self, from: data)
            return addyIoData.data
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "addAlias",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func activateSpecificAlias(aliasId: String) async throws -> Aliases? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_ACTIVE_ALIAS)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["id": aliasId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "activateSpecificAlias",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleAlias.self, from: data)
            return addyIoData.data
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "activateSpecificAlias",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func activateAttachedRecipientsOnly(aliasId: String) async throws -> Aliases? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_ATTACHED_RECIPIENTS_ONLY)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["id": aliasId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "activateAttachedRecipientsOnly",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleAlias.self, from: data)
            return addyIoData.data
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "activateAttachedRecipientsOnly",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }

    
    public func deactivateAttachedRecipientsOnly(aliasId: String) async throws -> String {
    #if DEBUG
            print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
    #endif
            let url = URL(string: "\(AddyIo.API_URL_ATTACHED_RECIPIENTS_ONLY)/\(aliasId)")!
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.allHTTPHeaderFields = getHeaders()
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                let error = URLError(.badServerResponse)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: error.localizedDescription,
                    method: "deactivateAttachedRecipientsOnly",
                    extra: error.failureURLString)
                throw error
            }
            
            switch httpResponse.statusCode {
            case 204:
                return "204"
            case 401:
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: "401, app will reset",
                    method: #function,
                    extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
                
                self.createAppResetDueToInvalidAPIKeyNotification()
                SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
            default:
                let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "deactivateAttachedRecipientsOnly",
                    extra: ErrorHelper.getErrorMessage(data: data))
                throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
            }
        }
    
    
    
    public func activateSpecificRule(ruleId: String) async throws -> Rules? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_ACTIVE_RULES)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["id": ruleId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "activateSpecificRule",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleRule.self, from: data)
            return addyIoData.data
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "activateSpecificRule",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    
    
    
    
    public func allowRecipientToReplySend(recipientId: String) async throws -> Recipients? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_ALLOWED_RECIPIENTS)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["id": recipientId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "allowRecipientToReplySend",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleRecipient.self, from: data)
            return addyIoData.data
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "allowRecipientToReplySend",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    
    public func enableCatchAllSpecificUsername(usernameId: String) async throws -> Usernames? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_CATCH_ALL_USERNAMES)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["id": usernameId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "enableCatchAllSpecificUsername",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleUsername.self, from: data)
            return addyIoData.data
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "enableCatchAllSpecificUsername",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func enableCatchAllSpecificDomain(domainId: String) async throws -> Domains? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_CATCH_ALL_DOMAINS)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["id": domainId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "enableCatchAllSpecificDomain",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleDomain.self, from: data)
            return addyIoData.data
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "enableCatchAllSpecificDomain",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func disableCatchAllSpecificUsername(usernameId: String) async throws -> String {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_CATCH_ALL_USERNAMES)/\(usernameId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "disableCatchAllSpecificUsername",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 204:
            return "204"
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "disableCatchAllSpecificUsername",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    
    public func disableCatchAllSpecificDomain(domainId: String) async throws -> String {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_CATCH_ALL_DOMAINS)/\(domainId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "disableCatchAllSpecificDomain",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 204:
            return "204"
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "disableCatchAllSpecificDomain",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    
    public func enableCanLoginSpecificUsername(usernameId: String) async throws -> Usernames? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_CAN_LOGIN_USERNAMES)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["id": usernameId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "enableCanLoginSpecificUsername",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleUsername.self, from: data)
            return addyIoData.data
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "enableCanLoginSpecificUsername",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func disableCanLoginSpecificUsername(usernameId: String) async throws -> String {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_CAN_LOGIN_USERNAMES)/\(usernameId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "disableCanLoginSpecificUsername",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 204:
            return "204"
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "disableCanLoginSpecificUsername",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    
    
    public func activateSpecificUsername(usernameId: String) async throws -> Usernames? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_ACTIVE_USERNAMES)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["id": usernameId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "activateSpecificUsername",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleUsername.self, from: data)
            return addyIoData.data
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "activateSpecificUsername",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    
    public func activateSpecificDomain(domainId: String) async throws -> Domains? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_ACTIVE_DOMAINS)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["id": domainId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "activateSpecificDomain",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleDomain.self, from: data)
            return addyIoData.data
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "activateSpecificDomain",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func deactivateSpecificUsername(usernameId: String) async throws -> String {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_ACTIVE_USERNAMES)/\(usernameId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "deactivateSpecificUsername",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 204:
            return "204"
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "deactivateSpecificUsername",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func deactivateSpecificDomain(domainId: String) async throws -> String {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_ACTIVE_DOMAINS)/\(domainId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "deactivateSpecificDomain",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 204:
            return "204"
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "deactivateSpecificDomain",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func deactivateSpecificAlias(aliasId: String) async throws -> String {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_ACTIVE_ALIAS)/\(aliasId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "deactivateSpecificAlias",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 204:
            return "204"
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "deactivateSpecificAlias",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func deactivateSpecificRule(ruleId: String) async throws -> String {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_ACTIVE_RULES)/\(ruleId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "deactivateSpecificRule",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 204:
            return "204"
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "deactivateSpecificRule",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func disallowRecipientToReplySend(recipientId: String) async throws -> String {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_ALLOWED_RECIPIENTS)/\(recipientId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "disallowRecipientToReplySend",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 204:
            return "204"
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "disallowRecipientToReplySend",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    
    public func disableEncryptionRecipient(recipientId: String) async throws -> String {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_ENCRYPTED_RECIPIENTS)/\(recipientId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "disableEncryptionRecipient",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 204:
            return "204"
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "disableEncryptionRecipient",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func enableEncryptionRecipient(recipientId: String) async throws -> Recipients? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_ENCRYPTED_RECIPIENTS)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["id": recipientId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "enableEncryptionRecipient",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleRecipient.self, from: data)
            return addyIoData.data
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "enableEncryptionRecipient",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func disableProtectedHeadersRecipient(recipientId: String) async throws -> String {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        
        let url = URL(string: "\(AddyIo.API_URL_PROTECTED_HEADERS_RECIPIENTS)/\(recipientId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "disableProtectedHeadersRecipient",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 204:
            return "204"
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "disableProtectedHeadersRecipient",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    
    public func disablePgpInlineRecipient(recipientId: String) async throws -> String {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_INLINE_ENCRYPTED_RECIPIENTS)/\(recipientId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "disablePgpInlineRecipient",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 204:
            return "204"
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "disablePgpInlineRecipient",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    public func enableProtectedHeadersRecipient(recipientId: String) async throws -> Recipients? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        
        let url = URL(string: AddyIo.API_URL_PROTECTED_HEADERS_RECIPIENTS)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["id": recipientId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "enableProtectedHeadersRecipient",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleRecipient.self, from: data)
            return addyIoData.data
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
            
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "enableProtectedHeadersRecipient",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func enablePgpInlineRecipient(recipientId: String) async throws -> Recipients? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_INLINE_ENCRYPTED_RECIPIENTS)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["id": recipientId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "enablePgpInlineRecipient",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleRecipient.self, from: data)
            return addyIoData.data
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "enablePgpInlineRecipient",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    
    
    public func removeEncryptionKeyRecipient(recipientId: String) async throws -> String {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_RECIPIENT_KEYS)/\(recipientId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "removeEncryptionKeyRecipient",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 204:
            return "204"
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "removeEncryptionKeyRecipient",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    
    
    
    
    
    public func addEncryptionKeyRecipient(recipientId: String, keyData: String) async throws -> Recipients? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_RECIPIENT_KEYS)/\(recipientId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["key_data": keyData]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "addEncryptionKeyRecipient",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleRecipient.self, from: data)
            return addyIoData.data
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "addEncryptionKeyRecipient",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    
    
    
    public func addRecipient(address: String) async throws -> Recipients? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_RECIPIENTS)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["email": address]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "addRecipient",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 201:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleRecipient.self, from: data)
            return addyIoData.data
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "addRecipient",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    
    public func addUsername(username: String) async throws -> Usernames? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_USERNAMES)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["username": username]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "addUsername",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 201:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleUsername.self, from: data)
            return addyIoData.data
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "addUsername",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    
    public func createRule(rule: Rules) async throws -> Rules? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_RULES)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let ruleData = try JSONEncoder().encode(rule)
        request.httpBody = ruleData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "createRule",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 201:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleRule.self, from: data)
            return addyIoData.data
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "createRule",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    
    
    
    public func reorderRules(rules: [Rules]) async throws -> String {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
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
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "reorderRules",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            return "200"
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "reorderRules",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    
    
    
    public func addDomain(domain: String) async throws -> (Domains?, String?, String?) {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: AddyIo.API_URL_DOMAINS)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["domain": domain]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "addDomain",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 201:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleDomain.self, from: data)
            return (addyIoData.data, "201", nil)
        case 404:
            return (nil, "404", String(data: data, encoding: .utf8))
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "addDomain",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    
    
    public func deleteAlias(aliasId: String) async throws -> String {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_ALIAS)/\(aliasId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "deleteAlias",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 204:
            return "204"
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "deleteAlias",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func forgetAlias(aliasId: String) async throws -> String {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_ALIAS)/\(aliasId)/forget")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "forgetAlias",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 204:
            return "204"
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "forgetAlias",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func deleteUsername(usernameId: String) async throws -> String {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_USERNAMES)/\(usernameId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "deleteUsername",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 204:
            return "204"
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "deleteUsername",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func deleteRule(ruleId: String) async throws -> String {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_RULES)/\(ruleId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "deleteRule",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 204:
            return "204"
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "deleteRule",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func deleteFailedDelivery(failedDeliveryId: String) async throws -> String {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_FAILED_DELIVERIES)/\(failedDeliveryId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "deleteFailedDelivery",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 204:
            return "204"
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "deleteFailedDelivery",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    public func resendFailedDelivery(failedDeliveryId: String, recipientIds: [String]? = nil) async throws -> String {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_FAILED_DELIVERIES)/\(failedDeliveryId)/resend")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["recipient_ids": recipientIds ?? []]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "resendFailedDelivery",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 204:
            return "204"
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "resendFailedDelivery",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func deleteDomain(domainId: String) async throws -> String {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_DOMAINS)/\(domainId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "deleteDomain",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 204:
            return "204"
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "deleteDomain",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func deleteRecipient(recipientId: String) async throws -> String {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_RECIPIENTS)/\(recipientId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "deleteRecipient",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 204:
            return "204"
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "deleteRecipient",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    
    public func updateDescriptionSpecificAlias(aliasId: String, description: String?) async throws -> Aliases? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_ALIAS)/\(aliasId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any?] = ["description": description]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "updateDescriptionSpecificAlias",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleAlias.self, from: data)
            return addyIoData.data
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "updateDescriptionSpecificAlias",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func updateDescriptionSpecificUsername(usernameId: String, description: String?) async throws -> Usernames? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_USERNAMES)/\(usernameId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any?] = ["description": description]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "updateDescriptionSpecificUsername",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleUsername.self, from: data)
            return addyIoData.data
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "updateDescriptionSpecificUsername",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func updateAutoCreateRegexSpecificUsername(usernameId: String, autoCreateRegex: String?) async throws -> Usernames? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_USERNAMES)/\(usernameId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any?] = ["auto_create_regex": autoCreateRegex]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "updateAutoCreateRegexSpecificUsername",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleUsername.self, from: data)
            return addyIoData.data
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "updateAutoCreateRegexSpecificUsername",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    
    public func updateDescriptionSpecificDomain(domainId: String, description: String?) async throws -> Domains? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_DOMAINS)/\(domainId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any?] = ["description": description]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "updateDescriptionSpecificDomain",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleDomain.self, from: data)
            return addyIoData.data
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "updateDescriptionSpecificDomain",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    
    public func updateAutoCreateRegexSpecificDomain(domainId: String, autoCreateRegex: String?) async throws -> Domains? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_DOMAINS)/\(domainId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any?] = ["auto_create_regex": autoCreateRegex]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "updateAutoCreateRegexSpecificDomain",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleDomain.self, from: data)
            return addyIoData.data
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "updateAutoCreateRegexSpecificDomain",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    
    public func updateFromNameSpecificAlias(aliasId: String, fromName: String?) async throws -> Aliases? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_ALIAS)/\(aliasId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any?] = ["from_name": fromName]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "updateFromNameSpecificAlias",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleAlias.self, from: data)
            return addyIoData.data
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "updateFromNameSpecificAlias",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func updateFromNameSpecificUsername(usernameId: String, fromName: String?) async throws -> Usernames? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_USERNAMES)/\(usernameId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any?] = ["from_name": fromName]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "updateFromNameSpecificUsername",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleUsername.self, from: data)
            return addyIoData.data
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "updateFromNameSpecificUsername",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func updateFromNameSpecificDomain(domainId: String, fromName: String?) async throws -> Domains? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_DOMAINS)/\(domainId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any?] = ["from_name": fromName]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "updateFromNameSpecificDomain",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleDomain.self, from: data)
            return addyIoData.data
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "updateFromNameSpecificDomain",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func updateRecipientsSpecificAlias(aliasId: String, recipients: [String]) async throws -> Aliases? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_ALIAS_RECIPIENTS)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any?] = ["alias_id": aliasId, "recipient_ids": recipients]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "updateRecipientsSpecificAlias",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleAlias.self, from: data)
            return addyIoData.data
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "updateRecipientsSpecificAlias",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func updateDefaultRecipientForSpecificUsername(usernameId: String, recipientId: String?) async throws -> Usernames? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_USERNAMES)/\(usernameId)/default-recipient")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any?] = ["default_recipient": recipientId ?? ""]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "updateDefaultRecipientForSpecificUsername",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleUsername.self, from: data)
            return addyIoData.data
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "updateDefaultRecipientForSpecificUsername",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func updateDefaultRecipientForSpecificDomain(domainId: String, recipientId: String?) async throws -> Domains? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_DOMAINS)/\(domainId)/default-recipient")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any?] = ["default_recipient": recipientId ?? ""]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "updateDefaultRecipientForSpecificDomain",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleDomain.self, from: data)
            return addyIoData.data
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "updateDefaultRecipientForSpecificDomain",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    public func getAliases(aliasSortFilterRequest: AliasSortFilterRequest, page: Int? = nil, size: Int? = 20, recipient: String? = nil, domain: String? = nil, username: String? = nil) async throws -> AliasesArray? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        var parameters: [URLQueryItem] = []
        
        if aliasSortFilterRequest.onlyActiveAliases {
            parameters.append(URLQueryItem(name: "filter[active]", value: "true"))
        } else if aliasSortFilterRequest.onlyInactiveAliases {
            parameters.append(URLQueryItem(name: "filter[active]", value: "false"))
            parameters.append(URLQueryItem(name: "filter[deleted]", value: "with"))
        } else if aliasSortFilterRequest.onlyDeletedAliases {
            parameters.append(URLQueryItem(name: "filter[deleted]", value: "only"))
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
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "getAliases",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(AliasesArray.self, from: data)
            return addyIoData
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "getAliases",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    
    public func bulkGetAlias(aliases: [String]) async throws -> BulkAliasesArray? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_ALIAS)/get/bulk")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["ids": aliases]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "bulkGetAlias",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(BulkAliasesArray.self, from: data)
            return addyIoData
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "bulkGetAlias",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    
    public func cacheUserResourceForWidget() async -> Bool {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
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
            self.encryptedSettingsManager.putSettingsString(key: .userResource, string: jsonString)
            
            // Stored data, return true to let the caller know the task succeeded
            return true
        } catch {
            let errorMessage = "Error: \(error.localizedDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "cacheUserResourceForWidget",
                extra: nil)
            
            return false
        }
    }
    
    
    
    public func cacheMostPopularAliasesDataForWidget(amountOfAliasesToCache: Int? = 15) async -> Bool {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let aliasSortFilterRequest = AliasSortFilterRequest(
            onlyActiveAliases: true,
            onlyDeletedAliases: false,
            onlyInactiveAliases: false,
            onlyWatchedAliases:false,
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
            self.encryptedSettingsManager.putSettingsString(key: .backgroundServiceCacheMostActiveAliasesData, string: jsonString)
            return true
        } catch {
            let errorMessage = "Error: \(error.localizedDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "cacheMostPopularAliasesDataForWidget",
                extra: nil)
            return false
        }
    }
    
    
    
    public func cacheFailedDeliveryCountForWidgetAndBackgroundService() async -> Bool {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        do {
            let result = try await getFailedDeliveries()
            guard let result = result else {
                // Result is null, return false to let the caller know the task failed.
                return false
            }
            
            // Store a copy of the just received data locally
            self.encryptedSettingsManager.putSettingsInt(key: .backgroundServiceCacheFailedDeliveriesCountPrevious, int: self.encryptedSettingsManager.getSettingsInt(key: .backgroundServiceCacheFailedDeliveriesCount))
            self.encryptedSettingsManager.putSettingsInt(key: .backgroundServiceCacheFailedDeliveriesCount, int: result.data.count)
            
            // Stored data, return true to let the caller know the task succeeded
            return true
        } catch {
            print("Failed to cache failed delivery count for widget and background service: \(error)")
            return false
        }
    }
    
    
    
    
    public func getGithubTags() async throws -> AtomFeed? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        
        do {
            return try await AtomFeed(urlString: AddyIo.GITHUB_TAGS_RSS_FEED)
        } catch {
            let errorMessage = "Error: \(error.localizedDescription)"
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "getGithubTags",
                extra: nil
            )
            throw error
        }
    }
    
    
    public func cacheAccountNotificationsCountForWidgetAndBackgroundService() async -> Bool {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        do {
            let result = try await getAllAccountNotifications()
            guard let result = result else {
                // Result is null, return false to let the caller know the task failed.
                return false
            }
            
            // Store a copy of the just received data locally
            self.encryptedSettingsManager.putSettingsInt(key: .backgroundServiceCacheAccountNotificationsCountPrevious, int: self.encryptedSettingsManager.getSettingsInt(key: .backgroundServiceCacheAccountNotificationsCount))
            self.encryptedSettingsManager.putSettingsInt(key: .backgroundServiceCacheAccountNotificationsCount, int: result.data.count)
            
            // Stored data, return true to let the caller know the task succeeded
            return true
        } catch {
            print("Failed to cache account notification count for widget and background service: \(error)")
            return false
        }
    }
    
    
    public func getAllAccountNotifications() async throws -> AccountNotificationsArray? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: AddyIo.API_URL_ACCOUNT_NOTIFICATIONS)!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "getAllAccountNotifications",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(AccountNotificationsArray.self, from: data)
            return addyIoData
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "getAllAccountNotifications",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
    
    
    public func notifyServerForSubscriptionChange(receipt: String) async throws -> UserResource? {
#if DEBUG
        print("\(#function) called from \((#file as NSString).lastPathComponent):\(#line)")
#endif
        let url = URL(string: "\(AddyIo.API_URL_NOTIFY_SUBSCRIPTION)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["receiptData": receipt, "platform": "apple"]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = URLError(.badServerResponse)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: error.localizedDescription,
                method: "notifyServerForSubscriptionChange",
                extra: error.failureURLString)
            throw error
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let addyIoData = try decoder.decode(SingleUserResource.self, from: data)
            return addyIoData.data
        case 401:
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: "401, app will reset",
                method: #function,
                extra: "data: \(data.base64EncodedString()), shouldBeheaders: \(getHeaders().description), actualRequestHeaders: \(request.allHTTPHeaderFields?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "None"), postUrl: \(request.url?.absoluteString ?? "none")")
            
            self.createAppResetDueToInvalidAPIKeyNotification()
            SettingsManager(encrypted: true).clearSettingsAndCloseApp()
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        default:
            let errorMessage = "Error: \(httpResponse.statusCode) - \(httpResponse.debugDescription)"
            print(errorMessage)
            self.loggingHelper.addLog(
                importance: LogImportance.critical,
                error: errorMessage,
                method: "notifyServerForSubscriptionChange",
                extra: ErrorHelper.getErrorMessage(data: data))
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: ErrorHelper.getErrorMessage(data: data)])
        }
    }
    
}
