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
    @EnvironmentObject var mainViewState: MainViewState
    
    @State private var isPresentingAppearanceBottomSheet: Bool = false
    
    @State private var storeLogs: Bool = false
    @State private var privacyMode: Bool = false
    @State private var biometricEnabled: Bool = false
    @State private var showPlayGround: Bool = false
    
    @Environment(\.openURL) var openURL
    @Binding var horizontalSize: UserInterfaceSizeClass
    
    enum ActiveAlert {
        case resetAppError, resetApp
    }
    @State private var showAlert = false
    @State private var activeAlert: ActiveAlert = .resetApp

    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
        
        if showPlayGround {
            PlayGround()
            
        } else{
            // Prevent having a navstack inside a navstack when the view is openen on a compact level (inside the profilesheet)
            Group() {
                if horizontalSize == .regular {
                    NavigationStack(){
                        appSettingsViewBody
                    }
                } else {
                    appSettingsViewBody
                }
            }
        }
    }
    
    private var appSettingsViewBody: some View {
        List {
            
            if mainViewState.permissionsRequired || mainViewState.backgroundAppRefreshDenied {
                Section {
                    if mainViewState.permissionsRequired {
                        AddySection(title: String(localized: "permissions_required"), description: String(localized: "notification_permissions_required_desc"), leadingSystemimage: "bell.fill", leadingSystemimageColor: .red){
                            requestNotificationPermission()
                        }
                    }
                    
                    if mainViewState.backgroundAppRefreshDenied {
                        AddySection(title: String(localized: "permissions_required"), description: String(localized: "background_app_refresh_denied_desc"), leadingSystemimage: "arrow.clockwise.square.fill", leadingSystemimageColor: .red){
                            requestBackgroundAppRefresh()
                        }
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
                    
                    if privacyMode {
                        // Clear shortcuts
                        UIApplication.shared.shortcutItems = []
                    }
                    
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
                    activeAlert = .resetApp
                    showAlert = true
                }
                
                
                NavigationLink(destination: DeleteAccountConfirmationView()){
                    AddySection(title: String(localized: "delete_account"), description: String(localized: "delete_account_desc"), leadingSystemimage: "person.fill.badge.minus", leadingSystemimageColor: .red)
                }
                
            } header: {
                Text(String(localized: "manage_your_data"))
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
                Text(String(localized: "about_this_app"))
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
                        .onLongPressGesture {
#if DEBUG
                            self.showPlayGround = true
#endif
                        }
                }
                
                
            }
        }
        .navigationTitle(String(localized: "settings"))
        .navigationBarTitleDisplayMode(horizontalSize == .regular ? .automatic : .inline)
        .toolbar {
            if horizontalSize == .regular {
                FailedDeliveriesIcon(horizontalSize: $horizontalSize).environmentObject(mainViewState)
                AccountNotificationsIcon().environmentObject(mainViewState)
                ProfilePicture().environmentObject(mainViewState)
            }
        }
        .alert(isPresented: $showAlert, content: {
            switch activeAlert {
                
            case .resetAppError:
                return Alert(title: Text(String(localized: "reset_app")),message:Text(String(localized: "reset_app_logout_failure")), primaryButton: .default(Text(String(localized: "reset_app_anyways"))), secondaryButton: .cancel())
            case .resetApp:
                return Alert(title: Text(String(localized: "reset_app")), message: Text(String(localized: "reset_app_confirmation_desc")), primaryButton: .destructive(Text(String(localized: "reset_app"))){
                    Task {
                        await logoutAndReset()
                    }
                }, secondaryButton: .cancel())
            }
            
           
        })
        .sheet(isPresented: $isPresentingAppearanceBottomSheet, content: {
            NavigationStack {
                AppearanceBottomSheet()
            }
            .presentationDetents([.medium, .large])
        })
        
    }
    
    func logoutAndReset() async {
        let networkHelper = NetworkHelper()
        do {
            if let statusCode = try await networkHelper.logout() {
                if statusCode == 204 {
                    DispatchQueue.main.async {
                        mainViewState.isPresentingProfileBottomSheet = false
                        SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                    }
                } else {
                    activeAlert = .resetAppError
                    showAlert = true
                }
            }
        } catch {
            activeAlert = .resetAppError
            showAlert = true
        }
       
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
        }
    }
    
    func requestNotificationPermission() {
        
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            if granted {
                //print("Permission granted for local notifications")
            } else {
                if let error = error {
                    //print("Error requesting permission: \(error.localizedDescription)")
                    
                    DispatchQueue.main.async {
                        if let appSettings = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(appSettings) {
                            UIApplication.shared.open(appSettings)
                        }
                    }
                } else {
                    //print("Permission denied for local notifications")
                    DispatchQueue.main.async {
                        if let appSettings = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(appSettings) {
                            UIApplication.shared.open(appSettings)
                        }
                    }
                }
            }
        }
        
        
    }
    
    func requestBackgroundAppRefresh() {
        if let appSettings = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(appSettings) {
            UIApplication.shared.open(appSettings)
        }
    }
}

struct AppSettingsView_Previews: PreviewProvider {
    
    static var previews: some View {
        @State var userInterfaceSizeClass: UserInterfaceSizeClass =  UserInterfaceSizeClass.regular
        AppSettingsView(horizontalSize: $userInterfaceSizeClass)
            .environmentObject(MainViewState.shared)
        
    }
}
