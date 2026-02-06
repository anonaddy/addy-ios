//
//  SettingsView.swift
//  addy
//
//  Created by Stijn van de Water on 06/02/2026.
//


import SwiftUI
import WatchKit
import addy_shared

struct SettingsView: View {
    @State private var storeLogs: Bool = false
    @State private var hasPairedDevices: Bool = false
    @State private var isShowingSendLogsProgress: Bool = false
    @EnvironmentObject var appState: AppState
    @StateObject private var connectivity = WatchConnectivityManager()
    @Environment(\.dismiss) private var dismiss

    private let settingsManager = SettingsManager(encrypted: false)
    private let encryptedSettingsManager = SettingsManager(encrypted: true)
    private let favoriteAliasHelper = FavoriteAliasHelper()

    var body: some View {
        List {

            Section("favorite_aliases") {
                Button {
                    
                    let cancelAction = WKAlertAction(title: String(localized: "cancel"), style: .cancel) {  }
                    let resetAction = WKAlertAction(title: String(localized: "clear"), style: .default) {
                       WKInterfaceDevice.current().play(.failure)
                    favoriteAliasHelper.clearFavoriteAliases()
                   }
                   
                   WKExtension.shared().visibleInterfaceController?.presentAlert(
                       withTitle: String(localized: "clear_favorites"),
                       message: String(localized: "clear_favorites_desc"),
                       preferredStyle: .alert,
                       actions: [cancelAction, resetAction]
                   )
                } label: {
                    Label("clear_favorites", systemImage: "star")
                }
            }

            Section("logs") {
                Toggle(isOn: $storeLogs) {
                    Text("store_logs")
                }
                .onChange(of: storeLogs) {
                    settingsManager.putSettingsBool(key: SettingsManager.Prefs.storeLogs, boolean: storeLogs)
                }

                Button {
                    sendLogsToPairedDevice()
                } label: {
                    if isShowingSendLogsProgress {
                        ProgressView()
                    } else {
                        Label("send_logs_to_device", systemImage: "iphone.gen3")
                    }
                }
            }

            Section("") {
                Button(role: .destructive) {
                    let cancelAction = WKAlertAction(title: String(localized: "cancel"), style: .cancel) {  }
                    let resetAction = WKAlertAction(title: String(localized: "reset"), style: .destructive) {
                       WKInterfaceDevice.current().play(.failure)
                       resetApp()
                   }
                   
                   WKExtension.shared().visibleInterfaceController?.presentAlert(
                       withTitle: String(localized: "reset_app"),
                       message: String(localized: "reset_app_desc"),
                       preferredStyle: .alert,
                       actions: [cancelAction, resetAction]
                   )
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Label("reset_app", systemImage: "arrow.counterclockwise")
                            .labelStyle(.titleOnly)  // Hide icon for main label
                        
                        Text("reset_app_label_desc")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                VStack(spacing: 0) {
                    Text("crafted_with_love_and_privacy").multilineTextAlignment(.center)
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")
                }
                .opacity(0.5)
                .frame(maxWidth: .infinity, alignment: .center)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())  // Removes all padding
            }
        }
        .listStyle(.carousel)
        .navigationTitle("settings")
        .onAppear {
            loadSettings()
        }
    }

    private func loadSettings() {
        storeLogs = settingsManager.getSettingsBool(key: SettingsManager.Prefs.storeLogs)
    }

    private func index(for minutes: Int) -> Int {
        switch minutes {
        case 15: return 1
        case 30: return 2
        case 60: return 3
        case 120: return 4
        default: return 2
        }
    }

    private func value(for index: Int) -> Int {
        switch index {
        case 1: return 15
        case 2: return 30
        case 3: return 60
        case 4: return 120
        default: return 30
        }
    }

    private func sendLogsToPairedDevice() {
        isShowingSendLogsProgress = true
        
        let logsJson = LoggingHelper().getLogs()
        connectivity.sendLogsToDevice(logs: logsJson, replyHandler: { success in
                isShowingSendLogsProgress = false
                
                let successAction = WKAlertAction(title: String(localized: "close") , style: .default) {  }
                WKInterfaceDevice.current().play(.success)
                WKExtension.shared().visibleInterfaceController?.presentAlert(
                    withTitle: String(localized: "success"),
                    message: String(localized: "logs_sent"),
                    preferredStyle: .alert,
                    actions: [successAction]
                )
                
                // Dismiss after 2s
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    WKExtension.shared().visibleInterfaceController?.dismiss()
                }
            
        }, errorHandler: { error in
                isShowingSendLogsProgress = false
                
                let okAction = WKAlertAction(title: String(localized: "close"), style: .default) {  }
                WKInterfaceDevice.current().play(.failure)
                WKExtension.shared().visibleInterfaceController?.presentAlert(
                    withTitle: String(localized: "error"),
                    message: error.localizedDescription,
                    preferredStyle: .alert,
                    actions: [okAction]
                )
        
        })
    }


    private func resetApp() {
        encryptedSettingsManager.clearSettingsAndCloseApp()
        self.appState.apiKey = nil
        dismiss()
    }
}
