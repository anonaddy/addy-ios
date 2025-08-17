import addy_shared
import LocalAuthentication
import Lottie
import SwiftUI

struct MainView: View {
    @EnvironmentObject var mainViewState: MainViewState
    @StateObject private var aliasesViewState = AliasesViewState.shared // Needs to be shared so that filters can be applied from other views
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // State variables

    // MARK: Share sheet AND MailTo tap action

    @State private var pendingURLFromShareViewController: IdentifiableURL?

    // MARK: END Share sheet AND MailTo tap action

    @State private var apiTokenExpiryText = ""
    @State private var subscriptionExpiryText = ""
    @State private var isShowingAddApiSheet = false
    @State private var isShowingChangelogSheet = false
    @State private var showBiometricsAlert = false
    @State private var lastGeneralRefresh = Date.now
    @State private var searchText = ""

    var body: some View {
        #if DEBUG
            let _ = Self._printChanges()
        #endif

        Group {
            if shouldShowLockedView {
                lockedView
            } else if mainViewState.userResourceData == nil || mainViewState.userResourceExtendedData == nil {
                SplashView()
            } else {
                contentView
            }
        }
        // Makes sure the env obj is available to all the child views
        .environmentObject(mainViewState)
        .environmentObject(aliasesViewState)
        .onChange(of: scenePhase, handleScenePhaseChange)
        .task(performInitialTasks)
    }

    private var shouldShowLockedView: Bool {
        mainViewState.encryptedSettingsManager.getSettingsBool(key: .biometricEnabled) && !mainViewState.isUnlocked
    }

