//
//  iOSConnectivityManager.swift
//  addy
//
//  Created by Stijn van de Water on 01/02/2026.
//

import addy_shared
import Combine
import Foundation
import WatchConnectivity

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

    func session(_: WCSession,
                 activationDidCompleteWith _: WCSessionActivationState,
                 error _: Error?)
    {
        #if DEBUG
            print("iOS Session activation completed")
        #endif
    }

    func sessionDidBecomeInactive(_: WCSession) {
        // Can hold off on sending data until session is active again
    }

    func sessionDidDeactivate(_: WCSession) {
        // Activate a new session
        WCSession.default.activate()
    }

    func session(_: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        #if DEBUG
            print("iOSConnectivityManager, received message: \(message)")
        #endif

        DispatchQueue.main.async {
            if message["request_setup"] as? Bool == true {
                guard let watchName = message["watch_name"] as? String,
                      let requestId = message["request_id"] as? String
                else {
                    replyHandler(["error": "Invalid message"]) // TODO: to localizable
                    return
                }
                self.watchName = watchName
                self.requestId = requestId

                if SettingsManager(encrypted: true).getSettingsString(key: .apiKey) != nil {
                    if SettingsManager(encrypted: false).getSettingsBool(key: .enableWatchKitQuickSetupDialog, default: true) {
                        self.showSetupSheet = true
                        NotificationHelper().createSetupWatchkitNotification(watchName: watchName)
                    }
                } else {
                    NotificationHelper().createSetupAppFirstWatchkitNotification()
                }
                replyHandler(["request_setup_confirm": true, "request_id": requestId])
            }

            if message["show_alias"] as? Bool == true {
                NotificationHelper().createOpenAliasFromWatchkitNotification(
                    id: message["alias_id"] as! String,
                    email: message["email"] as! String
                )
                replyHandler(["show_alias_confirm": true])
            }

            if message["show_logs"] as? Bool == true {
                var logs = message["logs"] as? String
                LoggingHelper(logFile: .watchosLogs).setList(logs: stringToLogs(logs ?? ""))
                LoggingHelper().addLog(
                    importance: LogImportance.info,
                    error: "User requested to show logs",
                    method: "session(_:didReceiveMessage:replyHandler:)",
                    extra: "\(String(describing: logs))"
                )
                NotificationHelper().createOpenLogsFromWatchkitNotification()
                // Trigger your reset logic here
                replyHandler(["show_logs_confirm": true])
            }
        }
    }

    func setupAppleWatchApp(requestId: String, baseUrl: String, apiKey: String) {
        WCSession.default.sendMessage(["setup_app": true, "request_id": requestId, "base_url": baseUrl, "api_key": apiKey], replyHandler: { _ in
        }, errorHandler: { error in
            LoggingHelper().addLog(
                importance: LogImportance.critical,
                error: "Failed to setup Apple Watch app: \(error)",
                method: "setupAppleWatchApp",
                extra: error.localizedDescription
            )
        })
    }
}
