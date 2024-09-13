//
//  AppSettingsFeaturesMailToView.swift
//  addy
//
//  Created by Stijn van de Water on 06/07/2024.
//

import SwiftUI

struct AppSettingsFeaturesMailToView: View {
    @State var watchAlias = true
    @State var mailtoActivityShowSuggestions = false
    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
        List {
            Image("feature_mailto").resizable().scaledToFit().frame(maxWidth: .infinity, alignment: .center).listRowInsets(EdgeInsets())
            
            Section {
                AddyToggle(isOn: $watchAlias, title: String(localized: "enable_feature"), description: String(localized: "enable_feature_always")).disabled(true)
                
                AddyToggle(isOn: $mailtoActivityShowSuggestions, title: String(localized: "show_suggestions"), description: String(localized: "show_suggestions_desc"))
                    .onAppear {
                        self.mailtoActivityShowSuggestions = MainViewState.shared.settingsManager.getSettingsBool(key: .mailtoActivityShowSuggestions)
                    }
                    .onChange(of: mailtoActivityShowSuggestions) {
                        // Only fire when the value is NOT the same as the value already in the model
                        if (mailtoActivityShowSuggestions != MainViewState.shared.settingsManager.getSettingsBool(key: .mailtoActivityShowSuggestions)){
                            MainViewState.shared.settingsManager.putSettingsBool(key: .mailtoActivityShowSuggestions, boolean: mailtoActivityShowSuggestions)
                        }
                    }
            } footer: {
                Text(String(localized: "integration_mailto_alias_desc")).padding(.top)
                
            }
        }
            .navigationTitle(String(localized: "integration_mailto_alias"))
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    AppSettingsFeaturesMailToView()
}
