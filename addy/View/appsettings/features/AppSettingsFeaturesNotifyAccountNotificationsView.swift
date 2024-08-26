//
//  AppSettingsFeaturesNotifyAccountNotificationsView 2.swift
//  addy
//
//  Created by Stijn van de Water on 23/08/2024.
//

import SwiftUI
import addy_shared

struct AppSettingsFeaturesNotifyAccountNotificationsView: View {
    
    @State var isShowingAccountNotificationsView: Bool = false
    @State var notifyAccountNotifications: Bool = false
    
    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
        List {
            Image("feature_account_notifications").resizable().scaledToFit().frame(maxWidth: .infinity, alignment: .center).listRowInsets(EdgeInsets())
            
            Section {
                AddyToggle(isOn: $notifyAccountNotifications, title: String(localized: "enable_feature"), description: AddyIo.isUsingHostedInstance() ? String(localized: "notify_account_notifications_feature_section_desc") : String(localized: "feature_not_available_hosted")).disabled(!AddyIo.isUsingHostedInstance())
                    .onAppear {
                        self.notifyAccountNotifications = MainViewState.shared.settingsManager.getSettingsBool(key: .notifyAccountNotifications)
                    }
                    .onChange(of: notifyAccountNotifications) {
                        // Only fire when the value is NOT the same as the value already in the model
                        if (notifyAccountNotifications != MainViewState.shared.settingsManager.getSettingsBool(key: .notifyAccountNotifications)){
                            MainViewState.shared.settingsManager.putSettingsBool(key: .notifyAccountNotifications, boolean: notifyAccountNotifications)
                            BackgroundWorkerHelper().scheduleBackgroundWorker()
                        }
                    }
                
                if AddyIo.isUsingHostedInstance() {
                    AddySection(title: String(localized: "view_account_notifications"), description: String(localized: "view_account_notifications_desc")){
                        isShowingAccountNotificationsView = true
                    }
                }
            } footer: {
                Text(String(localized: "notify_account_notifications_feature_section_desc")).padding(.top)
                
            }
        }.sheet(isPresented: $isShowingAccountNotificationsView) {
            // AccountNotificationsView has its own navigationStack, always go compact to make the dismiss button appear in the underlying sheet
            AccountNotificationsView(horizontalSize: UserInterfaceSizeClass.compact)
                .presentationDetents([.large])

        }
            .navigationTitle(String(localized: "feature_notify_account_notifications"))
            .navigationBarTitleDisplayMode(.inline)
    }
}


struct AppSettingsFeaturesNotifyAccountNotificationsView_Previews: PreviewProvider {
    
    static var previews: some View {
        @State var userInterfaceSizeClass: UserInterfaceSizeClass =  UserInterfaceSizeClass.regular
        AppSettingsFeaturesNotifyAccountNotificationsView()
        
    }
}

