//
//  AppSettingsFeaturesNotifyFailedDeliveriesView.swift
//  addy
//
//  Created by Stijn van de Water on 16/06/2024.
//

import addy_shared
import SwiftUI

struct AppSettingsFeaturesNotifyFailedDeliveriesView: View {
    @State var isShowingFailedDeliveriesView: Bool = false
    @State var notifyFailedDeliveries: Bool = false
    @State var notifyFailedDeliveriesType: String = ""

    let types = ["all", "inbound", "outbound"]

    var body: some View {
        #if DEBUG
            let _ = Self._printChanges()
        #endif
        List {
            Image("feature_failed_delivery").resizable().scaledToFit().frame(maxWidth: .infinity, alignment: .center).listRowInsets(EdgeInsets())

            Section {
                AddyToggle(isOn: $notifyFailedDeliveries, title: String(localized: "enable_feature"), description: String(localized: "notify_failed_deliveries_feature_section_desc"))
                    .onAppear {
                        self.notifyFailedDeliveries = MainViewState.shared.settingsManager.getSettingsBool(key: .notifyFailedDeliveries)
                        self.notifyFailedDeliveriesType = MainViewState.shared.settingsManager.getSettingsString(key: .notifyFailedDeliveriesType) ?? "all"
                    }
                    .onChange(of: notifyFailedDeliveries) {
                        // Only fire when the value is NOT the same as the value already in the model
                        if notifyFailedDeliveries != MainViewState.shared.settingsManager.getSettingsBool(key: .notifyFailedDeliveries) {
                            MainViewState.shared.settingsManager.putSettingsBool(key: .notifyFailedDeliveries, boolean: notifyFailedDeliveries)
                            BackgroundWorkerHelper().scheduleAppRefresh()
                        }
                    }

                if notifyFailedDeliveries {
                    Picker(selection: $notifyFailedDeliveriesType, label: Text(String(localized: "type"))) {
                        ForEach(types, id: \.self) { type in
                            Text(type.capitalized).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: notifyFailedDeliveriesType) {
                        MainViewState.shared.settingsManager.putSettingsString(key: .notifyFailedDeliveriesType, string: notifyFailedDeliveriesType)
                        BackgroundWorkerHelper().scheduleAppRefresh()
                    }
                }

                AddySection(title: String(localized: "view_failed_deliveries"), description: String(localized: "view_failed_deliveries_desc")) {
                    isShowingFailedDeliveriesView = true
                }
            } footer: {
                Text(String(localized: "notify_failed_deliveries_feature_desc")).padding(.top)
            }
        }.sheet(isPresented: $isShowingFailedDeliveriesView) {
            // FailedDeliveriesView has its own navigationStack, always go compact to make the dismiss button appear in the underlying sheet
            FailedDeliveriesView(horizontalSize: UserInterfaceSizeClass.compact)
                .presentationDetents([.large])
        }
        .navigationTitle(String(localized: "feature_notify_failed_deliveries"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AppSettingsFeaturesNotifyFailedDeliveriesView_Previews: PreviewProvider {
    static var previews: some View {
        @State var userInterfaceSizeClass = UserInterfaceSizeClass.regular
        AppSettingsFeaturesNotifyFailedDeliveriesView()
    }
}
