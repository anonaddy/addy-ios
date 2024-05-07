//
//  NetworkHelper.swift
//  addy
//
//  Created by Stijn van de Water on 07/05/2024.
//

import Foundation
import Alamofire

public class NetworkHelper {
    private let loggingHelper: LoggingHelper
    private let encryptedSettingsManager: SettingsManager
    
    
    
    public init() {
        self.loggingHelper = LoggingHelper()
        self.encryptedSettingsManager = SettingsManager(encrypted: true)
        AddyIo.API_BASE_URL = encryptedSettingsManager.getSettingsString(key: .baseUrl) ?? AddyIo.API_BASE_URL
    }
    
    private func getHeaders(apiKey: String? = nil) -> HTTPHeaders {
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
    
    private func getAlamofireResponse(response: AFDataResponse<Any>) -> Data? {
        switch response.result {
        case .success(let data):
            return data as? Data
        case .failure:
            return nil
        }
    }
    
    private func invalidApiKey() {
            print(String(localized: "api_key_invalid"))
            // TODO reset app
        
    }
    
    func downloadBody(url: String, completion: @escaping (String?, String?) -> Void) {
        AF.request(url).response { response in
            switch response.result {
            case .success(let data):
                completion(String(data: data ?? Data(), encoding: .utf8), nil)
            case .failure(let error):
                completion(nil, error.localizedDescription)
            }
        }
    }
    
    public func verifyApiKey(baseUrl: String, apiKey: String, completion: @escaping (String?) -> Void) {
        AddyIo.API_BASE_URL = baseUrl
        debugPrint(AddyIo.API_URL_ACCOUNT_DETAILS)
        AF.request(AddyIo.API_URL_ACCOUNT_DETAILS, headers: getHeaders(apiKey: apiKey)).response { response in
            switch response.response?.statusCode {
            case 200:
                completion("200")
            default:
                debugPrint("AFA", "\(String(describing: response.response?.statusCode)) - \(String(describing: response.error?.errorDescription))")
                self.loggingHelper.addLog(
                    importance: LogImportance.critical,
                    error: String(describing: response.error?.errorDescription),
                    method: "verifyApiKey",
                    extra: String(describing: response.error.debugDescription))
                completion(response.error?.errorDescription)
            }
        }
    }
    
    func getAddyIoInstanceVersion(completion: @escaping (Version?, String?) -> Void) {
        AF.request(AddyIo.API_URL_APP_VERSION, headers: getHeaders()).response { response in
            switch response.result {
            case .success(let data):
                let decoder = JSONDecoder()
                if let data = data, let version = try? decoder.decode(Version.self, from: data) {
                    completion(version, nil)
                } else {
                    completion(nil, "Failed to decode version")
                }
            case .failure(let error):
                completion(nil, error.localizedDescription)
            }
        }
    }
}
