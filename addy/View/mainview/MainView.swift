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

struct MainView: View {
    @EnvironmentObject var mainViewState: MainViewState
    
    // MARK: Share sheet AND MailTo tap action
    @State var pendingURLFromShareViewController: IdentifiableURL? = nil
    // MARK: END Share sheet AND MailTo tap action
    
    @Environment(\.scenePhase) var scenePhase
    
    
    @State private var apiTokenExpiryText = ""
    @State private var subscriptionExpiryText = ""
    
    @State var isShowingAppSettingsView = false
    @State var isShowingFailedDeliveriesView = false
    @State var isShowingDomainsView = false
    @State private var isPresentingChangelogBottomSheet = false
    @State private var showBiometricsNotAvailableAlert = false
    @State var isShowingAddApiBottomSheet: Bool = false
    
    @State var lastGeneralRefresh = Date.now
    
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
                        .onOpenURL { url in
                            // handle the in coming url or call a function
                            handleURL(url: url)
                        }
                        .onAppear(perform: {
                            // Also perform BGTask immediately when opening the app
                            BackgroundWorkerHelper.backgroundWorker.performRequest { error in
                                // Schedule background tasks after it was executed
                                BackgroundWorkerHelper().scheduleAppRefresh()
                                
                            }
                            
                            // Check for changelog
                            let dictionary = Bundle.main.infoDictionary!
                            let currentVersionCode = Int(dictionary["CFBundleVersion"] as! String) ?? 0
                            if SettingsManager(encrypted: false).getSettingsInt(key: .versionCode) < currentVersionCode {
                                isPresentingChangelogBottomSheet = true
                            }
                            
                            SettingsManager(encrypted: false).putSettingsInt(key: .versionCode, int: currentVersionCode)
                        })
                        .alert(isPresented: Binding<Bool>(
                                    get: { self.mainViewState.showApiExpirationWarning || self.mainViewState.showSubscriptionExpirationWarning },
                                    set: { _ in }
                                )) {
                            if mainViewState.showApiExpirationWarning {
                                return Alert(title: Text(String(localized: "api_token_about_to_expire")), message: Text(apiTokenExpiryText.isEmpty ? String(localized: "api_token_about_to_expire_desc_unknown_expiry_date") : String(format: String(localized:"api_token_about_to_expire_desc"), apiTokenExpiryText)), primaryButton: .default(Text(String(localized: "api_token_about_to_expire_option_1"))){
                                    isShowingAddApiBottomSheet = true
                                    mainViewState.showApiExpirationWarning = false
                                }, secondaryButton: .cancel(Text(String(localized: "dismiss"))){
                                    mainViewState.showApiExpirationWarning = false
                                })
                            }
                            else if mainViewState.showSubscriptionExpirationWarning {
                                return Alert(title: Text(String(localized: "subscription_about_to_expire")), message: Text(String(format: String(localized:"subscription_about_to_expire_desc"), subscriptionExpiryText)), dismissButton: .cancel(Text(String(localized: "dismiss"))){
                                    mainViewState.showSubscriptionExpirationWarning = false

                                })
                            } else {
                                return Alert(title: Text(""))

                            }
                        }
                
