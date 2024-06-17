//
//  MainView.swift
//  addy
//
//  Created by Stijn van de Water on 08/05/2024.
//

import SwiftUI
import addy_shared
import Lottie
import LocalAuthentication

class MainViewState: ObservableObject {
    
    static let shared = MainViewState() // Shared instance
    
    // MARK: NOTIFICATION ACTIONS
    @Published var aliasToDisable: String? = nil
    @Published var showAliasWithId: String? = nil
    // MARK: END NOTIFICATION ACTIONS
    
    @Published var isPresentingProfileBottomSheet = false

    @Published var selectedTab: Destination = .home

    @Published var showApiExpirationWarning = false
    @Published var isUnlocked = false

    @Published var encryptedSettingsManager = SettingsManager(encrypted: true)
    @Published var settingsManager = SettingsManager(encrypted: false)
    
    @Published var userResourceData: String? {
        didSet {
            userResourceData.map { encryptedSettingsManager.putSettingsString(key: .userResource, string: $0) }
        }
    }
    
    var userResource: UserResource? {
        get {
            if let jsonString = userResourceData,
               let jsonData = jsonString.data(using: .utf8) {
                let decoder = JSONDecoder()
                return try? decoder.decode(UserResource.self, from: jsonData)
            }
            return nil
        }
        set {
            if let newValue = newValue {
                let encoder = JSONEncoder()
                if let jsonData = try? encoder.encode(newValue),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    userResourceData = jsonString
                }
            }
        }
    }
    
    
    @Published var userResourceExtendedData: String? {
        didSet {
            userResourceExtendedData.map { encryptedSettingsManager.putSettingsString(key: .userResourceExtended, string: $0) }
        }
    }
    
    var userResourceExtended: UserResourceExtended? {
        get {
            if let jsonString = userResourceExtendedData,
               let jsonData = jsonString.data(using: .utf8) {
                let decoder = JSONDecoder()
                return try? decoder.decode(UserResourceExtended.self, from: jsonData)
            }
            return nil
        }
        set {
            if let newValue = newValue {
                let encoder = JSONEncoder()
                if let jsonData = try? encoder.encode(newValue),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    userResourceExtendedData = jsonString
                }
            }
        }
    }
    
}

struct MainView: View {
    @EnvironmentObject var mainViewState: MainViewState
    @Environment(\.scenePhase) var scenePhase
    
    @State private var apiTokenExpiryText = ""
    
    @State var isShowingAppSettingsView = false
    @State var isShowingFailedDeliveriesView = false
    @State var isShowingDomainsView = false
    @State private var isPresentingChangelogBottomSheet = false
    @State private var isShowingUsernamesView = false
    @State private var isShowingRulesView = false
    @State private var navigationPath = NavigationPath()
    @State private var showBiometricsNotAvailableAlert = false
    @State var isShowingAddApiBottomSheet: Bool = false
    @State var newFailedDeliveries : Int? = nil
    @Environment(\.horizontalSizeClass) var horizontalSize

    
    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
        
