//
//  AppSettingsFeaturesWatchAliasView.swift
//  addy
//
//  Created by Stijn van de Water on 12/06/2024.
//

import SwiftUI

struct AppSettingsFeaturesWatchAliasView: View {
    
    @State var watchAlias = true
    var body: some View {
    
        List {
            Image("feature_watch_alias").resizable().scaledToFit().frame(maxWidth: .infinity, alignment: .center).listRowInsets(EdgeInsets())
            
            Section {
                AddyToggle(isOn: $watchAlias, title: String(localized: "enable_feature"), description: String(localized: "enable_feature_always")).disabled(true)
            } footer: {
                Label {
                    Text(String(localized: "watch_alias_feature_desc"))
                } icon: {
                    Image(systemName: "info.circle")
                }.padding(.top)
                
            }
        }
            .navigationTitle(String(localized: "watch_alias"))
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    AppSettingsFeaturesWatchAliasView()
}
