//
//  AppSettingsUpdateView.swift
//  addy
//
//  Created by Stijn van de Water on 12/06/2024.
//

import SwiftUI
import addy_shared

struct AppSettingsUpdateView: View {
    @State private var showAlert: Bool = false
    
    @State private var errorAlertTitle = ""
    @State private var errorAlertMessage = ""
    
    @State private var isCheckingForUpdates: Bool = false
    
    @State var updateStatusTitle = String(localized: "check_for_updates")
    @State var updateStatusDescription = String(localized: "check_for_updates_desc")
    
    @State private var notifyUpdates: Bool = false
    @State private var isPresentingChangelogBottomSheet = false
    
    let settingsManager = SettingsManager(encrypted: false)

    @Environment(\.openURL) var openURL

    var body: some View {
        List {
            
            Section {
                AddySection(title: updateStatusTitle, description: updateStatusDescription, leadingSystemimage: "arrow.down.circle.dotted", leadingSystemimageColor: .blue){
                    self.checkForUpdates()
                    }
                
                AddyToggle(isOn: $notifyUpdates, title: String(localized: "update_notify_title"), description: String(localized: "update_notify_desc"), leadingSystemimage: "bell.fill", leadingSystemimageColor: .green).onAppear {
                    self.notifyUpdates = settingsManager.getSettingsBool(key: .notifyUpdates)
                }
                .onChange(of: notifyUpdates) {
                    settingsManager.putSettingsBool(key: .notifyUpdates, boolean: notifyUpdates)
                }
                
            } header: {
                Text(String(localized: "general"))
            }
            
            Section {
                AddySection(title: String(localized: "changelog"), description: String(localized: "see_this_version_changelogs"), leadingSystemimage: "plus.forwardslash.minus", leadingSystemimageColor: .orange){
                        isPresentingChangelogBottomSheet = true
                    }
                
                AddySection(title: String(localized: "previous_changelogs"), description: String(localized: "previous_changelogs_desc"), leadingSystemimage: "rectangle.stack.fill", leadingSystemimageColor: .orange){
                        openURL(URL(string: "https://github.com/anonaddy/addy-ios/blob/master/CHANGELOG.md")!)
                    }
            } header: {
                Text(String(localized: "changelog"))
            } footer: {
                Label {
                    let appVersion = "v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")"
                    Text(String(format: String(localized: "version_s"), appVersion))
                } icon: {
                    Image(systemName: "info.circle")
                }
                
            }
            
        }.refreshable {
                self.checkForUpdates()
        }.sheet(isPresented: $isPresentingChangelogBottomSheet, content: {
            NavigationStack {
                ChangelogBottomSheet()
            }
        })
        .alert(isPresented: $showAlert) {
            return Alert(
                title: Text(errorAlertTitle),
                message: Text(errorAlertMessage)
            )
        }
        .navigationTitle(String(localized: "addyio_updater"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: {
            if settingsManager.getSettingsBool(key: .notifyUpdates){
                DispatchQueue.global(qos: .background).async {
                    self.checkForUpdates()
                }
            }
        })
    }
    
    private func checkForUpdates(){
        Updater().isUpdateAvailable { updateAvailable, latestVersion, isRunningFutureVersion in
            DispatchQueue.main.async {
                let appVersion = "v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")"

                if (updateAvailable){
                    updateStatusTitle = String(localized: "new_update_available")
                    updateStatusDescription = String(format: String(localized: "new_update_available_version"), appVersion, latestVersion ?? "")
                } else if (isRunningFutureVersion) {
                    updateStatusTitle = String(localized: "greetings_time_traveller")
                    updateStatusDescription = String(localized: "greetings_time_traveller_desc")
                } else {
                    updateStatusTitle = String(localized: "no_new_update_available")
                    updateStatusDescription = String(localized: "no_new_update_available_desc")
                }
            }
        }
    }
}

struct AppSettingsUpdateView_Previews: PreviewProvider {

    static var previews: some View {
        AppSettingsUpdateView()
    }
}
