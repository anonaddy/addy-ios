//
//  AppSettingsFeaturesWebintentResolutionView.swift
//  addy
//
//  Created by Stijn van de Water on 09/07/2024.
//

import SwiftUI


struct AppSettingsFeaturesWebintentResolutionView: View {
    @State var webIntentResolutionEnabled = true
    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
        List {
            Image("integration_web_intent_resolution").resizable().scaledToFit().frame(maxWidth: .infinity, alignment: .center).listRowInsets(EdgeInsets())
            
            Section {
                AddyToggle(isOn: $webIntentResolutionEnabled, title: String(localized: "enable_feature"), description: String(localized: "enable_feature_always")).disabled(true)
            } footer: {
                Text(String(localized: "integration_webintent_resolution_desc")).padding(.top)
                
            }
        }
            .navigationTitle(String(localized: "integration_webintent_resolution"))
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    AppSettingsFeaturesWebintentResolutionView()
}
