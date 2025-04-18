//
//  AppSettingsFeaturesNotifyApiTokenExpiryView.swift
//  addy
//
//  Created by Stijn van de Water on 16/06/2024.
//

import SwiftUI
import addy_shared

struct AppSettingsFeaturesNotifyApiTokenExpiryView: View {
    
    @State var notifyApiTokenExpiry: Bool = false
    @State var isShowingAddApiBottomSheet: Bool = false
    @State var apiExpiryText: String = String(localized: "obtaining_information")
    
    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
        List {
            Image("feature_notify_api_token_expiry").resizable().scaledToFit().frame(maxWidth: .infinity, alignment: .center).listRowInsets(EdgeInsets())
            
            Section {
                AddyToggle(isOn: $notifyApiTokenExpiry, title: String(localized: "enable_feature"), description: String(localized: "notify_api_token_expiry_feature_section_desc"))
                    .onAppear {
                        self.notifyApiTokenExpiry = MainViewState.shared.settingsManager.getSettingsBool(key: .notifyApiTokenExpiry)
                    }
                    .onChange(of: notifyApiTokenExpiry) {
                        // Only fire when the value is NOT the same as the value already in the model
                        if (notifyApiTokenExpiry != MainViewState.shared.settingsManager.getSettingsBool(key: .notifyApiTokenExpiry)){
                            MainViewState.shared.settingsManager.putSettingsBool(key: .notifyApiTokenExpiry, boolean: notifyApiTokenExpiry)
                            BackgroundWorkerHelper().scheduleAppRefresh()
                        }
                    }
                
                AddySection(title: String(localized: "update_api_token_now"), description: String(localized: "update_api_token_now_desc")){
                    isShowingAddApiBottomSheet = true
                }
            } footer: {
                VStack(alignment: .leading){
                    Text(String(localized: "feature_api_token_expiry_notification_desc"))
                    Spacer()
                    Spacer()
                    Text(apiExpiryText)
                }.padding(.top)
                
            }
        }.task {
                await checkTokenExpiry()
        }
        .sheet(isPresented: $isShowingAddApiBottomSheet) {
            let baseUrl = MainViewState.shared.encryptedSettingsManager.getSettingsString(key: .baseUrl)
            NavigationStack {
                AddApiBottomSheet(apiBaseUrl: baseUrl, addKey: addKey(apiKey:_:)).environmentObject(MainViewState.shared)
            }
            .presentationDetents([.large])
        }
        .navigationTitle(String(localized: "feature_api_token_expiry_notification"))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func addKey(apiKey: String, _: String) {
        MainViewState.shared.encryptedSettingsManager.putSettingsString(key: .apiKey, string: apiKey)
        isShowingAddApiBottomSheet = false
        
        Task {
            await checkTokenExpiry()
        }
    }
    
    private func checkTokenExpiry() async {
        do {
            let apiTokenDetails = try await NetworkHelper().getApiTokenDetails()
            if let apiTokenDetails = apiTokenDetails {
                if let expiresAt = apiTokenDetails.expires_at {
                    let expiryDate = try DateTimeUtils.convertStringToLocalTimeZoneDate(expiresAt) // Get the expiry date
                    let text = expiryDate.futureDateDisplay() // Use the new method here
                    apiExpiryText = String(format: NSLocalizedString("current_api_token_expiry_date", comment: ""), apiTokenDetails.name, text)
                } else {
                    apiExpiryText = String(format: NSLocalizedString("current_api_token_expiry_date_never", comment: ""), apiTokenDetails.name, AddyIo.API_BASE_URL)
                }
            } else {
                apiExpiryText = String(format: NSLocalizedString("current_api_token_expiry_date_unknown", comment: ""), AddyIo.API_BASE_URL)
            }
        } catch {
            // Panic
            LoggingHelper().addLog(
                importance: LogImportance.critical,
                error: "Could not parse expiryDate",
                method: "checkTokenExpiry",
                extra: error.localizedDescription)
            
            apiExpiryText = String(format: NSLocalizedString("current_api_token_expiry_date_unknown", comment: ""), AddyIo.API_BASE_URL)
        }
    }

    
}

#Preview {
    AppSettingsFeaturesNotifyApiTokenExpiryView()
}
