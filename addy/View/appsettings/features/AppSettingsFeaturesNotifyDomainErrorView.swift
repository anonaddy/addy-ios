//
//  AppSettingsFeaturesNotifyDomainErrorView.swift
//  addy
//
//  Created by Stijn van de Water on 16/06/2024.
//

import SwiftUI

struct AppSettingsFeaturesNotifyDomainErrorView: View {
    
    @State var notifyDomainError: Bool = false
    
    var body: some View {
    
        List {
            Image("feature_notify_domain_error").resizable().scaledToFit().frame(maxWidth: .infinity, alignment: .center).listRowInsets(EdgeInsets())
            
            Section {
                AddyToggle(isOn: $notifyDomainError, title: String(localized: "enable_feature"), description: String(localized: "notify_domain_error_feature_section_desc"))
                    .onAppear {
                        self.notifyDomainError = MainViewState.shared.settingsManager.getSettingsBool(key: .notifyDomainError)
                    }
                    .onChange(of: notifyDomainError) {
                        // Only fire when the value is NOT the same as the value already in the model
                        if (notifyDomainError != MainViewState.shared.settingsManager.getSettingsBool(key: .notifyDomainError)){
                            MainViewState.shared.settingsManager.putSettingsBool(key: .notifyDomainError, boolean: notifyDomainError)
                            BackgroundWorkerHelper().scheduleBackgroundWorker()
                        }
                    }
            } footer: {
                Label {
                    Text(String(localized: "feature_domain_error_notification_desc"))
                } icon: {
                    Image(systemName: "info.circle")
                }.padding(.top)
                
            }
        }
            .navigationTitle(String(localized: "feature_domain_error_notification"))
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    AppSettingsFeaturesNotifyDomainErrorView()
}
