//
//  AppSettingsFeaturesView.swift
//  addy
//
//  Created by Stijn van de Water on 12/06/2024.
//

import SwiftUI

struct AppSettingsFeaturesView: View {
    
    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
        List {
            AddySettingsHeader(title: String(localized: "features_and_integrations"), description: String(localized: "features_and_integrations_header_desc"), systemimage: "star.fill", systemimageColor: .accentColor)
            
            Section {
                NavigationLink(destination: AppSettingsFeaturesWatchAliasView()){
                    AddySection(title: String(localized: "watch_alias"), description: String(localized: "watch_alias_feature_desc"), leadingSystemimage: "eyes", leadingSystemimageColor: .blue)
                }
                
                NavigationLink(destination: AppSettingsFeaturesNotifyFailedDeliveriesView()){
                    AddySection(title: String(localized: "feature_notify_failed_deliveries"), description: String(localized: "notify_failed_deliveries_feature_section_desc"), leadingSystemimage: "exclamationmark.triangle.fill", leadingSystemimageColor: .orange)
                }
                
                NavigationLink(destination: AppSettingsFeaturesNotifyApiTokenExpiryView()){
                    AddySection(title: String(localized: "feature_api_token_expiry_notification"), description: String(localized: "notify_api_token_expiry_feature_section_desc"), leadingSystemimage: "textformat", leadingSystemimageColor: .cyan)
                }
                
                NavigationLink(destination: AppSettingsFeaturesNotifyDomainErrorView()){
                    AddySection(title: String(localized: "feature_domain_error_notification"), description: String(localized: "notify_domain_error_feature_section_desc"), leadingSystemimage: "exclamationmark.icloud.fill", leadingSystemimageColor: .red)
                }
               NavigationLink(destination: AppSettingsFeaturesNotifySubscriptionExpiryView()){
                   AddySection(title: String(localized: "feature_subscription_expiry_notification"), description: String(localized: "feature_subscription_expiry_notification_desc"), leadingSystemimage: "creditcard.fill", leadingSystemimageColor: .green)
                }
               
            } header: {
                Text(String(localized: "features"))
            }
            
            Section {
                NavigationLink(destination: AppSettingsFeaturesMailToView()){
                    AddySection(title: String(localized: "integration_mailto_alias"), description: String(localized: "integration_mailto_alias_desc"), leadingSystemimage: "square.and.arrow.up", leadingSystemimageColor: .blue)
                 }
                
                NavigationLink(destination: AppSettingsFeaturesWebintentResolutionView()){
                    AddySection(title: String(localized: "integration_webintent_resolution"), description: String(localized: "integration_webintent_resolution_desc"), leadingSystemimage: "link", leadingSystemimageColor: .gray)
                 }
                
                NavigationLink(destination: AppSettingsFeaturesAppIntentsView()){
                    AddySection(title: String(localized: "integration_app_intents"), description: String(localized: "integration_app_intents_desc"), leadingSystemimage: "square.3.layers.3d.top.filled", leadingSystemimageColor: .pink)
                 }
                
            } header: {
                Text(String(localized: "integrations"))
            } footer: {
                Text(String(localized: "ios_background_limitations_note")).padding(.top)
                
            }
        }
            .navigationTitle(String(localized: "features_and_integrations"))
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    AppSettingsFeaturesView()
}
