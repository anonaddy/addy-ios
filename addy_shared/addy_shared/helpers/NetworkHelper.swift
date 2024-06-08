//
//  NetworkHelper.swift
//  addy
//
//  Created by Stijn van de Water on 07/05/2024.
//

import Foundation

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
    
    private func getUserAgent() -> String {
        let userAgent = "\(SharedData.shared.userAgent.userAgentApplicationID) (\(SharedData.shared.userAgent.userAgentApplicationBuildType)) / \(SharedData.shared.userAgent.userAgentVersion) (\(SharedData.shared.userAgent.userAgentVersionCode))"
        
#if DEBUG
        print("User-Agent: \(userAgent)")
#endif
        
        return userAgent
    }
    
    
    
    private func invalidApiKey() {
        print(String(localized: "api_key_invalid"))
        // TODO: reset app
    }
    
    public func verifyApiKey(baseUrl: String, apiKey: String, completion: @escaping (String?) -> Void) {
        // Set base URL
        AddyIo.API_BASE_URL = baseUrl
        
        let url = URL(string: AddyIo.API_URL_ACCOUNT_DETAILS)!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders(apiKey: apiKey)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil)
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                completion("200")
            case 401:
                completion(nil)
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print("Error: \(httpResponse.statusCode) - \(errorMessage)")
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "getUserResource",
                    extra: ErrorHelper.getErrorMessage(data:
                                                        data
                                                      ))
                completion(
                    nil
                )
            }
        }
        
        task.resume()
    }
    
    public func getAddyIoInstanceVersion(completion: @escaping (Version?, String?) -> Void) {
        let url = URL(string: AddyIo.API_URL_APP_VERSION)!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(Version.self, from: data)
                    completion(addyIoData, nil)
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "getAddyIoInstanceVersion",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                    nil,
                    errorMessage
                )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            case 404:
                // Not found, aka the addy.io version is <0.6.0 (this endpoint was introduced in 0.6.0)
                // Send an empty version as callback to let the checks run in SplashActivity
                completion(Version(major: 0, minor: 0, patch: 0, version: ""), nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "getAddyIoInstanceVersion",
                    extra: ErrorHelper.getErrorMessage(data:
                                                        data
                                                      ))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    public func getUserResource(completion: @escaping (UserResource?, String?) -> Void) {
        let url = URL(string: AddyIo.API_URL_ACCOUNT_DETAILS)!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(SingleUserResource.self, from: data)
                    completion(addyIoData.data, nil)
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "getUserResource",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                    nil,
                    errorMessage
                )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "getUserResource",
                    extra: ErrorHelper.getErrorMessage(data:
                                                        data
                                                      ))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    public func getRecipients(verifiedOnly: Bool, completion: @escaping ([Recipients]?, String?) -> Void) {
        let url = URL(string: AddyIo.API_URL_RECIPIENTS)!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
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
                    
                    completion(recipientList, nil)
                    
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "getRecipients",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                    nil,
                    errorMessage
                )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "getRecipients",
                    extra: ErrorHelper.getErrorMessage(data:
                                                        data
                                                      ))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    public func getUsernames(completion: @escaping (UsernamesArray?, String?) -> Void) {
        let url = URL(string: AddyIo.API_URL_USERNAMES)!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(UsernamesArray.self, from: data)
                    completion(addyIoData, nil)
                    
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "getUsernames",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                    nil,
                    errorMessage
                )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "getUsernames",
                    extra: ErrorHelper.getErrorMessage(data:
                                                        data
                                                      ))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    
    public func getRules(completion: @escaping (RulesArray?, String?) -> Void) {
        let url = URL(string: AddyIo.API_URL_RULES)!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(RulesArray.self, from: data)
                    completion(addyIoData, nil)
                    
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "getRules",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                    nil,
                    errorMessage
                )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "getRules",
                    extra: ErrorHelper.getErrorMessage(data:
                                                        data
                                                      ))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    public func getDomains(completion: @escaping (DomainsArray?, String?) -> Void) {
        let url = URL(string: AddyIo.API_URL_DOMAINS)!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(DomainsArray.self, from: data)
                    completion(addyIoData, nil)
                    
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "getDomains",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                    nil,
                    errorMessage
                )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "getDomains",
                    extra: ErrorHelper.getErrorMessage(data:
                                                        data
                                                      ))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    public func getFailedDeliveries(completion: @escaping (FailedDeliveriesArray?, String?) -> Void) {
        let url = URL(string: AddyIo.API_URL_FAILED_DELIVERIES)!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(FailedDeliveriesArray.self, from: data)
                    completion(addyIoData, nil)
                    
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "getFailedDeliveries",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                    nil,
                    errorMessage
                )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "getFailedDeliveries",
                    extra: ErrorHelper.getErrorMessage(data:
                                                        data
                                                      ))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    public func getDomainOptions(completion: @escaping (DomainOptions?, String?) -> Void) {
        let url = URL(string: AddyIo.API_URL_DOMAIN_OPTIONS)!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(DomainOptions.self, from: data)
                    completion(addyIoData, nil)
                    
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "getDomainOptions",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                    nil,
                    errorMessage
                )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "getDomainOptions",
                    extra: ErrorHelper.getErrorMessage(data:
                                                        data
                                                      ))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    
    public func getSpecificUsername(completion: @escaping (Usernames?, String?) -> Void, usernameId:String) {
        let url = URL(string: "\(AddyIo.API_URL_USERNAMES)/\(usernameId)")!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(SingleUsername.self, from: data)
                    completion(addyIoData.data, nil)
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "getSpecificUsername",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                        nil,
                        errorMessage
                    )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "getSpecificUsername",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    
    public func getSpecificDomain(completion: @escaping (Domains?, String?) -> Void, domainId:String) {
        let url = URL(string: "\(AddyIo.API_URL_DOMAINS)/\(domainId)")!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(SingleDomain.self, from: data)
                    completion(addyIoData.data, nil)
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "getSpecificDomain",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                        nil,
                        errorMessage
                    )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "getSpecificDomain",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    
    public func getSpecificRecipient(completion: @escaping (Recipients?, String?) -> Void, recipientId:String) {
        let url = URL(string: "\(AddyIo.API_URL_RECIPIENTS)/\(recipientId)")!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(SingleRecipient.self, from: data)
                    completion(addyIoData.data, nil)
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "getSpecificRecipient",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                        nil,
                        errorMessage
                    )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "getSpecificRecipient",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    public func resendVerificationEmail(completion: @escaping (String?) -> Void, recipientId:String) {
        let url = URL(string: AddyIo.API_URL_RECIPIENT_RESEND)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["recipient_id": recipientId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                completion("200")
                
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "resendVerificationEmail",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    
    public func getSpecificAlias(completion: @escaping (Aliases?, String?) -> Void, aliasId:String) {
        let url = URL(string: "\(AddyIo.API_URL_ALIAS)/\(aliasId)")!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(SingleAlias.self, from: data)
                    completion(addyIoData.data, nil)
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "getSpecificAlias",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                        nil,
                        errorMessage
                    )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "getSpecificAlias",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    
    public func getSpecificRule(completion: @escaping (Rules?, String?) -> Void, ruleId:String) {
        let url = URL(string: "\(AddyIo.API_URL_RULES)/\(ruleId)")!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = getHeaders()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(SingleRule.self, from: data)
                    completion(addyIoData.data, nil)
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "getSpecificRule",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                        nil,
                        errorMessage
                    )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "getSpecificRule",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    
    public func updateRule(completion: @escaping (String?) -> Void, ruleId:String, rule:Rules) {
        let url = URL(string: "\(AddyIo.API_URL_RULES)/\(ruleId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = getHeaders()
        let ruleData = try? JSONEncoder().encode(rule)
        request.httpBody = ruleData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                completion("200")
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "updateRule",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    public func restoreAlias(completion: @escaping (Aliases?, String?) -> Void, aliasId:String) {
        let url = URL(string: "\(AddyIo.API_URL_ALIAS)/\(aliasId)/restore")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = getHeaders()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(SingleAlias.self, from: data)
                    completion(addyIoData.data, nil)
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "restoreSpecificAlias",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                        nil,
                        errorMessage
                    )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "restoreSpecificAlias",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    public func addAlias(completion: @escaping (Aliases?, String?) -> Void, domain: String, description: String, format: String, localPart: String, recipients: [String]) {
        let url = URL(string: AddyIo.API_URL_ALIAS)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        
        
        let json: [String: Any] = ["domain": domain,
                                   "description": description,
                                   "format": format,
                                   "local_part": localPart,
                                   "recipient_ids": recipients]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 201:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(SingleAlias.self, from: data)
                    completion(addyIoData.data, nil)
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "addAlias",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                        nil,
                        errorMessage
                    )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "addAlias",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    public func activateSpecificAlias(completion: @escaping (Aliases?, String?) -> Void, aliasId:String) {
        let url = URL(string: AddyIo.API_URL_ACTIVE_ALIAS)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["id": aliasId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(SingleAlias.self, from: data)
                    completion(addyIoData.data, nil)
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "activateSpecificAlias",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                        nil,
                        errorMessage
                    )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "activateSpecificAlias",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    
    
    
    
    public func allowRecipientToReplySend(completion: @escaping (Recipients?, String?) -> Void, recipientId:String) {
        let url = URL(string: AddyIo.API_URL_ALLOWED_RECIPIENTS)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["id": recipientId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(SingleRecipient.self, from: data)
                    completion(addyIoData.data, nil)
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "allowRecipientToReplySend",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                        nil,
                        errorMessage
                    )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "allowRecipientToReplySend",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    
    public func enableCatchAllSpecificUsername(completion: @escaping (Usernames?, String?) -> Void, usernameId:String) {
        let url = URL(string: AddyIo.API_URL_CATCH_ALL_USERNAMES)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["id": usernameId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(SingleUsername.self, from: data)
                    completion(addyIoData.data, nil)
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "enableCatchAllSpecificUsername",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                        nil,
                        errorMessage
                    )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "enableCatchAllSpecificUsername",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    public func enableCatchAllSpecificDomain(completion: @escaping (Domains?, String?) -> Void, domainId:String) {
        let url = URL(string: AddyIo.API_URL_CATCH_ALL_DOMAINS)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["id": domainId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(SingleDomain.self, from: data)
                    completion(addyIoData.data, nil)
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "enableCatchAllSpecificDomain",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                        nil,
                        errorMessage
                    )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "enableCatchAllSpecificDomain",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    public func disableCatchAllSpecificUsername(completion: @escaping (String?) -> Void, usernameId:String) {
        let url = URL(string: "\(AddyIo.API_URL_CATCH_ALL_USERNAMES)/\(usernameId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 204:
                completion("204")
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "disableCatchAllSpecificUsername",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    
    public func disableCatchAllSpecificDomain(completion: @escaping (String?) -> Void, domainId:String) {
        let url = URL(string: "\(AddyIo.API_URL_CATCH_ALL_DOMAINS)/\(domainId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 204:
                completion("204")
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "disableCatchAllSpecificDomain",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    
    public func enableCanLoginSpecificUsername(completion: @escaping (Usernames?, String?) -> Void, usernameId:String) {
        let url = URL(string: AddyIo.API_URL_CAN_LOGIN_USERNAMES)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["id": usernameId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(SingleUsername.self, from: data)
                    completion(addyIoData.data, nil)
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "enableCanLoginSpecificUsername",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                        nil,
                        errorMessage
                    )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "enableCanLoginSpecificUsername",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    public func disableCanLoginSpecificUsername(completion: @escaping (String?) -> Void, usernameId:String) {
        let url = URL(string: "\(AddyIo.API_URL_CAN_LOGIN_USERNAMES)/\(usernameId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 204:
                completion("204")
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "disableCanLoginSpecificUsername",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    
    
    public func activateSpecificUsername(completion: @escaping (Usernames?, String?) -> Void, usernameId:String) {
        let url = URL(string: AddyIo.API_URL_ACTIVE_USERNAMES)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["id": usernameId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(SingleUsername.self, from: data)
                    completion(addyIoData.data, nil)
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "activateSpecificUsername",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                        nil,
                        errorMessage
                    )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "activateSpecificUsername",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    
    public func activateSpecificDomain(completion: @escaping (Domains?, String?) -> Void, domainId:String) {
        let url = URL(string: AddyIo.API_URL_ACTIVE_DOMAINS)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["id": domainId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(SingleDomain.self, from: data)
                    completion(addyIoData.data, nil)
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "activateSpecificDomain",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                        nil,
                        errorMessage
                    )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "activateSpecificDomain",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    public func deactivateSpecificUsername(completion: @escaping (String?) -> Void, usernameId:String) {
        let url = URL(string: "\(AddyIo.API_URL_ACTIVE_USERNAMES)/\(usernameId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 204:
                completion("204")
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "deactivateSpecificUsername",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    public func deactivateSpecificDomain(completion: @escaping (String?) -> Void, domainId:String) {
        let url = URL(string: "\(AddyIo.API_URL_ACTIVE_DOMAINS)/\(domainId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 204:
                completion("204")
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "deactivateSpecificDomain",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    public func deactivateSpecificAlias(completion: @escaping (String?) -> Void, aliasId:String) {
        let url = URL(string: "\(AddyIo.API_URL_ACTIVE_ALIAS)/\(aliasId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 204:
                completion("204")
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "deactivateSpecificAlias",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    public func disallowRecipientToReplySend(completion: @escaping (String?) -> Void, recipientId:String) {
        let url = URL(string: "\(AddyIo.API_URL_ALLOWED_RECIPIENTS)/\(recipientId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 204:
                completion("204")
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "disallowRecipientToReplySend",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    
    public func disableEncryptionRecipient(completion: @escaping (String?) -> Void, recipientId:String) {
        let url = URL(string: "\(AddyIo.API_URL_ENCRYPTED_RECIPIENTS)/\(recipientId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 204:
                completion("204")
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "disableEncryptionRecipient",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    public func enableEncryptionRecipient(completion: @escaping (Recipients?, String?) -> Void, recipientId:String) {
        let url = URL(string: AddyIo.API_URL_ENCRYPTED_RECIPIENTS)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["id": recipientId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(SingleRecipient.self, from: data)
                    completion(addyIoData.data, nil)
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "enableEncryptionRecipient",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                        nil,
                        errorMessage
                    )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "enableEncryptionRecipient",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    
    public func disablePgpInlineRecipient(completion: @escaping (String?) -> Void, recipientId:String) {
        let url = URL(string: "\(AddyIo.API_URL_INLINE_ENCRYPTED_RECIPIENTS)/\(recipientId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 204:
                completion("204")
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "disablePgpInlineRecipient",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    public func enablePgpInlineRecipient(completion: @escaping (Recipients?, String?) -> Void, recipientId:String) {
        let url = URL(string: AddyIo.API_URL_INLINE_ENCRYPTED_RECIPIENTS)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["id": recipientId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(SingleRecipient.self, from: data)
                    completion(addyIoData.data, nil)
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "enablePgpInlineRecipient",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                        nil,
                        errorMessage
                    )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "enablePgpInlineRecipient",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    
    
    public func removeEncryptionKeyRecipient(completion: @escaping (String?) -> Void, recipientId:String) {
        let url = URL(string: "\(AddyIo.API_URL_RECIPIENT_KEYS)/\(recipientId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 204:
                completion("204")
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "removeEncryptionKeyRecipient",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    public func disableProtectedHeadersRecipient(completion: @escaping (String?) -> Void, recipientId:String) {
        let url = URL(string: "\(AddyIo.API_URL_PROTECTED_HEADERS_RECIPIENTS)/\(recipientId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 204:
                completion("204")
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "disablePgpInlineRecipient",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    public func enableProtectedHeadersRecipient(completion: @escaping (Recipients?, String?) -> Void, recipientId:String) {
        let url = URL(string: AddyIo.API_URL_PROTECTED_HEADERS_RECIPIENTS)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["id": recipientId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(SingleRecipient.self, from: data)
                    completion(addyIoData.data, nil)
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "enablePgpInlineRecipient",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                        nil,
                        errorMessage
                    )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "enablePgpInlineRecipient",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    public func addEncryptionKeyRecipient(completion: @escaping (Recipients?, String?) -> Void, recipientId:String, keyData:String) {
        let url = URL(string: "\(AddyIo.API_URL_RECIPIENT_KEYS)/\(recipientId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["key_data": keyData]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(SingleRecipient.self, from: data)
                    completion(addyIoData.data, nil)
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "addEncryptionKeyRecipient",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                        nil,
                        errorMessage
                    )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "addEncryptionKeyRecipient",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    
    
    public func addRecipient(completion: @escaping (Recipients?, String?) -> Void, address:String) {
        let url = URL(string: AddyIo.API_URL_RECIPIENTS)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["email": address]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 201:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(SingleRecipient.self, from: data)
                    completion(addyIoData.data, nil)
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "addRecipient",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                        nil,
                        errorMessage
                    )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "addRecipient",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    
    public func addUsername(completion: @escaping (Usernames?, String?) -> Void, username:String) {
        let url = URL(string: AddyIo.API_URL_USERNAMES)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["username": username]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 201:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(SingleUsername.self, from: data)
                    completion(addyIoData.data, nil)
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "addUsername",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                        nil,
                        errorMessage
                    )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "addUsername",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    
    
    public func createRule(completion: @escaping (Rules?, String?) -> Void, rule:Rules) {
        let url = URL(string: AddyIo.API_URL_USERNAMES)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let ruleData = try? JSONEncoder().encode(rule)
        request.httpBody = ruleData
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 201:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(SingleRule.self, from: data)
                    completion(addyIoData.data, nil)
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "createRule",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                        nil,
                        errorMessage
                    )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "createRule",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    
    
    
    public func reorderRules(completion: @escaping (String?) -> Void, rules:[Rules]) {
        let url = URL(string: AddyIo.API_URL_REORDER_RULES)!
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
        
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                completion("200")
                
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "reorderRules",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    
    
    
    public func addDomain(completion: @escaping (Domains?, String?, String?) -> Void, domain:String) {
        let url = URL(string: AddyIo.API_URL_DOMAINS)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any] = ["domain": domain]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error), nil)
                return
            }
            
            switch httpResponse.statusCode {
            case 201:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(SingleDomain.self, from: data)
                    completion(addyIoData.data, "201", nil)
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "addDomain",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                        nil,
                        errorMessage,
                        nil
                    )
                }
                // 404 means that the setup is not completed
            case 404:
                completion(nil, "404", String(data: data, encoding: .utf8))
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "addDomain",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    nil,
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    
    
    public func deleteAlias(completion: @escaping (String?) -> Void, aliasId:String) {
        let url = URL(string: "\(AddyIo.API_URL_ALIAS)/\(aliasId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 204:
                completion("204")
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "deleteSpecificAlias",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    public func forgetAlias(completion: @escaping (String?) -> Void, aliasId:String) {
        let url = URL(string: "\(AddyIo.API_URL_ALIAS)/\(aliasId)/forget")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 204:
                completion("204")
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "forgetSpecificAlias",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    public func deleteUsername(completion: @escaping (String?) -> Void, usernameId:String) {
        let url = URL(string: "\(AddyIo.API_URL_USERNAMES)/\(usernameId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 204:
                completion("204")
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "deleteUsername",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    public func deleteRule(completion: @escaping (String?) -> Void, ruleId:String) {
        let url = URL(string: "\(AddyIo.API_URL_RULES)/\(ruleId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 204:
                completion("204")
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "deleteRule",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    public func deleteFailedDelivery(completion: @escaping (String?) -> Void, failedDeliveryId:String) {
        let url = URL(string: "\(AddyIo.API_URL_FAILED_DELIVERIES)/\(failedDeliveryId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 204:
                completion("204")
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "deleteFailedDelivery",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    public func deleteDomain(completion: @escaping (String?) -> Void, domainId:String) {
        let url = URL(string: "\(AddyIo.API_URL_DOMAINS)/\(domainId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 204:
                completion("204")
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "deleteDomain",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    public func deleteRecipient(completion: @escaping (String?) -> Void, recipientId:String) {
        let url = URL(string: "\(AddyIo.API_URL_RECIPIENTS)/\(recipientId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = getHeaders()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 204:
                completion("204")
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "deleteRecipient",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    
    public func updateDescriptionSpecificAlias(completion: @escaping (Aliases?, String?) -> Void, aliasId:String, description:String?) {
        let url = URL(string: "\(AddyIo.API_URL_ALIAS)/\(aliasId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any?] = ["description": description]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(SingleAlias.self, from: data)
                    completion(addyIoData.data, nil)
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "updateDescriptionSpecificAlias",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                        nil,
                        errorMessage
                    )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "updateDescriptionSpecificAlias",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    public func updateDescriptionSpecificUsername(completion: @escaping (Usernames?, String?) -> Void, usernameId:String, description:String?) {
        let url = URL(string: "\(AddyIo.API_URL_USERNAMES)/\(usernameId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any?] = ["description": description]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(SingleUsername.self, from: data)
                    completion(addyIoData.data, nil)
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "updateDescriptionSpecificUsername",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                        nil,
                        errorMessage
                    )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "updateDescriptionSpecificUsername",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    
    public func updateDescriptionSpecificDomain(completion: @escaping (Domains?, String?) -> Void, domainId:String, description:String?) {
        let url = URL(string: "\(AddyIo.API_URL_DOMAINS)/\(domainId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any?] = ["description": description]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(SingleDomain.self, from: data)
                    completion(addyIoData.data, nil)
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "updateDescriptionSpecificDomain",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                        nil,
                        errorMessage
                    )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "updateDescriptionSpecificDomain",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    
    public func updateFromNameSpecificAlias(completion: @escaping (Aliases?, String?) -> Void, aliasId:String, fromName:String?) {
        let url = URL(string: "\(AddyIo.API_URL_ALIAS)/\(aliasId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any?] = ["from_name": fromName]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(SingleAlias.self, from: data)
                    completion(addyIoData.data, nil)
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "updateFromNameSpecificAlias",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                        nil,
                        errorMessage
                    )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "updateFromNameSpecificAlias",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    public func updateFromNameSpecificUsername(completion: @escaping (Usernames?, String?) -> Void, usernameId:String, fromName:String?) {
        let url = URL(string: "\(AddyIo.API_URL_USERNAMES)/\(usernameId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any?] = ["from_name": fromName]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(SingleUsername.self, from: data)
                    completion(addyIoData.data, nil)
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "updateFromNameSpecificUsername",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                        nil,
                        errorMessage
                    )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "updateFromNameSpecificUsername",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    public func updateFromNameSpecificDomain(completion: @escaping (Domains?, String?) -> Void, domainId:String, fromName:String?) {
        let url = URL(string: "\(AddyIo.API_URL_DOMAINS)/\(domainId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any?] = ["from_name": fromName]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(SingleDomain.self, from: data)
                    completion(addyIoData.data, nil)
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "updateFromNameSpecificDomain",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                        nil,
                        errorMessage
                    )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "updateFromNameSpecificDomain",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    public func updateRecipientsSpecificAlias(completion: @escaping (Aliases?, String?) -> Void, aliasId:String, recipients:[String]) {
        let url = URL(string: AddyIo.API_URL_ALIAS_RECIPIENTS)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any?] = ["alias_id": aliasId, "recipient_ids": recipients]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(SingleAlias.self, from: data)
                    completion(addyIoData.data, nil)
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "updateDescriptionSpecificAlias",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                        nil,
                        errorMessage
                    )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "updateRecipientsSpecificAlias",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    public func updateDefaultRecipientForSpecificUsername(completion: @escaping (Usernames?, String?) -> Void, usernameId:String, recipientId:String?) {
        let url = URL(string: "\(AddyIo.API_URL_USERNAMES)/\(usernameId)/default-recipient")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any?] = ["default_recipient": recipientId ?? ""]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(SingleUsername.self, from: data)
                    completion(addyIoData.data, nil)
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "updateDefaultRecipientForSpecificUsername",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                        nil,
                        errorMessage
                    )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "updateDefaultRecipientForSpecificUsername",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    public func updateDefaultRecipientForSpecificDomain(completion: @escaping (Domains?, String?) -> Void, domainId:String, recipientId:String?) {
        let url = URL(string: "\(AddyIo.API_URL_DOMAINS)/\(domainId)/default-recipient")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = getHeaders()
        let json: [String: Any?] = ["default_recipient": recipientId ?? ""]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(SingleDomain.self, from: data)
                    completion(addyIoData.data, nil)
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "updateDefaultRecipientForSpecificDomain",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                        nil,
                        errorMessage
                    )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print(errorMessage)
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "updateDefaultRecipientForSpecificDomain",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }
    
    public func  getAliases(completion: @escaping (AliasesArray?, String?) -> Void, aliasSortFilterRequest: AliasSortFilterRequest,page: Int? = nil,size: Int? = 20,recipient: String? = nil,domain: String? = nil,username: String? = nil) {
        
        
        
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
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                completion(nil, String(describing: error))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoder = JSONDecoder()
                    let addyIoData = try decoder.decode(AliasesArray.self, from: data)
                    completion(addyIoData, nil)
                } catch {
                    let errorMessage = "Error: \(String(describing: error.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                    print(errorMessage)
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "getAliases",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                    nil,
                    errorMessage
                )
                }
                
            case 401:
                //TODO: remove, not allowed
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //                    // Unauthenticated, clear settings
                //                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                //                }
                completion(nil, nil)
                
            default:
                let errorMessage = "Error: \(String(describing: error?.localizedDescription)) | \(httpResponse.statusCode) - \(String(describing: error))"
                print("Error: \(httpResponse.statusCode) - \(String(describing: error))")
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "getAliases",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    nil,
                    errorMessage
                )
            }
        }
        
        task.resume()
    }}