    private var lockedView: some View {
        NavigationStack {
            ContentUnavailableView {
                Label(String(localized: "addyio_locked"), systemImage: "lock.fill")
            } description: {
                Text(String(localized: "addyio_locked_desc"))
            } actions: {
                Button(String(localized: "unlock")) { authenticate() }
            }
            .navigationTitle(String(localized: "addyio_locked"))
            .alert(String(localized: "authentication_splash_error_unavailable"), isPresented: $showBiometricsAlert) {
                Button(String(localized: "try_again")) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { authenticate() }
                }
                Button(String(localized: "reset_app"), role: .destructive) {
                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                }
            }
        }
    }

    private var contentView: some View {
        Group {
            TabView(selection: $mainViewState.selectedTab) {
                ForEach(tabDestinations, id: \.self) { destination in
                    destination.view(horizontalSize: .constant(horizontalSizeClass!), refreshGeneralData: refreshGeneralData)
                        .tag(destination)
                        .tabItem { Label(destination.title, systemImage: destination.systemImage) }
                        .badge(destination == .failedDeliveries ? mainViewState.newFailedDeliveries ?? 0 : 0)
                }
            }
            .apply {
                if #available(iOS 26.0, *) {
                    $0.tabViewStyle(.sidebarAdaptable).tabBarMinimizeBehavior(.onScrollDown)
                } else if #available(iOS 18.0, *) {
                    $0.tabViewStyle(.sidebarAdaptable)
                } else {
                    $0.tabViewStyle(.automatic)
                }
            }
            .navigationTitle(mainViewState.selectedTab.title)
        }
        .onOpenURL(perform: handleURL)
        .onAppear(perform: handleOnAppear)
        .alert(item: alertBinding) { alertType in
            switch alertType {
            case .apiExpiration:
                return Alert(
                    title: Text(String(localized: "api_token_about_to_expire")),
                    message: Text(apiTokenExpiryText.isEmpty ? String(localized: "api_token_about_to_expire_desc_unknown_expiry_date") : String(format: String(localized: "api_token_about_to_expire_desc"), apiTokenExpiryText)),
                    primaryButton: .default(Text(String(localized: "api_token_about_to_expire_option_1"))) {
                        isShowingAddApiSheet = true
                        mainViewState.showApiExpirationWarning = false
                    },
                    secondaryButton: .cancel(Text(String(localized: "dismiss"))) {
                        mainViewState.showApiExpirationWarning = false
                    }
                )
            case .subscriptionExpiration:
                return Alert(
                    title: Text(String(localized: "subscription_about_to_expire")),
                    message: Text(String(format: String(localized: "subscription_about_to_expire_desc"), subscriptionExpiryText)),
                    primaryButton: .default(Text(String(localized: "manage"))) {
                        mainViewState.isPresentingProfileBottomSheet = true
                        mainViewState.profileBottomSheetAction = .subscription
                    },
                    secondaryButton: .cancel(Text(String(localized: "dismiss"))) {
                        mainViewState.showSubscriptionExpirationWarning = false
                    }
                )
            }
        }
        .sheet(isPresented: $isShowingAddApiSheet) {
            NavigationStack {
                AddApiBottomSheet(apiBaseUrl: mainViewState.encryptedSettingsManager.getSettingsString(key: .baseUrl), addKey: addKey)
                    .environmentObject(mainViewState)
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
                ProfileBottomSheet(
                    onNavigate: { mainViewState.isPresentingProfileBottomSheet = false; mainViewState.selectedTab = $0 },
                    isPresentingProfileBottomSheet: $mainViewState.isPresentingProfileBottomSheet,
                    horizontalSize: horizontalSizeClass
                )
                .environmentObject(mainViewState)
            }
            .interactiveDismissDisabled()
            .presentationDetents([.large])
        }
        .sheet(isPresented: $mainViewState.isPresentingFailedDeliveriesSheet) {
            NavigationStack {
                FailedDeliveriesView(horizontalSize: horizontalSizeClass)
            }
            .presentationDetents([.large])
        }
        .sheet(isPresented: $mainViewState.isPresentingAccountNotificationsSheet) {
            NavigationStack {
                AccountNotificationsView(horizontalSize: horizontalSizeClass)
            }
            .presentationDetents([.large])
        }
        .sheet(item: $mainViewState.mailToActionSheetData) { data in
            MailToActionSheet(
                mailToActionSheetData: data,
                openedThroughShareSheet: false,
                returnToApp: { mainViewState.showAliasWithId = $0; mainViewState.selectedTab = .aliases; mainViewState.mailToActionSheetData = nil },
                close: { mainViewState.mailToActionSheetData = nil },
                openMailToShareSheet: { UIApplication.shared.open($0, options: [:]) { _ in mainViewState.mailToActionSheetData = nil } }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingChangelogSheet) {
            NavigationStack { ChangelogBottomSheet() }
                .presentationDetents([.medium, .large])
        }
    }

    private var tabDestinations: [Destination] {
        horizontalSizeClass == .regular ? Destination.otherCases : Destination.iPhoneCases
    }

    private enum AlertType: Identifiable {
        case apiExpiration, subscriptionExpiration
        var id: Self { self }
    }

    private var alertBinding: Binding<AlertType?> {
        Binding(
            get: {
                if mainViewState.showApiExpirationWarning { return .apiExpiration }
                if mainViewState.showSubscriptionExpirationWarning { return .subscriptionExpiration }
                return nil
            },
            set: { _ in }
        )
    }

    private func handleOnAppear() {
        // Also perform BGTask immediately when opening the app
        BackgroundWorkerHelper.backgroundWorker.performRequest { _ in
            // Schedule background tasks after it was executed
            BackgroundWorkerHelper().scheduleAppRefresh()
        }
        checkForChangelog()
        openDefaultPage()
        SettingsManager(encrypted: false).putSettingsInt(
            key: .timesTheAppHasBeenOpened,
            int: SettingsManager(encrypted: false).getSettingsInt(key: .timesTheAppHasBeenOpened) + 1
        )

        #if DEBUG
            print("App has been opened \(SettingsManager(encrypted: false).getSettingsInt(key: .timesTheAppHasBeenOpened)) times")
        #endif
    }

    private func performInitialTasks() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await checkForUpdates() }
            group.addTask { await checkTokenExpiry() }
            group.addTask { await checkForSubscriptionExpiration() }
            group.addTask { await checkForNewFailedDeliveries() }
            group.addTask { await checkForNewAccountNotifications() }
        }
    }

    private func handleScenePhaseChange(oldPhase _: ScenePhase, newPhase: ScenePhase) {
        switch newPhase {
        case .background:
            // User closed the app to background, lock the app (only if neccessary of course)
            if mainViewState.encryptedSettingsManager.getSettingsBool(key: .biometricEnabled) {
                mainViewState.isUnlocked = false
            }
        case .active:
            // User opens the app and the app is not unlocked
            if mainViewState.aliasToDisable != nil {
                mainViewState.selectedTab = .aliases
            }
            checkForPendingURLFromShareViewController()

            // Check this every time the app is come to foreground
            checkForAlerts()

            // Reset badge number
            UNUserNotificationCenter.current().setBadgeCount(0) { error in
                if let error = error {
                    LoggingHelper().addLog(importance: .critical, error: "Cannot set badge to 0", method: "MainView.newPhase", extra: error.localizedDescription)
                }
            }
            if lastGeneralRefresh.timeIntervalSinceNow < -300 {
                // -300 seconds is 5 minutes
                // print("More than 5 minutes have passed since the last general refresh.")
                // Refresh general data when coming back from the background to the foreground

                refreshGeneralData()
            }
        default:
            break
        }
    }

    private func handleURL(url: URL) {
        // handle the in coming url or call a function
        if url.host == "alias" {
            mainViewState.showAliasWithId = url.lastPathComponent
            mainViewState.selectedTab = .aliases
        }
    }

    private func checkForChangelog() {
        let currentVersionCode = Int(Bundle.main.infoDictionary!["CFBundleVersion"] as! String) ?? 0
        if SettingsManager(encrypted: false).getSettingsInt(key: .versionCode) < currentVersionCode {
            isShowingChangelogSheet = true
            SettingsManager(encrypted: false).putSettingsInt(key: .versionCode, int: currentVersionCode)
        }
    }

    private func openDefaultPage() {
        // Check if the value exists in the array, default (but dont reset) to home if not (this could occur if eg. a tablet backup (which has more options) gets restored on mobile)
        // Don't reset the value as this app could be opened in splitscreen, we don't want to reset the value then.

        let destinations = horizontalSizeClass == .regular ? Destination.otherCases : Destination.iPhoneCases
        let startupPage = SettingsManager(encrypted: false).getSettingsString(key: .startupPage) ?? "home"
        if let destination = destinations.first(where: { $0.value == startupPage }) {
            mainViewState.selectedTab = destination
        }
    }

    private func checkForSubscriptionExpiration() async {
        // Only check on hosted instance
        guard AddyIo.isUsingHostedInstance() else { return }
        do {
            if let user = try await NetworkHelper().getUserResource(), let subscriptionEndsAt = user.subscription_ends_at {
                let expiryDate = try DateTimeUtils.convertStringToLocalTimeZoneDate(subscriptionEndsAt)
                let currentDate = Date()
                if let deadlineDate = Calendar.current.date(byAdding: .day, value: -7, to: expiryDate), currentDate > deadlineDate {
                    // The current date is suddenly after the deadline date. It will expire within 7 days
                    // Show the subscription is about to expire card
                    subscriptionExpiryText = expiryDate.futureDateDisplay()
                    mainViewState.showSubscriptionExpirationWarning = true
                }
            }
            // If expires_at is null it will never expire
        } catch {
            LoggingHelper().addLog(importance: .critical, error: "Could not parse subscriptionEndsAt", method: "checkForSubscriptionExpiration", extra: error.localizedDescription)
        }
    }

    private func checkForPendingURLFromShareViewController() {
        // Check if there are pendingURLFromShareViewController
        if let urlString = SettingsManager(encrypted: true).getSettingsString(key: .pendingURLFromShareViewController), let url = URL(string: urlString) {
            // eg. addyio://alias/\(aliasId)" (from ShareViewController)
            if urlString.starts(with: "addyio://") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                pendingURLFromShareViewController = IdentifiableURL(url: url)
            }

            // Remove to prevent any future references
            SettingsManager(encrypted: true).removeSetting(key: .pendingURLFromShareViewController)
        }
    }

    private func checkTokenExpiry() async {
        do {
            if let apiTokenDetails = try await NetworkHelper().getApiTokenDetails(), let expiresAt = apiTokenDetails.expires_at {
                let expiryDate = try DateTimeUtils.convertStringToLocalTimeZoneDate(expiresAt)
                let currentDate = Date()
                if let deadlineDate = Calendar.current.date(byAdding: .day, value: -5, to: expiryDate), currentDate > deadlineDate {
                    // The current date is suddenly after the deadline date. It will expire within 5 days
                    // Show the api is about to expire alert
                    apiTokenExpiryText = expiryDate.futureDateDisplay()
                    mainViewState.showApiExpirationWarning = true
                }
            }
        } catch {
            LoggingHelper().addLog(importance: .critical, error: "Could not parse expiresAt", method: "checkTokenExpiry", extra: error.localizedDescription)
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
            if let result = try await NetworkHelper().getFailedDeliveries() {
                let currentCount = mainViewState.encryptedSettingsManager.getSettingsInt(key: .backgroundServiceCacheFailedDeliveriesCount)
                if result.data.count > currentCount {
                    withAnimation { mainViewState.newFailedDeliveries = result.data.count - currentCount }
                }
            }
        } catch {
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
            if let result = try await NetworkHelper().getAllAccountNotifications() {
                let currentCount = mainViewState.encryptedSettingsManager.getSettingsInt(key: .backgroundServiceCacheAccountNotificationsCount)
                if result.data.count > currentCount {
                    withAnimation { mainViewState.newAccountNotifications = result.data.count - currentCount }
                }
            }
        } catch {
            // Error will be logged when user has enabled this
        }
    }

    private func authenticate() {
        let context = LAContext()
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: String(localized: "addyio_locked")) { success, _ in
                DispatchQueue.main.async {
                    withAnimation { mainViewState.isUnlocked = success }
                }
            }
        } else {
            showBiometricsAlert = true
        }
    }

    private func addKey(apiKey: String, _: String) {
        mainViewState.encryptedSettingsManager.putSettingsString(key: .apiKey, string: apiKey)
        isShowingAddApiSheet = false
    }

    private func refreshGeneralData() {
        Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await checkForUpdates() }
                group.addTask { await checkForSubscriptionExpiration() }
                group.addTask { await checkForNewFailedDeliveries() }
                group.addTask { await checkForNewAccountNotifications() }
                group.addTask { await checkTokenExpiry() }
                group.addTask { await getUserResource() }
            }
            lastGeneralRefresh = Date.now
        }
    }

    private func getUserResource() async {
        do {
            if let userResource = try await NetworkHelper().getUserResource() {
                mainViewState.userResource = userResource
            }
        } catch {
            print("Failed to get user resource: \(error)")
        }
    }

    private func checkForUpdates() async {
        guard mainViewState.settingsManager.getSettingsBool(key: .notifyUpdates) else { return }
        do {
            let (updateAvailable, _, _, _) = try await Updater().isUpdateAvailable()
            withAnimation { mainViewState.updateAvailable = updateAvailable }
        } catch {}
    }

    private func checkForAlerts() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async { mainViewState.permissionsRequired = settings.authorizationStatus != .authorized }
        }
        mainViewState.backgroundAppRefreshDenied = !BackgroundWorkerHelper().checkBackgroundRefreshStatus()
    }
}

