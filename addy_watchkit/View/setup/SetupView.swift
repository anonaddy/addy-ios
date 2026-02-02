//
// SetupView.swift
// addy
//
// Created by Stijn van de Water on 01/02/2026.
//

import SwiftUI
import WatchConnectivity
import WatchKit
import addy_shared
import Combine

struct SetupView: View {
    @State private var isAnimating = false
    @State private var hasPairedDevice = false
    @EnvironmentObject var appState: AppState
    @StateObject private var connectivity = WatchConnectivityManager()
    @State private var displayedText = String(localized: "setup_watchos_check_paired_device_status_1")


    var body: some View {
        Group {
            VStack(spacing: 20) {
                // Animated app icon
                Image("addy_icon")
                    .resizable()
                    .frame(width: 56, height: 56)

                VStack(spacing: 6) {
                    Text("setup_watchos_open_addyio")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                    Text("setup_watchos_check_paired_device")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                    Text(displayedText)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .animation(.easeInOut(duration: 0.3), value: displayedText)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            }
            .padding(.top, 40)
            .frame(minHeight: 300)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
        )
        .onAppear {
            isAnimating = true
        }
    }
}

class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    @Published var isReachable = false
    private var retryTimer: Timer?
    private var requestId: String?
    private var shouldNagiPhone = true

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
        retryTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
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
        // Send requestSetup to iPhone, including watchName and a unique ID for later confirmation (to make sure the incoming configuration is really meant for this Watch
        WCSession.default.sendMessage(["request_setup": true, "watch_name": watchName, "request_id": UUID().uuidString], replyHandler: { reply in
            DispatchQueue.main.async {
                if reply["setup_request_received"] as? Bool == true {
                    if let requestId = reply["request_id"] as? String {
                        // setupRequest was confirmed by iPhone, we can stop nagging now, and we know the unique ID to listen to for further information
#if DEBUG
                        print("Request with ID \(requestId) confirmed, no more nagging needed.")
#endif
                        //displayedText = String(localized: "setup_watchos_check_paired_device_status_2")
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
