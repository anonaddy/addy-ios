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
    
    @Published var encryptedSettingsManager = SettingsManager(encrypted: true)
    
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
    @StateObject private var mainViewState = MainViewState()
    @State private var isPresentingProfileBottomSheet = false
    @State private var isShowingFailedDeliveriesView = false
    @State private var isShowingUsernamesView = false
    @State private var isShowingDomainsView = false
    @State private var isShowingRulesView = false
    @State private var isShowingAppSettingsView = false
    @State private var navigationPath = NavigationPath()
    @State private var selectedMenuItem: Destination? = .home
    @State private var selectedTab: Destination = .home
    @State private var isUnlocked = false
    @State private var showBiometricsNotAvailableAlert = false

    
    var body: some View {
        
        if isUnlocked {
            Group {
                
                if mainViewState.userResourceData == nil || mainViewState.userResourceExtendedData == nil {
                    SplashView()
                } else {
                    deviceSpecificLayout
                        .sheet(isPresented: $isPresentingProfileBottomSheet) {
                            NavigationStack {
                                ProfileBottomSheet(onNavigate: { destination in
                                    isPresentingProfileBottomSheet = false
                                    
                                    if UIDevice.current.userInterfaceIdiom == .pad {
                                        selectedMenuItem = destination
                                        
                                    } else {
                                        if destination == .usernames {
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                isShowingUsernamesView = true}
                                        } else if destination == .domains {
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                isShowingDomainsView = true}
                                        }else if destination == .rules {
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                isShowingRulesView = true}
                                        }else if destination == .settings {
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                isShowingAppSettingsView = true}
                                        }
                                    }
                                }, isPresentingProfileBottomSheet: $isPresentingProfileBottomSheet).environmentObject(mainViewState)
                            }
                        }
                        .fullScreenCover(isPresented: $isShowingUsernamesView) {
                            AnyView(UsernamesView(isShowingUsernamesView: $isShowingUsernamesView))
                        }.fullScreenCover(isPresented: $isShowingDomainsView) {
                            AnyView(DomainsView(isShowingDomainsView: $isShowingDomainsView))
                        }.fullScreenCover(isPresented: $isShowingFailedDeliveriesView) {
                            AnyView(FailedDeliveriesView(isShowingFailedDeliveriesView: $isShowingFailedDeliveriesView))
                        }.fullScreenCover(isPresented: $isShowingRulesView) {
                            AnyView(RulesView(isShowingRulesView: $isShowingRulesView))
                        }.fullScreenCover(isPresented: $isShowingAppSettingsView) {
                            AnyView(AppSettingsView(isShowingAppSettingsView: $isShowingAppSettingsView))
                        }
                }
            }
            .environmentObject(mainViewState)
        } else {
            Color.accentColor
                .ignoresSafeArea(.container) // Ignore just for the color
                .overlay(
                    VStack(spacing: 20) {
                        LottieView(animation: .named("ic_loading_logo.shapeshifter"))
                            .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                            .animationSpeed(Double(2))
                            .frame(maxHeight: 128)
                            .opacity(0.5)
                        
                    }).onAppear(perform: {
                        if mainViewState.encryptedSettingsManager.getSettingsBool(key: .biometricEnabled){
                            authenticate()
                        } else {
                            isUnlocked = true
                        }
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
        
    
    func authenticate() {
        let context = LAContext()
        var error: NSError?

        // check whether biometric authentication is possible
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // it's possible, so go ahead and use it
            let reason = String(localized: "addyio_locked")

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                // authentication has now completed
                if success {
                    self.isUnlocked = true
                } else {
                    authenticate()
                }
            }
        } else {
            showBiometricsNotAvailableAlert = true
        }
    }

    private var deviceSpecificLayout: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                iPadLayout
            } else {
                iPhoneLayout
            }
        }
    }

    private var iPadLayout: some View {
        NavigationSplitView {
            menuList
        } detail: {
            navigationStack
        }
    }

    private var iPhoneLayout: some View {
        TabView(selection: $selectedTab) {
            ForEach(Destination.iPhoneCases, id: \.self) { destination in
                destination.view(isPresentingProfileBottomSheet: $isPresentingProfileBottomSheet, isShowingUsernamesView: $isShowingUsernamesView, isShowingDomainsView: $isShowingDomainsView,
                                 isShowingFailedDeliveriesView: $isShowingFailedDeliveriesView, isShowingRulesView: $isShowingRulesView, isShowingAppSettingsView: $isShowingAppSettingsView)
                .tag(destination)
                .tabItem {
                    Label(destination.title, systemImage: destination.systemImage)
                }
            }
        }
    }
    
    private var menuList: some View {
        List(selection: $selectedMenuItem) {
            ForEach(Destination.allCases, id: \.self) { destination in
                NavigationLink(value: destination, label: {
                    Label(destination.title, systemImage: destination.systemImage)
                })
            }
        }
    }
    

    private var navigationStack: some View {
        NavigationStack(path: $navigationPath) {
            if let selectedItem = selectedMenuItem {
                selectedItem.view(isPresentingProfileBottomSheet: $isPresentingProfileBottomSheet, isShowingUsernamesView: $isShowingUsernamesView, isShowingDomainsView: $isShowingDomainsView,
                                  isShowingFailedDeliveriesView: $isShowingFailedDeliveriesView, isShowingRulesView: $isShowingRulesView, isShowingAppSettingsView: $isShowingAppSettingsView)
            } else {
                Text(String(localized: "select_menu_item"))
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

    func view(isPresentingProfileBottomSheet: Binding<Bool>,
              isShowingUsernamesView: Binding<Bool>,
              isShowingDomainsView: Binding<Bool>,
              isShowingFailedDeliveriesView: Binding<Bool>,
              isShowingRulesView: Binding<Bool>,
              isShowingAppSettingsView: Binding<Bool>) -> some View {
        switch self {
        case .home: return AnyView(HomeView(isPresentingProfileBottomSheet: isPresentingProfileBottomSheet,
                                            isShowingFailedDeliveriesView: isShowingFailedDeliveriesView))
        case .aliases: return AnyView(AliasesView(isPresentingProfileBottomSheet: isPresentingProfileBottomSheet,
                                                  isShowingFailedDeliveriesView: isShowingFailedDeliveriesView))
        case .recipients: return AnyView(RecipientsView(isPresentingProfileBottomSheet: isPresentingProfileBottomSheet,
                                                        isShowingFailedDeliveriesView: isShowingFailedDeliveriesView))
        case .usernames: return AnyView(UsernamesView(isShowingUsernamesView: isShowingUsernamesView))
        case .domains: return AnyView(DomainsView(isShowingDomainsView: isShowingDomainsView))
        case .failedDeliveries: return AnyView(FailedDeliveriesView(isShowingFailedDeliveriesView: isShowingFailedDeliveriesView))
        case .rules: return AnyView(RulesView(isShowingRulesView: isShowingRulesView))
        case .settings: return AnyView(AppSettingsView(isShowingAppSettingsView: isShowingAppSettingsView))
        }
    }
    
}


#Preview {
    MainView()
}
