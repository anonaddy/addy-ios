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
                let errorMessage = error?.localizedDescription ?? "Unknown error"
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
                    let errorMessage = error.localizedDescription
                    print("Error: \(httpResponse.statusCode) - \(error)")
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "getUserResource",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                        nil,
                        ErrorHelper.getErrorMessage(data:data)
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
                let errorMessage = error?.localizedDescription ?? "Unknown error"
                print("Error: \(httpResponse.statusCode) - \(error)")
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "getUserResource",
                    extra: ErrorHelper.getErrorMessage(data:
                                                        data
                                                      ))
                completion(
                    nil,
                    ErrorHelper.getErrorMessage(data:
                                                    data
                                               )
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
                    let errorMessage = error.localizedDescription
                    print("Error: \(httpResponse.statusCode) - \(error)")
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "getSpecificRecipient",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                        nil,
                        ErrorHelper.getErrorMessage(data:
                                                        data
                                                   )
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
                let errorMessage = error?.localizedDescription ?? "Unknown error"
                print("Error: \(httpResponse.statusCode) - \(error)")
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "getSpecificRecipient",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    nil,
                    ErrorHelper.getErrorMessage(data:data)
                )
            }
        }
        
        task.resume()
    }
    
    
    public func  getAliases(completion: @escaping (AliasesArray?, String?) -> Void, aliasSortFilter: AliasSortFilter,page: Int? = nil,size: Int? = 20,recipient: String? = nil,domain: String? = nil,username: String? = nil) {
        
        
        
        var parameters: [URLQueryItem] = []

           if aliasSortFilter.onlyActiveAliases {
               parameters.append(URLQueryItem(name: "filter[active]", value: "true"))
           } else if aliasSortFilter.onlyInactiveAliases {
               parameters.append(URLQueryItem(name: "filter[active]", value: "false"))
               parameters.append(URLQueryItem(name: "filter[deleted]", value: "with"))
           } else if aliasSortFilter.onlyDeletedAliases {
               parameters.append(URLQueryItem(name: "filter[deleted]", value: "only"))
           } else {
               parameters.append(URLQueryItem(name: "filter[deleted]", value: "with"))
           }

           if let size = size {
               parameters.append(URLQueryItem(name: "page[size]", value: "\(size)"))
           }

           if let filter = aliasSortFilter.filter {
               parameters.append(URLQueryItem(name: "filter[search]", value: filter))
           }

           if let page = page {
               parameters.append(URLQueryItem(name: "page[number]", value: "\(page)"))
           }

           if let sort = aliasSortFilter.sort {
               let sortFilter: String = aliasSortFilter.sortDesc ? "-\(sort)" : sort
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
                    let errorMessage = error.localizedDescription
                    print("Error: \(httpResponse.statusCode) - \(error)")
                    self.loggingHelper.addLog(
                        importance: LogImportance.critical,
                        error: errorMessage,
                        method: "getAliases",
                        extra: ErrorHelper.getErrorMessage(data:
                                                            data
                                                          ))
                    completion(
                        nil,
                        ErrorHelper.getErrorMessage(data:
                                                        data
                                                   )
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
                let errorMessage = error?.localizedDescription ?? "Unknown error"
                print("Error: \(httpResponse.statusCode) - \(error)")
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: errorMessage,
                    method: "getSpecificRecipient",
                    extra: ErrorHelper.getErrorMessage(data:data))
                completion(
                    nil,
                    ErrorHelper.getErrorMessage(data:data)
                )
            }
        }
        
        task.resume()
    }}
