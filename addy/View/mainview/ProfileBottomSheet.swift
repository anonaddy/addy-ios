//
//  ProfileBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 12/05/2024.
//


import SwiftUI
import AVFoundation
import addy_shared
import Shiny

struct ProfileBottomSheet: View {
    @Binding var isPresentingProfileBottomSheet: Bool
    @EnvironmentObject var mainViewState: MainViewState
    @State var horizontalSize: UserInterfaceSizeClass
    
    @State var isShowingDomainsView = false
    @State var isShowingSubscriptionView = false
    @State var isShowingRulesView = false
    @State var isShowingUsernamesView = false
    @State var isShowingAppSettingsView = false
    @State var shouldHideNavigationBarBackButtonSubscriptionView = false
    
    let onNavigate: (Destination) -> Void
    
    init(onNavigate: @escaping (Destination) -> Void, isPresentingProfileBottomSheet: Binding<Bool>, horizontalSize: UserInterfaceSizeClass?) {
        self.onNavigate = onNavigate
        self._isPresentingProfileBottomSheet = isPresentingProfileBottomSheet
        self.horizontalSize = horizontalSize ?? UserInterfaceSizeClass.compact // In case horizontalSize cannot be determined, go with the compact mode (iPhone)
    }
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    
    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
        NavigationStack {
            List {
                
                Section{
                    VStack{
                        ZStack(alignment: .center) {
                            Circle()
                                .fill(LinearGradient(gradient: Gradient(colors: [Color.secondary.opacity(0.6), Color.secondary]), startPoint: .top, endPoint: .bottom))
                                .frame(width: 100, height: 100)
                            Text(mainViewState.userResource!.username.prefix(2).uppercased())
                                .font(.system(size: 40))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }.frame(maxWidth: .infinity).padding(.bottom,10)
                        
                        Text(mainViewState.userResource!.username)
                            .font(.headline)
                        
                        if (mainViewState.userResource!.subscription != nil){
                            Text(String(format: String(localized: "subscription_user"), mainViewState.userResource!.subscription!))
                                .font(.headline)
                                .opacity(0.6)
                                .apply {
                                    // Apply a shiny effect when the user does not have a free subcription. (So Lite or Pro)
                                    if !(mainViewState.userResource!.hasUserFreeSubscription()) {
                                        $0.shiny()
                                    } else {
                                        $0
                                    }
                                }
                            
                            
                            if (mainViewState.userResource!.subscription_ends_at != nil) {
                                Text(getSubscriptionUntilText())
                                    .font(.subheadline)
                                    .fontWeight(.thin)
                                    .opacity(0.6)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        
#if APPSTORELESS
                        AddyButton(action: {
                            openURL(URL(string: "\(AddyIo.API_BASE_URL)/settings")!)
                        }, style: AddyButtonStyle(backgroundColor: Color(.accent).opacity(0.5))) {
                            Text(String(localized: "addyio_settings")).foregroundColor(Color.white)
                        }.padding(.top).buttonStyle(PlainButtonStyle())
#endif
                    }
                }.listRowBackground(Color.clear)
            
                if AddyIo.isUsingHostedInstance(){
#if APPSTORE
                    Section {
                        AddySection(title: String(localized: "manage_subscription"), description: String(localized: "manage_subscription_desc"), trailingSystemimage: "chevron.right") {
                            self.isShowingSubscriptionView = true
                        }
                    }
#else
                    
                    Section {
                        AddySection(title: String(localized: "manage_subscription"), description: String(localized: "manage_subscription_desc"), trailingSystemimage: nil) {
                            openURL(URL(string: "\(AddyIo.API_BASE_URL)/settings/subscription")!)
                        }
                    }
                    
#endif
                }
                
                
                Section{
                    
                    AddySection(title: String(localized: "manage_domains"), description: String(localized: "manage_domains_desc"), trailingSystemimage: "chevron.right") {
                        
                        if horizontalSize == .regular {
                            self.onNavigate(Destination.domains)
                        } else {
                            self.isShowingDomainsView = true
                        }
                        
                    }
                    
                    AddySection(title: String(localized: "manage_rules"), description: String(localized: "manage_rules_desc"), trailingSystemimage: "chevron.right") {
                        if horizontalSize == .regular {
                            self.onNavigate(Destination.rules)
                        } else {
                            self.isShowingRulesView = true
                        }
                    }
                    
                    AddySection(title: String(localized: "manage_usernames"), description: String(localized: "manage_usernames_desc"), trailingSystemimage: "chevron.right") {
                        if horizontalSize == .regular {
                            self.onNavigate(Destination.usernames)
                        } else {
                            self.isShowingUsernamesView = true
                        }
                    }
                    
                    AddySection(title: String(localized: "app_settings"), description: getAppVersionSectionDescription(), trailingSystemimage: "chevron.right") {
                        if horizontalSize == .regular {
                            self.onNavigate(Destination.settings)
                        } else {
                            self.isShowingAppSettingsView = true
                        }
                    }
                    
                    
                } footer: {
                    VStack {
                        
                        
                        Spacer()
                        Text(getAddyIoVersion())
                            .multilineTextAlignment(.center)
                            .font(.system(size: 16))
                            .frame(maxWidth: .infinity)
                            .padding(.bottom,5).padding(.top,5)
                        Text(String(localized: "addyio_android_stjin"))
                            .multilineTextAlignment(.center)
                            .font(.system(size: 16))
                            .frame(maxWidth: .infinity)
                            .padding(.bottom,1)
                        Text(String(localized: "crafted_with_love_and_privacy"))
                            .multilineTextAlignment(.center)
                            .font(.system(size: 14))
                            .frame(maxWidth: .infinity)
                    }
                }
                
                
            }
            .navigationTitle(String(localized: "addyio_account"))
            .navigationDestination(isPresented: $isShowingDomainsView) {
                DomainsView(horizontalSize: $horizontalSize).environmentObject(mainViewState)
            }
            .navigationDestination(isPresented: $isShowingRulesView) {
                RulesView(horizontalSize: $horizontalSize).environmentObject(mainViewState)
            }
            .navigationDestination(isPresented: $isShowingUsernamesView) {
                UsernamesView(horizontalSize: $horizontalSize).environmentObject(mainViewState)
            }
            .navigationDestination(isPresented: $isShowingAppSettingsView) {
                AppSettingsView(horizontalSize: $horizontalSize).environmentObject(mainViewState)
            }
            .navigationDestination(isPresented: $isShowingSubscriptionView) {
                // Double check that this destination is ONLY being loaded when user is using the hosted instance
                if AddyIo.isUsingHostedInstance(){
                    ManageSubscriptionView(horizontalSize: $horizontalSize, shouldHideNavigationBarBackButtonSubscriptionView: $shouldHideNavigationBarBackButtonSubscriptionView).environmentObject(mainViewState).navigationBarBackButtonHidden(shouldHideNavigationBarBackButtonSubscriptionView)
                }
            }
            .listSectionSpacing(.compact)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem() {
                    Button {
                        dismiss()
                    } label: {
                        Label(String(localized: "dismiss"), systemImage: "xmark.circle.fill")
                    }
                    
                }
            })
        }.onAppear {
            checkForAnyInteractiveActions()
        }
        
    }
    
    
    private func getAppVersionSectionDescription() ->String {
        let appVersion = "v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")"
        
        if mainViewState.permissionsRequired || mainViewState.backgroundAppRefreshDenied {
            return String(localized: "permissions_required")
        } else if mainViewState.updateAvailable {
            return String(format: String(localized: "version_s_update_available"), appVersion)
        } else {
            return String(format: String(localized: "version_s"), appVersion)
        }
    }
    
    func checkForAnyInteractiveActions(){
        switch mainViewState.profileBottomSheetAction {
        case .settings:
            isShowingAppSettingsView = true
            break
        case .domains:
            isShowingDomainsView = true
            break
        case .subscription:
            isShowingSubscriptionView = true
            break
        default:
            break
        }
        
        // Return to nil to prevent the page from opening every time
        mainViewState.profileBottomSheetAction = nil
    }
    
    private func getAddyIoVersion() ->String {
        if (AddyIo.isUsingHostedInstance()) {
            return String(localized: "hosted_instance")
        } else {
            return String(format: String(localized: "self_hosted_instance_s"), AddyIo.VERSIONSTRING)
        }
    }
    
    
    private func getSubscriptionUntilText() ->String {
        return String(format: String(localized: "subscription_user_until"), DateTimeUtils.convertStringToLocalTimeZoneString(
            mainViewState.userResource!.subscription_ends_at,
            dateTimeFormat: DateTimeUtils.DateTimeFormat.date)
        )
        
    }
}

//#Preview {
//    ProfileBottomSheet() {
//        // Dummy function for preview
//    }
//}