                    .sheet(isPresented: $isShowingAddApiBottomSheet) {
                        let baseUrl = MainViewState.shared.encryptedSettingsManager.getSettingsString(key: .baseUrl)
                        NavigationStack {
                            AddApiBottomSheet(apiBaseUrl: baseUrl, addKey: addKey(apiKey:_:))
                        }
                        .presentationDetents([.large])
                    }
                    .sheet(item: $pendingURLFromShareViewController) { identifiableURL in
                        NavigationStack {
                            ShareViewControllerPendingUrlView(pendingURLFromShareViewController: identifiableURL)
                        }
                        .presentationDetents([.fraction(0.3)])
                    }
                    .sheet(isPresented: $mainViewState.isPresentingProfileBottomSheet) {
                        NavigationStack {
                            ProfileBottomSheet(onNavigate: { destination in
                                mainViewState.isPresentingProfileBottomSheet = false
                                mainViewState.selectedTab = destination
                            }, isPresentingProfileBottomSheet: $mainViewState.isPresentingProfileBottomSheet,
                                               horizontalSize:  horizontalSize)
                            .environmentObject(mainViewState)
                        }
                        .interactiveDismissDisabled()
                        .presentationDetents([.large])
                    }
                    .sheet(isPresented: $mainViewState.isPresentingFailedDeliveriesSheet) {
                        NavigationStack {
                            FailedDeliveriesView(horizontalSize: horizontalSize)
                        }
                        .presentationDetents([.large])
                    }
                    .sheet(isPresented: $mainViewState.isPresentingAccountNotificationsSheet) {
                        NavigationStack {
                            AccountNotificationsView(horizontalSize: horizontalSize)
                        }
                        .presentationDetents([.large])
                    }
                    .sheet(item: $mainViewState.mailToActionSheetData) { data in
                        // Has its own navigationStack
                        MailToActionSheet(mailToActionSheetData: mainViewState.mailToActionSheetData!, openedThroughShareSheet: false, returnToApp: { aliasId in
                            mainViewState.mailToActionSheetData = nil
                            
                            MainViewState.shared.showAliasWithId = aliasId
                            MainViewState.shared.selectedTab = .aliases
                            
                        }, close: {
                            mainViewState.mailToActionSheetData = nil
                        }, openMailToShareSheet: { url in
                            UIApplication.shared.open(url, options: [:], completionHandler: { _ in
                                mainViewState.mailToActionSheetData = nil
                            })
                        })
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                    }
                    .sheet(isPresented: $isPresentingChangelogBottomSheet, content: {
                        NavigationStack {
                            ChangelogBottomSheet()
                        }
                        .presentationDetents([.medium, .large])
                    })
                    .task {
                        await checkForUpdates()
                        await checkTokenExpiry()
                        await checkForSubscriptionExpiration()
                        await checkForNewFailedDeliveries()
                        await checkForNewAccountNotifications()
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
                    
                    
                    // Check if there are pendingURLFromShareViewController
                    if let url = SettingsManager(encrypted: true).getSettingsString(key: .pendingURLFromShareViewController) {
                        
                        if url.starts(with: "addyio://") {
                            UIApplication.shared.open(URL(string: "\(url)")!, options: [:], completionHandler: nil)
                        } else {
                            pendingURLFromShareViewController = IdentifiableURL(url: URL(string: "\(url)")!)
                        }
                        
                        // Remove to prevent any future references
                        SettingsManager(encrypted: true).removeSetting(key: .pendingURLFromShareViewController)
                    }
                    
                    // Check this every time the app is come to foreground
                    checkForAlerts()
                    
                    if lastGeneralRefresh.timeIntervalSinceNow < -300 { // -300 seconds is 5 minutes
                        //print("More than 5 minutes have passed since the last general refresh.")
                        // Refresh general data when coming back from the background to the foreground
                        refreshGeneralData()
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
        .alert(String(localized: "authentication_splash_error_unavailable"), isPresented: $showBiometricsNotAvailableAlert) {
            Button(String(localized: "try_again"), role: .cancel) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    authenticate()
                }
                
            }
            Button(String(localized: "reset_app"), role: .destructive) {
                let settingsManager = SettingsManager(encrypted: true)
                settingsManager.clearSettingsAndCloseApp()
            }
            
        }
    }
    
}


private func handleURL(url: URL) {
    switch url.host {
    case "alias":
        // change the selected tab from the tabbar
        MainViewState.shared.showAliasWithId = url.lastPathComponent
        MainViewState.shared.selectedTab = .aliases
    default:
        break
    }
}


