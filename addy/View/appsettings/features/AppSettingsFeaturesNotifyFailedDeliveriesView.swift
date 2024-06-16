//
//  AppSettingsFeaturesNotifyFailedDeliveriesView.swift
//  addy
//
//  Created by Stijn van de Water on 16/06/2024.
//

import SwiftUI

struct AppSettingsFeaturesNotifyFailedDeliveriesView: View {
    
    @State var isShowingFailedDeliveriesView: Bool = false
    @State var notifyFailedDeliveries: Bool = false
    
    var body: some View {
    
        List {
            Image("feature_failed_delivery").resizable().scaledToFit().frame(maxWidth: .infinity, alignment: .center).listRowInsets(EdgeInsets())
            
            Section {
                AddyToggle(isOn: $notifyFailedDeliveries, title: String(localized: "enable_feature"), description: String(localized: "notify_failed_deliveries_feature_section_desc"))
                    .onAppear {
                        self.notifyFailedDeliveries = MainViewState.shared.settingsManager.getSettingsBool(key: .notifyFailedDeliveries)
                    }
                    .onChange(of: notifyFailedDeliveries) {
                        // Only fire when the value is NOT the same as the value already in the model
                        if (notifyFailedDeliveries != MainViewState.shared.settingsManager.getSettingsBool(key: .notifyFailedDeliveries)){
                            MainViewState.shared.settingsManager.putSettingsBool(key: .notifyFailedDeliveries, boolean: notifyFailedDeliveries)
                            BackgroundWorkerHelper().scheduleBackgroundWorker()
                        }
                    }
                
                AddySection(title: String(localized: "view_failed_deliveries"), description: String(localized: "view_failed_deliveries_desc")){
                    isShowingFailedDeliveriesView = true
                    }
            } footer: {
                Label {
                    Text(String(localized: "notify_failed_deliveries_feature_desc"))
                } icon: {
                    Image(systemName: "info.circle")
                }.padding(.top)
                
            }
        }.sheet(isPresented: $isShowingFailedDeliveriesView) {
            // FailedDeliveriesView has its own navigationStack
            AnyView(FailedDeliveriesView(isShowingFailedDeliveriesView: $isShowingFailedDeliveriesView, navigationBarTitleDisplayMode: .inline))
        }
            .navigationTitle(String(localized: "feature_notify_failed_deliveries"))
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    AppSettingsFeaturesNotifyFailedDeliveriesView()
}