public enum Destination: Hashable, CaseIterable {
    case home, aliases, recipients, usernames, domains, failedDeliveries, rules, settings, subscription

    static var iPhoneCases: [Destination] { [.home, .aliases, .recipients] }
    static var otherCases: [Destination] { [.home, .aliases, .recipients, .usernames, .domains, .failedDeliveries, .rules, .settings] }

    var title: LocalizedStringKey {
        switch self {
        case .home: "home"
        case .aliases: "aliases"
        case .recipients: "recipients"
        case .usernames: "usernames"
        case .domains: "domains"
        case .failedDeliveries: "failed_deliveries"
        case .rules: "rules"
        case .settings: "settings"
        case .subscription: "subscription"
        }
    }

    var value: String {
        switch self {
        case .home: return "home"
        case .aliases: return "aliases"
        case .recipients: return "recipients"
        case .usernames: return "usernames"
        case .domains: return "domains"
        case .failedDeliveries: return "failed_deliveries"
        case .rules: return "rules"
        case .settings: return "settings"
        case .subscription: return "subscription"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house"
        case .aliases: "at.circle.fill"
        case .recipients: "person.2"
        case .usernames: "person.crop.circle.fill"
        case .domains: "globe"
        case .failedDeliveries: "exclamationmark.triangle.fill"
        case .rules: "checklist"
        case .settings: "gear"
        case .subscription: "creditcard.fill"
        }
    }