private func checkForSubscriptionExpiration() async {
    // Only check on hosted instance
    if (AddyIo.isUsingHostedInstance()) {
        do {
            let user = try await NetworkHelper().getUserResource()
            if let subscriptionEndsAt = user?.subscription_ends_at {
                let expiryDate = try DateTimeUtils.turnStringIntoLocalDateTime(subscriptionEndsAt) // Get the expiry date
                let currentDateTime = Date() // Get the current date
                let deadLineDate = Calendar.current.date(byAdding: .day, value: -7, to: expiryDate) // Subtract 7 days from the expiry date
                if let deadLineDate = deadLineDate, currentDateTime > deadLineDate {
                    // The current date is suddenly after the deadline date. It will expire within 7 days
                    // Show the subscription is about to expire card
                    subscriptionExpiryText = expiryDate.futureDateDisplay()
                    mainViewState.showSubscriptionExpirationWarning = true
                }
            }
            // If expires_at is null it will never expire
        } catch {
            // Panic
            LoggingHelper().addLog(
                importance: LogImportance.critical,
                error: "Could not parse subscriptionEndsAt",
                method: "checkForSubscriptionExpiration",
                extra: error.localizedDescription)
        }
    }
}


private func checkTokenExpiry() async {
    do {
        let apiTokenDetails = try await NetworkHelper().getApiTokenDetails()
        if let expiresAt = apiTokenDetails?.expires_at {
            let expiryDate = try DateTimeUtils.turnStringIntoLocalDateTime(expiresAt) // Get the expiry date
            let currentDateTime = Date() // Get the current date
            let deadLineDate = Calendar.current.date(byAdding: .day, value: -5, to: expiryDate) // Subtract 5 days from the expiry date
            if let deadLineDate = deadLineDate, currentDateTime > deadLineDate {
                // The current date is suddenly after the deadline date. It will expire within 5 days
                // Show the api is about to expire alert
                
                apiTokenExpiryText = expiryDate.futureDateDisplay()
                mainViewState.showApiExpirationWarning = true
            }
        }
        // If expires_at is null it will never expire
    } catch {
        // Panic
        LoggingHelper().addLog(
            importance: LogImportance.critical,
            error: "Could not parse expiresAt",
            method: "checkTokenExpiry",
            extra: error.localizedDescription)
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

private func checkForNewFailedDeliveries() async {
    do {
        let result = try await NetworkHelper().getFailedDeliveries()
        let currentFailedDeliveries = mainViewState.encryptedSettingsManager.getSettingsInt(key: .backgroundServiceCacheFailedDeliveriesCount)
        if (result?.data.count ?? 0 - currentFailedDeliveries) > 0 {
            withAnimation {
                self.mainViewState.newFailedDeliveries = (result?.data.count ?? 0) - currentFailedDeliveries
            }
        }
    } catch {
        //TODO: Let the user know

        //print("Failed to get failed deliveries: \(error)")
        // Error will be logged when user has enabled this
    }
}

    
/*
 This method checks if there are new account notifications
 It does this by getting the current account notifications count, if that count is bigger than the account notifications in the cache that means there are new notifications
 
 As backgroundServiceCacheAccountNotificationsCount is only updated in the service and in the AccountNotificationsView that means that the red
 indicator is only visible if:
 
 - The activity has not been opened since there were new items.
 - There are more account notifications than the server cached last time (in which case the user should have got a notification)
 */

private func checkForNewAccountNotifications() async {
    do {
        let result = try await NetworkHelper().getAllAccountNotifications()
        let currentAccountNotifications = mainViewState.encryptedSettingsManager.getSettingsInt(key: .backgroundServiceCacheAccountNotificationsCount)
        if (result?.data.count ?? 0 - currentAccountNotifications) > 0 {
            withAnimation {
                self.mainViewState.newAccountNotifications = (result?.data.count ?? 0) - currentAccountNotifications
            }
        }
    } catch {
        //TODO: Let the user know
        //print("Failed to get account notifications: \(error)")
        // Error will be logged when user has enabled this
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
                    withAnimation {
                        self.mainViewState.isUnlocked = true

                    }
                    
                }
            }
        }
    } else {
        showBiometricsNotAvailableAlert = true
    }
}


