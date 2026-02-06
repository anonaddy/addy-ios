//
//  iOSConnectivityManager.swift
//  addy
//
//  Created by Stijn van de Water on 01/02/2026.
//


import Foundation
import WatchConnectivity
import Combine

final class iOSConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    @Published var showSetupSheet = false
    @Published var watchName = ""
    @Published var requestId = ""

    override init() {
        super.init()
        setupSession()
    }

    private func setupSession() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
#if DEBUG
        print("iOS Session activation completed")
#endif
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        // Can hold off on sending data until session is active again
    }
    func sessionDidDeactivate(_ session: WCSession) {
        // Activate a new session
        WCSession.default.activate()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
#if DEBUG
        print("iOSConnectivityManager, received message: \(message)")
#endif

        DispatchQueue.main.async {
            if message["request_setup"] as? Bool == true {
                self.showSetupSheet = true
                
                
                guard let watchName = message["watch_name"] as? String,
                              let requestId = message["request_id"] as? String else {
                            replyHandler(["error": "Invalid message"]) //TODO: to localizable
                            return
                        }
                self.watchName = watchName
                self.requestId = requestId
                
                replyHandler(["request_setup_confirm": true, "request_id": requestId])
                
            }
            
            if message["show_alias"] as? Bool == true {
                replyHandler(["show_alias_confirm": true])
            }
            
            if message["show_logs"] as? Bool == true {
                // Trigger your reset logic here
                replyHandler(["show_logs_confirm": true])
            }
        }
    }
    
    
    func setupAppleWatchApp(requestId: String, baseUrl: String, apiKey: String) {
        WCSession.default.sendMessage(["setup_app": true, "request_id": requestId, "base_url": baseUrl, "api_key": apiKey], replyHandler: { reply in
        }, errorHandler: { error in
            print("Failed to send confirmation: \(error)")
        })
    }
}