        if !mainViewState.encryptedSettingsManager.getSettingsBool(key: .biometricEnabled) || mainViewState.isUnlocked {
            Group {
                
                if mainViewState.userResourceData == nil || mainViewState.userResourceExtendedData == nil {
                    SplashView()
                } else {
                    tabView
                        .onAppear(perform: {
                            
                            // Schedule background tasks
                            BackgroundWorkerHelper().scheduleBackgroundWorker()
                            
                            // Check for changelog
                            let dictionary = Bundle.main.infoDictionary!
                            let currentVersionCode = Int(dictionary["CFBundleVersion"] as! String) ?? 0
                            if SettingsManager(encrypted: false).getSettingsInt(key: .versionCode) < currentVersionCode {
                                isPresentingChangelogBottomSheet = true
                            }
                            
                            SettingsManager(encrypted: false).putSettingsInt(key: .versionCode, int: currentVersionCode)
                        })
                        .alert(isPresented: $mainViewState.showApiExpirationWarning){
                            Alert(title: Text(String(localized: "api_token_about_to_expire")), message: Text(apiTokenExpiryText.isEmpty ? String(localized: "api_token_about_to_expire_desc_unknown_expiry_date") : String(format: String(localized:"api_token_about_to_expire_desc"), apiTokenExpiryText)), primaryButton: .default(Text(String(localized: "api_token_about_to_expire_option_1"))){
                                isShowingAddApiBottomSheet = true
                            }, secondaryButton: .cancel(Text(String(localized: "dismiss"))))
                        }
                        .sheet(isPresented: $isShowingAddApiBottomSheet) {
                            let baseUrl = MainViewState.shared.encryptedSettingsManager.getSettingsString(key: .baseUrl)
                            NavigationStack {
                                AddApiBottomSheet(apiBaseUrl: baseUrl, addKey: addKey(apiKey:baseUrl:))
                            }
                            .presentationDetents([.large])
                        }
                        .sheet(isPresented: $mainViewState.isPresentingProfileBottomSheet) {
                            NavigationStack {
                                ProfileBottomSheet(onNavigate: { destination in
                                    mainViewState.isPresentingProfileBottomSheet = false
                                    mainViewState.selectedTab = destination
                                }, isPresentingProfileBottomSheet: $mainViewState.isPresentingProfileBottomSheet, horizontalSize:  .constant(horizontalSize!))
                                .environmentObject(mainViewState)
                            }
                            .presentationDetents([.large])
                        }
                        .sheet(isPresented: $isPresentingChangelogBottomSheet, content: {
                            NavigationStack {
                                ChangelogBottomSheet()
                            }
                            .presentationDetents([.medium, .large])
                        })
                        .task {
                            // Upon launching the app, always check for token expiry
                            checkTokenExpiry()
                            checkForNewFailedDeliveries()
                        }
                }
            }
            // Makes sure the env obj is available to all the child views
            .environmentObject(mainViewState)
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .background {
                    // User closed the app to background, lock the app (only if neccessary of course)
                    if mainViewState.encryptedSettingsManager.getSettingsBool(key: .biometricEnabled){
                        self.mainViewState.isUnlocked = false
                    }
                }
                else if newPhase == .active {
                    // User opened the app from background
                    if mainViewState.aliasToDisable != nil{
                        mainViewState.selectedTab = .aliases
                    }
                    
                }
            }
        } else {
            ContentUnavailableView {
                Label(String(localized: "addyio_locked"), systemImage: "lock.fill")
            } description: {
                Text(String(localized: "addyio_locked_desc"))
            } actions: {
                Button(String(localized: "unlock")) {
                    authenticate()
                }
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .active {
                    // User opens the app and the app is not unlocked
                    
                    if mainViewState.encryptedSettingsManager.getSettingsBool(key: .biometricEnabled){
                        authenticate()
                    } else {
                        self.mainViewState.isUnlocked = true
                    }
                                    }
            }
            .onAppear(perform: {
                
            })
            .alert(String(localized: "authentication_splash_error_unavailable"), isPresented: $showBiometricsNotAvailableAlert) {
                Button(String(localized: "try_again"), role: .cancel) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        authenticate()
                    }
                    
                }
                Button(String(localized: "reset_app"), role: .destructive) {
                    // TODO: RESET THE APP
                }
                
            }
            
            
            
        }
        
        
    }
    
    private func checkTokenExpiry(){
        NetworkHelper().getApiTokenDetails { (apiTokenDetails, error) in
            if let expiresAt = apiTokenDetails?.expires_at {
                do {
                    let expiryDate = try DateTimeUtils.turnStringIntoLocalDateTime(expiresAt) // Get the expiry date
                    let currentDateTime = Date() // Get the current date
                    let deadLineDate = Calendar.current.date(byAdding: .day, value: -5, to: expiryDate) // Subtract 5 days from the expiry date
                    if let deadLineDate = deadLineDate, currentDateTime > deadLineDate {
                        // The current date is suddenly after the deadline date. It will expire within 5 days
                        // Show the api is about to expire alert
                        
                        DispatchQueue.main.async {
                            apiTokenExpiryText = expiryDate.futureDateDisplay()
                            mainViewState.showApiExpirationWarning = true
                        }
                    } else {
                        // The current date is not yet after the deadline date.
                    }
                } catch {
                    // Panic
                    LoggingHelper().addLog(
                        importance: LogImportance.critical,
                        error: "Could not parse expiresAt",
                        method: "checkTokenExpiry",
                        extra: error.localizedDescription)
                }
                
            }
            // If expires_at is null it will never expire
        }
    }
    
    /*
        This method checks if there are new failed deliveries
        It does this by getting the current failed delivery count, if that count is bigger than the failed deliveries in the cache that means there are new failed
        deliveries.

        As backgroundServiceCacheFailedDeliveriesCount is only updated in the service and in the FailedDeliveriesActivity that means that the red
        indicator is only visible if:

        - The activity has not been opened since there were new items.
        - There are more failed deliveries than the server cached last time (in which case the user should have got a notification)
         */
    
    //TODO: Refresh button to refresh this?
        private func checkForNewFailedDeliveries(){
            NetworkHelper().getFailedDeliveries { (result, _) in
                let currentFailedDeliveries = mainViewState.encryptedSettingsManager.getSettingsInt(key: .backgroundServiceCacheFailedDeliveriesCount)
                if (result?.data.count ?? 0 - currentFailedDeliveries) > 0 {
                    DispatchQueue.main.async {
                        newFailedDeliveries = (result?.data.count ?? 0) - currentFailedDeliveries
                    }
                }
            }
    }
    
    func authenticate() {
        let context = LAContext()
        var error: NSError?
        
        // check whether biometric authentication is possible
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // it's possible, so go ahead and use it
            let reason = String(localized: "addyio_locked")
            
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in
                // authentication has now completed
                if success {
                    DispatchQueue.main.async {
                        self.mainViewState.isUnlocked = true

                                }
                }
            }
        } else {
            showBiometricsNotAvailableAlert = true
        }
    }
    
    
    private func addKey(apiKey: String, baseUrl: String) {
        mainViewState.encryptedSettingsManager.putSettingsString(key: .apiKey, string: apiKey)
        isShowingAddApiBottomSheet = false
    }
    
    
    private var tabView: some View {
        TabView(selection: $mainViewState.selectedTab) {
            let destinations = horizontalSize == .regular ? Destination.allCases : Destination.iPhoneCases
    
            ForEach(destinations, id: \.self) { destination in
                destination.view(horizontalSize: .constant(horizontalSize!))
                        .tag(destination)
                        .tabItem {
                            Label(destination.title, systemImage: destination.systemImage)
                        }
                        .apply {
                            // Apply the badge to the failed deliveries item
                            if (destination == .failedDeliveries) {
                                $0.badge(newFailedDeliveries ?? 0)
                            } else {
                                $0.badge(0)
                            }
                        }
                    }
                }
        .apply {
            if #available(iOS 18.0, *) {
                $0.tabViewStyle(.sidebarAdaptable)
            } else {
                $0.tabViewStyle(.automatic)
            }
        }
    }
}

