//
//  AppSettingsFeaturesMailToView.swift
//  addy
//
//  Created by Stijn van de Water on 06/07/2024.
//

import addy_shared
import SwiftUI

struct AppSettingsFeaturesMailToView: View {
    @State var watchAlias = true
    @State var mailtoActivityShowSuggestions = false
    @State private var preferredMailClient: String = ""
    @State private var isPresentingSelectMailClientBottomSheet = false

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
                        if mailtoActivityShowSuggestions != MainViewState.shared.settingsManager.getSettingsBool(key: .mailtoActivityShowSuggestions) {
                            MainViewState.shared.settingsManager.putSettingsBool(key: .mailtoActivityShowSuggestions, boolean: mailtoActivityShowSuggestions)
                        }
                    }
            } footer: {
                Text(String(localized: "integration_mailto_alias_desc")).padding(.top)
            }

            Section {
                AddySection(
                    title: String(localized: "preferred_email_client"),
                    description: getPreferredClientName(),
                    leadingSystemimage: "envelope.fill",
                    leadingSystemimageColor: .blue,
                    trailingSystemimage: "chevron.right"
                ) {
                    isPresentingSelectMailClientBottomSheet = true
                }
                .onAppear {
                    self.preferredMailClient = MainViewState.shared.settingsManager.getSettingsString(key: .preferredMailClient) ?? ""
                }
            } header: {
                Text(String(localized: "preferred_email_client"))
            } footer: {
                Text(String(localized: "preferred_email_client_desc"))
            }
        }
        .navigationTitle(String(localized: "integration_mailto_alias"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPresentingSelectMailClientBottomSheet) {
            NavigationStack {
                SelectMailClientBottomSheet(isSettingsMode: true) { _ in
                    self.preferredMailClient = MainViewState.shared.settingsManager.getSettingsString(key: .preferredMailClient) ?? ""
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func getPreferredClientName() -> String {
        let scheme = preferredMailClient
        if scheme.isEmpty {
            return String(localized: "always_ask")
        }
        if scheme == ThirdPartyMailClient.systemDefault.URLScheme {
            return ThirdPartyMailClient.systemDefault.name
        }
        if let client = ThirdPartyMailClient.clients.first(where: { $0.URLScheme == scheme }) {
            return client.name
        }
        return String(localized: "always_ask")
    }
}

#Preview {
    AppSettingsFeaturesMailToView()
}