    func view(horizontalSize: Binding<UserInterfaceSizeClass>, refreshGeneralData: (() -> Void)? = nil) -> some View {
        switch self {
        case .home: AnyView(HomeView(horizontalSize: horizontalSize, onRefreshGeneralData: refreshGeneralData))
        case .aliases: AnyView(AliasesView(horizontalSize: horizontalSize, onRefreshGeneralData: refreshGeneralData))
        case .recipients: AnyView(RecipientsView(horizontalSize: horizontalSize, onRefreshGeneralData: refreshGeneralData))
        case .usernames: AnyView(UsernamesView(horizontalSize: horizontalSize, onRefreshGeneralData: refreshGeneralData))
        case .domains: AnyView(DomainsView(horizontalSize: horizontalSize, onRefreshGeneralData: refreshGeneralData))
        case .failedDeliveries: AnyView(FailedDeliveriesView(horizontalSize: horizontalSize.wrappedValue, onRefreshGeneralData: refreshGeneralData))
        case .rules: AnyView(RulesView(horizontalSize: horizontalSize, onRefreshGeneralData: refreshGeneralData))
        case .settings: AnyView(AppSettingsView(horizontalSize: horizontalSize))
        case .subscription: AnyView(ManageSubscriptionView(horizontalSize: horizontalSize, shouldHideNavigationBarBackButtonSubscriptionView: .constant(false)))
        }
    }
}

#Preview {
    MainView().environmentObject(MainViewState())
}