enum Destination: Hashable, CaseIterable {
    case home, aliases, recipients, usernames, domains, failedDeliveries, rules, settings
    
    
    static var iPhoneCases: [Destination] {
        return [.home, .aliases, .recipients]
    }
    
    var title: LocalizedStringKey {
        switch self {
        case .home: return "home"
        case .aliases: return "aliases"
        case .recipients: return "recipients"
        case .usernames: return "usernames"
        case .domains: return "domains"
        case .failedDeliveries: return "failed_deliveries"
        case .rules: return "rules"
        case .settings: return "settings"
        }
    }
    
    var systemImage: String {
        switch self {
        case .home: return "house"
        case .aliases: return "at.circle"
        case .recipients: return "person.2"
        case .usernames: return "person.crop.circle.fill"
        case .domains: return "globe"
        case .failedDeliveries: return "exclamationmark.triangle.fill"
        case .rules: return "checklist"
        case .settings: return "gear"
        }
    }
    
    func view(horizontalSize:Binding<UserInterfaceSizeClass>) -> some View {
        switch self {
        case .home: return AnyView(HomeView())
        case .aliases: return AnyView(AliasesView())
        case .recipients: return AnyView(RecipientsView())
        case .usernames: return AnyView(UsernamesView(horizontalSize: horizontalSize))
        case .domains: return AnyView(DomainsView(horizontalSize: horizontalSize))
        case .failedDeliveries: return AnyView(FailedDeliveriesView(horizontalSize: horizontalSize))
        case .rules: return AnyView(RulesView(horizontalSize: horizontalSize))
        case .settings: return AnyView(AppSettingsView(horizontalSize: horizontalSize))
        }
    }
    
}


#Preview {
    MainView()
}
