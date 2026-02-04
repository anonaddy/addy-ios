//
//  WatchConnectivityManager.swift
//  addy
//
//  Created by Stijn van de Water on 03/02/2026.
//


import SwiftUI
import WatchConnectivity
import WatchKit
import addy_shared
import Combine

class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    @Published var isReachable = false
    private var retryTimer: Timer?
    private var requestId: String?
    @Published var shouldNagiPhone = true
    @Published var statusText: String = String(localized: "setup_watchos_check_paired_device_status_1")
    var onSetupComplete: ((String) -> Void)?


    
    override init() {
        super.init()
        setupSession()
        startPeriodicNagging()
    }
    
    private func setupSession() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        
#if DEBUG
        print("WatchConnectivityManager, received message: \(message)")
#endif

        DispatchQueue.main.async {
            if message["setup_app"] as? Bool == true {
                
                
                guard let request_id = message["request_id"] as? String,
                              let baseUrl = message["base_url"] as? String,
                                let apiKey = message["api_key"] as? String else {
                            replyHandler(["error": "Invalid message"]) //TODO: to localizable
                            return
                        }
                
                
#if DEBUG
                print("Got config, request_id: \(request_id), baseUrl: \(baseUrl), apiKey: \(apiKey)")
#endif
                
                if request_id == self.requestId {
                    // TODO: This is not working
                    let encryptedSettingsManager = SettingsManager(encrypted: true)
                    encryptedSettingsManager.putSettingsString(key: SettingsManager.Prefs.apiKey, string: apiKey)
                    encryptedSettingsManager.putSettingsString(key: SettingsManager.Prefs.baseUrl, string: baseUrl)
                    
                    let test = encryptedSettingsManager.getSettingsString(key: SettingsManager.Prefs.apiKey) ?? "nope"
                    
                    
                    DispatchQueue.main.async {
                        self.onSetupComplete?(apiKey)
                    }
                } else {
#if DEBUG
                print("Received message for wrong request_id")
#endif
                }
                
                
            }
            
            if message["open_alias"] as? Bool == true {
                // Trigger your open alias logic here
                //self.showAliasSheet = true
            }

            if message["reset"] as? Bool == true {
                // Trigger your reset logic here
                //self.performReset()
            }
        }
    }
    
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            if self.isReachable {
                self.nagForSetup() // Send immediately when connected
            }
        }
    }
    
    private func startPeriodicNagging() {
        retryTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { _ in
            if self.shouldNagiPhone {
                self.nagForSetup()
            }
        }
    }
    
    private func nagForSetup() {
        guard WCSession.default.isReachable else { return }
        #if DEBUG
        print("🐛 Nagging iPhone for setup...")
        #endif
        let watchName = WKInterfaceDevice.current().name
        self.statusText = String(localized: "setup_watchos_check_paired_device_status_1")
        // Send requestSetup to iPhone, including watchName and a unique ID for later confirmation (to make sure the incoming configuration is really meant for this Watch
        WCSession.default.sendMessage(["request_setup": true, "watch_name": watchName, "request_id": UUID().uuidString], replyHandler: { reply in
            DispatchQueue.main.async {
                if reply["setup_request_received"] as? Bool == true {
                    if let requestId = reply["request_id"] as? String {
                        // setupRequest was confirmed by iPhone, we can stop nagging now, and we know the unique ID to listen to for further information
#if DEBUG
                        print("Request with ID \(requestId) confirmed, no more nagging needed.")
#endif
                        self.statusText = String(localized: "setup_watchos_check_paired_device_status_2")
                        self.shouldNagiPhone = false
                        self.requestId = requestId
                    }
                }
            }
        }, errorHandler: { error in
            LoggingHelper().addLog(
                importance: LogImportance.warning,
                error: "Error sending message to watch: \(error.localizedDescription)",
                method: "SetupView",
                extra: nil
            )
        })
    }
}
