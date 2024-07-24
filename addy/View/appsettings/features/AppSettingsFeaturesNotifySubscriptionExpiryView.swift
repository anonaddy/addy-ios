//
//  AppSettingsFeaturesNotifySubscriptionExpiryView.swift
//  addy
//
//  Created by Stijn van de Water on 16/06/2024.
//

import SwiftUI
import addy_shared

struct AppSettingsFeaturesNotifySubscriptionExpiryView: View {
    
    @State var notifySubscriptionExpiry: Bool = false
    @State var isToggleDisabled: Bool = false
    @State var subscriptionExpiryText: String = String(localized: "obtaining_information")
    @State var toggleDescription: String = String(localized: "notify_subscription_expiry_feature_section_desc")
    
    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
        List {
            Image("feature_notify_subscription_expiry").resizable().scaledToFit().frame(maxWidth: .infinity, alignment: .center).listRowInsets(EdgeInsets())
            
            Section {
                AddyToggle(isOn: $notifySubscriptionExpiry, title: String(localized: "enable_feature"), description: toggleDescription).disabled(isToggleDisabled)
                    .onAppear {
                        self.notifySubscriptionExpiry = MainViewState.shared.settingsManager.getSettingsBool(key: .notifySubscriptionExpiry)
                    }
                    .onChange(of: notifySubscriptionExpiry) {
                        // Only fire when the value is NOT the same as the value already in the model
                        if (notifySubscriptionExpiry != MainViewState.shared.settingsManager.getSettingsBool(key: .notifySubscriptionExpiry)){
                            MainViewState.shared.settingsManager.putSettingsBool(key: .notifySubscriptionExpiry, boolean: notifySubscriptionExpiry)
                            BackgroundWorkerHelper().scheduleBackgroundWorker()
                        }
                    }
            } footer: {
                VStack(alignment: .leading){
                    Text(String(localized: "feature_subscription_expiry_notification_desc"))
                    Spacer()
                    Spacer()
                    Text(subscriptionExpiryText)
                }.padding(.top)
                
            }
        }.task {
            await checkSubscriptionExpiry()
        }
        
        .navigationTitle(String(localized: "feature_subscription_expiry_notification"))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    
    private func setSubscriptionInfoText(user: UserResource?) {
        if let user = user {
            if user.subscription != nil {
                if let subscriptionEndsAt = user.subscription_ends_at {
                    do {
                        let expiryDate = try DateTimeUtils.turnStringIntoLocalDateTime(subscriptionEndsAt) // Get the expiry date
                        let text = expiryDate.futureDateDisplay() // Use the new method here
                        subscriptionExpiryText = String(format: String(localized: "subscription_expiry_date"), text)
                    } catch {
                        // Panic
                        LoggingHelper().addLog(
                            importance: LogImportance.critical,
                            error: "Could not parse subscriptionEndsAt",
                            method: "setSubscriptionInfoText",
                            extra: error.localizedDescription)
                        
                        subscriptionExpiryText = String(localized: "subscription_expiry_date_unknown")
                    }
                } else {
                    subscriptionExpiryText = String(localized: "subscription_expiry_date_unknown")
                }
            } else {
                subscriptionExpiryText = String(localized: "subscription_expiry_date_never")
            }
        } else {
            subscriptionExpiryText = String(localized: "subscription_expiry_date_unknown")
        }
    }
    
    
    private func checkSubscriptionExpiry() async {
        if (AddyIo.VERSIONMAJOR == 9999) {
            do {
                let userResource = try await NetworkHelper().getUserResource()
                setSubscriptionInfoText(user: userResource)
            } catch {
                print("Failed to get user resource: \(error)")
            }
        } else {
            subscriptionExpiryText = String(localized: "subscription_expiry_date_self_hosted")
            toggleDescription = String(localized: "subscription_expiry_date_self_hosted")
            isToggleDisabled = true
        }
    }

    
}

#Preview {
    AppSettingsFeaturesNotifySubscriptionExpiryView()
}
