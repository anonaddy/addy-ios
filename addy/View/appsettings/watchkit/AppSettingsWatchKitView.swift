//
//  AppSettingsWatchKitView.swift
//  addy
//
//  Created by Stijn van de Water on 08/02/2026.
//

import addy_shared
import SwiftUI

struct AppSettingsWatchKitView: View {
    @State private var showAlert: Bool = false
    @State private var errorAlertMessage = ""
    @State private var enableWatchKitQuickSetupDialog: Bool = false

    var body: some View {
        #if DEBUG
            let _ = Self._printChanges()
        #endif
        List {
            AddySettingsHeader(title: String(localized: "addyio_for_watchkit"), description: String(localized: "addyio_for_watchkit_desc"), systemimage: "applewatch", systemimageColor: .mint)

            //TODO: Tips?
            
            Section {
                NavigationLink(destination: LogViewerView(showWatchOsLogs: true)) {
                    AddySection(title: String(localized: "view_store_logs"), description: String(localized: "view_store_logs_watchkit_desc"), leadingSystemimage: "exclamationmark.magnifyingglass", leadingSystemimageColor: .blue)
                }

            } header: {
                Text(String(localized: "logs", bundle: Bundle(for: SharedData.self)))
            }.textCase(nil)
            
            
            Section {
                AddyToggle(isOn: $enableWatchKitQuickSetupDialog, title: String(localized: "wearable_quick_setup"), description: String(localized: "wearable_quick_setup_desc"), leadingSystemimage: "bell")
                    .onAppear {
                        self.enableWatchKitQuickSetupDialog = MainViewState.shared.settingsManager.getSettingsBool(key: .enableWatchKitQuickSetupDialog, default: true)
                    }
                    .onChange(of: enableWatchKitQuickSetupDialog) {
                        MainViewState.shared.settingsManager.putSettingsBool(key: .enableWatchKitQuickSetupDialog, boolean: enableWatchKitQuickSetupDialog)
                    }

            } header: {
                Text(String(localized: "this_device"))
            }.textCase(nil)
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(String(localized: "could_not_check_for_updates")),
                message: Text(errorAlertMessage)
            )
        }
        .navigationTitle(String(localized: "addyio_for_watchkit"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AppSettingsWatchKitView_Previews: PreviewProvider {
    static var previews: some View {
        AppSettingsWatchKitView()
    }
}
