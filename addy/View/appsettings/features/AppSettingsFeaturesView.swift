//
//  AppSettingsFeaturesView.swift
//  addy
//
//  Created by Stijn van de Water on 12/06/2024.
//

import SwiftUI

struct AppSettingsFeaturesView: View {
    var body: some View {
        List {
            AddySettingsHeader(title: String(localized: "features_and_integrations"), description: String(localized: "features_and_integrations_header_desc"), systemimage: "star.fill", systemimageColor: .accentColor)
            
            Section {
                NavigationLink(destination: AppSettingsFeaturesWatchAliasView()){
                    AddySection(title: String(localized: "watch_alias"), description: String(localized: "watch_alias_feature_desc"), leadingSystemimage: "eyes", leadingSystemimageColor: .blue)
                }
            } header: {
                Text(String(localized: "features"))
            }
            
            Section {
                
            } header: {
                Text(String(localized: "integrations"))
            }
        }
            .navigationTitle(String(localized: "features_and_integrations"))
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    AppSettingsFeaturesView()
}
