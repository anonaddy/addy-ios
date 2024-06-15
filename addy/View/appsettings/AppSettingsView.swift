//
//  AppSettingsView.swift
//  addy
//
//  Created by Stijn van de Water on 10/06/2024.
//

import SwiftUI
import addy_shared
import LocalAuthentication

struct AppSettingsView: View {
    @Binding var isShowingAppSettingsView: Bool
    
    @State private var isPresentingAppearanceBottomSheet: Bool = false
    
    @State private var storeLogs: Bool = false
    @State private var privacyMode: Bool = false
    @State private var biometricEnabled: Bool = false
    
    
    @State private var hasNotificationPermission = false
    
    @Environment(\.openURL) var openURL
    
    var body: some View {
        NavigationStack(){
            List {
                
                if !hasNotificationPermission {
                    Section {
                        AddySection(title: String(localized: "permissions_required"), description: String(localized: "notification_permissions_required_desc"), leadingSystemimage: "bell.fill", leadingSystemimageColor: .red){
                            requestNotificationPermission()
                        }
                    } header: {
                        Text(String(localized: "requires_attention"))
                    }
                }
                
                Section {
                    AddySection(title: String(localized: "appearance"), description: String(localized: "appearance_desc"), leadingSystemimage: "app.dashed",leadingSystemimageColor: .orange){
                        isPresentingAppearanceBottomSheet = true
                    }
                    NavigationLink(destination: AppSettingsUpdateView()) {
                        AddySection(title: String(localized: "addyio_updater"), description: String(localized: "addyio_updater_desc"), leadingSystemimage: "arrow.down.circle.dotted", leadingSystemimageColor: .blue)
                    }
                    NavigationLink(destination: AppSettingsFeaturesView()) {
                        AddySection(title: String(localized: "features_and_integrations"), description: String(localized: "features_and_integrations_desc"), leadingSystemimage: "star.fill", leadingSystemimageColor: .accentColor){
                            isPresentingAppearanceBottomSheet = true
                        }
                    }
                    
                    //                    AddySection(title: String(localized: "addyio_for_wearables"), leadingSystemimage: "applewatch", leadingSystemimageColor: .accentColor){
                    //
                    //                        }
                    
                    
                    //                    AddySection(title: String(localized: "addyio_backup"), leadingSystemimage: "square.and.arrow.up", leadingSystemimageColor: .accentColor){
                    //                        isPresentingAppearanceBottomSheet = true
                    //                        }
                    
                    
                    AddyToggle(isOn: $biometricEnabled, title: String(localized: "security"),description: !LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) ? String(localized: "biometric_error") : String(localized: "security_desc"), leadingSystemimage: "faceid", leadingSystemimageColor: .green).onAppear {
                        self.biometricEnabled = MainViewState.shared.encryptedSettingsManager.getSettingsBool(key: .biometricEnabled)
                    }
                    .onChange(of: biometricEnabled) {
                        // Only fire when the value is NOT the same as the value already in the model
                        if (biometricEnabled != MainViewState.shared.encryptedSettingsManager.getSettingsBool(key: .biometricEnabled)){
                            faceIdAuthentication(shouldEnableBiometrics: biometricEnabled)
                        }
                    }
                    .disabled(!LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil))
                    
                    AddyToggle(isOn: $privacyMode, title: String(localized: "privacy_mode"), description: String(localized: "privacy_mode_desc"), leadingSystemimage: "lock.shield.fill", leadingSystemimageColor: .green).onAppear {
                        self.privacyMode = MainViewState.shared.encryptedSettingsManager.getSettingsBool(key: .privacyMode)
                    }
                    .onChange(of: privacyMode) {
                        MainViewState.shared.encryptedSettingsManager.putSettingsBool(key: .privacyMode, boolean: privacyMode)
                        
                    }
                } header: {
                    Text(String(localized: "general"))
                }
                
                Section {
                    
                    AddyToggle(isOn: $storeLogs, title: String(localized: "store_logs"), description: String(localized: "store_logs_desc"), leadingSystemimage: "exclamationmark.magnifyingglass")
                        .onAppear {
                            self.storeLogs = MainViewState.shared.settingsManager.getSettingsBool(key: .storeLogs)
                        }
                        .onChange(of: storeLogs) {
                            MainViewState.shared.settingsManager.putSettingsBool(key: .storeLogs, boolean: storeLogs)
                        }
                    
                    NavigationLink(destination: LogViewerView()) {
                        AddySection(title: String(localized: "view_store_logs"))
                    }
                    
                } header: {
                    Text(String(localized: "advanced"))
                }
                
                Section {
                    AddySection(title: String(localized: "reset_app"), description: String(localized: "reset_app_desc"), leadingSystemimage: "gobackward", leadingSystemimageColor: .red){
                        isPresentingAppearanceBottomSheet = true
                    }
                    
                }
                
                Section {
                    AddySection(title: String(localized: "addyio_help"), description: String(localized: "visit_addyio_helps_section"), leadingSystemimage: "questionmark.circle", leadingSystemimageColor: .primaryColorStatic){
                        openURL(URL(string: "https://addy.io/help/")!)
                    }
                    AddySection(title: String(localized: "faq"), description: String(localized: "faq_desc"), leadingSystemimage: "questionmark.bubble.fill", leadingSystemimageColor: .primaryColorStatic){
                        openURL(URL(string: "https://addy.io/faq/")!)
                    }
                } header: {
                    Text(String(localized: "app_name"))
                }
                
                Section {
                    AddySection(title: String(localized: "github_project"), description: String(localized: "github_project_desc"), leadingSystemimage: "swift", leadingSystemimageColor: .primaryColorStatic){
                        openURL(URL(string: "https://github.com/anonaddy/addy-ios")!)
                    }
                    AddySection(title: String(localized: "report_an_issue"), description: String(localized: "report_an_issue_desc"), leadingSystemimage: "ladybug.fill", leadingSystemimageColor: .primaryColorStatic){
                        openURL(URL(string: "https://github.com/anonaddy/addy-ios/issues/new")!)
                    }
                    AddySection(title: String(localized: "contributors"), description: String(localized: "contributors_list"), leadingSystemimage: "person.2.fill", leadingSystemimageColor: .primaryColorStatic){}
                    
                } header: {
                    Text(String(localized: "more"))
                } footer: {
                    
                    VStack {
                        
                        
                        Spacer()
                        Image("stjin_full_logo").renderingMode(.template).resizable().scaledToFit().frame(maxHeight: 40).grayscale(1).opacity(0.7).onTapGesture {
                            openURL(URL(string: "https://stjin.host")!)
                        }
                        let appVersion = "v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")"
                        
                        Text(String(localized: "crafted_with_love_and_privacy"))
                            .multilineTextAlignment(.center)
                            .font(.system(size: 14))
                            .frame(maxWidth: .infinity)
                        Text(appVersion)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 16))
                            .frame(maxWidth: .infinity)
                    }
                    
                    
                }
            }
            .navigationTitle(String(localized: "settings"))
            .navigationBarItems(leading: Button(action: {
                self.isShowingAppSettingsView = false
            }) {
                if UIDevice.current.userInterfaceIdiom != .pad {
                    Text(String(localized: "close"))
                }
            })
            .sheet(isPresented: $isPresentingAppearanceBottomSheet, content: {
                NavigationStack {
                    AppearanceBottomSheet()
                }
            })
        }.onAppear(perform: {
            checkNotificationPermission()
        })
    }
    
    
    func faceIdAuthentication(shouldEnableBiometrics: Bool){
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error){
            let reason = "Authenticate to access the app"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason){ success, authenticationError in
                if success{
                    DispatchQueue.main.async {
                        // Also unlock the app to prevent the app from immediately locking
                        MainViewState.shared.isUnlocked = true
                    }
                    
                    
                    MainViewState.shared.encryptedSettingsManager.putSettingsBool(key: .biometricEnabled, boolean: shouldEnableBiometrics)
                }else{
                    biometricEnabled = !shouldEnableBiometrics
                }
            }
        } else{
            // Device does not support Face ID or Touch ID
            print("Biometric authentication unavailable")
        }
    }
    
    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.hasNotificationPermission = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestNotificationPermission() {
        
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            self.hasNotificationPermission = granted
            if granted {
                print("Permission granted for local notifications")
            } else {
                if let error = error {
                    print("Error requesting permission: \(error.localizedDescription)")
                } else {
                    print("Permission denied for local notifications")
                }
            }
        }
        
        
    }
}

struct AppSettingsView_Previews: PreviewProvider {
    
    static var previews: some View {
        @State var isShowingAppSettingsView = false
        
        AppSettingsView(isShowingAppSettingsView: $isShowingAppSettingsView)
        
    }
}