private func addKey(apiKey: String, _: String) {
    mainViewState.encryptedSettingsManager.putSettingsString(key: .apiKey, string: apiKey)
    isShowingAddApiBottomSheet = false
}


private func refreshGeneralData(){
    Task {
        await checkForUpdates()
        await checkForSubscriptionExpiration()
        await checkForNewFailedDeliveries()
        await checkForNewAccountNotifications()
        await checkTokenExpiry()
        await getUserResource()
    }
    
    self.lastGeneralRefresh = Date.now
}

private func getUserResource() async {
    let networkHelper = NetworkHelper()
    do {
        let userResource = try await networkHelper.getUserResource()
        if let userResource = userResource {
            mainViewState.userResource = userResource
        }
    } catch {
        //TODO: Let the user know
        print("Failed to get user resource: \(error)")
        // Error will be logged when user has enabled this
    }
}

private func checkForUpdates() async {
    if mainViewState.settingsManager.getSettingsBool(key: .notifyUpdates) {
        do {
            let (updateAvailable, _, _, _) = try await Updater().isUpdateAvailable()
            withAnimation {
                mainViewState.updateAvailable = updateAvailable
            }
            
        } catch {
            //TODO: Let the user know
            //print("Failed to check for updates: \(error)")
            // Error will be logged when user has enabled this
        }
    }
}


func checkForAlerts() {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
        DispatchQueue.main.async {
            mainViewState.permissionsRequired = settings.authorizationStatus != .authorized
        }
    }
    
    mainViewState.backgroundAppRefreshDenied = !BackgroundWorkerHelper().checkBackgroundRefreshStatus()
}
    


private var tabView: some View {
    TabView(selection: $mainViewState.selectedTab) {
        let destinations = horizontalSize == .regular ? Destination.allCases : Destination.iPhoneCases
        
        ForEach(destinations, id: \.self) { destination in
            destination.view(horizontalSize: .constant(horizontalSize!), refreshGeneralData: self.refreshGeneralData)
                .tag(destination)
                .tabItem {
                    Label(destination.title, systemImage: destination.systemImage)
                }
                .apply {
                    // Apply the badge to the failed deliveries item
                    if (destination == .failedDeliveries) {
                        $0.badge(self.mainViewState.newFailedDeliveries ?? 0)
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
        case .aliases: return "at.circle.fill"
        case .recipients: return "person.2"
        case .usernames: return "person.crop.circle.fill"
        case .domains: return "globe"
        case .failedDeliveries: return "exclamationmark.triangle.fill"
        case .rules: return "checklist"
        case .settings: return "gear"
        }
    }
    
    func view(horizontalSize:Binding<UserInterfaceSizeClass>, refreshGeneralData: (() -> Void)? = nil) -> some View {
        switch self {
        case .home: return AnyView(HomeView(horizontalSize: horizontalSize, onRefreshGeneralData: {
            refreshGeneralData?()
        }))
        case .aliases: return AnyView(AliasesView(horizontalSize: horizontalSize, onRefreshGeneralData: {
            refreshGeneralData?()
        }))
        case .recipients: return AnyView(RecipientsView(horizontalSize: horizontalSize, onRefreshGeneralData: {
            refreshGeneralData?()
        }))
        case .usernames: return AnyView(UsernamesView(horizontalSize: horizontalSize, onRefreshGeneralData: {
            refreshGeneralData?()
        }))
        case .domains: return AnyView(DomainsView(horizontalSize: horizontalSize, onRefreshGeneralData: {
            refreshGeneralData?()
        }))
        case .failedDeliveries: return AnyView(FailedDeliveriesView(horizontalSize: horizontalSize.wrappedValue, onRefreshGeneralData: {
            refreshGeneralData?()
        }))
        case .rules: return AnyView(RulesView(horizontalSize: horizontalSize, onRefreshGeneralData: {
            refreshGeneralData?()
        }))
        case .settings: return AnyView(AppSettingsView(horizontalSize: horizontalSize))
        }
    }
    
}


#Preview {
    MainView()
}
