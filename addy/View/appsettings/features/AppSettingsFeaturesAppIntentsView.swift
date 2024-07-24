//
//  AppSettingsFeaturesAppIntentsView.swift
//  addy
//
//  Created by Stijn van de Water on 13/07/2024.
//

import SwiftUI
import _AppIntents_UIKit

struct AppSettingsFeaturesAppIntentsView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
        List {
            //Image("integration_app_intents").resizable().scaledToFit().frame(maxWidth: .infinity, alignment: .center).listRowInsets(EdgeInsets())
            
            
            Section {
                HStack(alignment: .center){
                    ShortcutsLink().shortcutsLinkStyle((colorScheme == .dark) ? .darkOutline : .lightOutline).frame(maxWidth: .infinity)
                }
                
            } footer: {
                Text(String(localized: "integration_app_intents_desc")).padding(.top)
                
            }.listRowInsets(EdgeInsets()).listRowBackground(Color.clear)
        }
            .navigationTitle(String(localized: "watch_alias"))
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    AppSettingsFeaturesAppIntentsView()
}
