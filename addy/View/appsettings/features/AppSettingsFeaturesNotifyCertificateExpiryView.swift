//
//  AppSettingsFeaturesNotifyCertificateExpiryView.swift
//  addy
//
//  Created by Stijn van de Water on 20/09/2026.
//

import addy_shared
import SwiftUI

struct AppSettingsFeaturesNotifyCertificateExpiryView: View {
    @State var notifyCertificateExpiry: Bool = false
    @State var isShowingAddApiBottomSheet: Bool = false
    @State var certificateExpiryText: String = .init(localized: "obtaining_information")
    @State var hasCertificate: Bool = false
    @State var showingRemoveConfirmation: Bool = false

    var body: some View {
        #if DEBUG
            let _ = Self._printChanges()
        #endif
        List {
            Section {
                AddyToggle(
                    isOn: $notifyCertificateExpiry,
                    title: String(localized: "enable_feature"),
                    description: String(localized: "notify_certificate_expiry_feature_section_desc")
                )
                .disabled(!hasCertificate)
                .onAppear {
                    self.notifyCertificateExpiry = MainViewState.shared.settingsManager.getSettingsBool(key: .notifyCertificateExpiry)
                }
                .onChange(of: notifyCertificateExpiry) {
                    if notifyCertificateExpiry != MainViewState.shared.settingsManager.getSettingsBool(key: .notifyCertificateExpiry) {
                        MainViewState.shared.settingsManager.putSettingsBool(key: .notifyCertificateExpiry, boolean: notifyCertificateExpiry)
                        BackgroundWorkerHelper.shared.scheduleAppRefresh()
                    }
                }

                AddySection(title: String(localized: "update_certificate_now"), description: String(localized: "update_certificate_now_desc")) {
                    isShowingAddApiBottomSheet = true
                }

                if hasCertificate {
                    Button(role: .destructive) {
                        showingRemoveConfirmation = true
                    } label: {
                        Text(String(localized: "remove_certificate"))
                    }
                }
            } footer: {
                VStack(alignment: .leading, spacing: 12) {
                    Text(String(localized: "feature_certificate_expiry_notification_desc"))
                    Text(certificateExpiryText)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }.padding(.top)
            }
        }
        .task {
            checkCertificateExpiry()
        }
        .confirmationDialog(
            String(localized: "remove_certificate"),
            isPresented: $showingRemoveConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "remove_certificate"), role: .destructive) {
                removeCertificate()
            }
            Button(String(localized: "cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "remove_certificate_confirm"))
        }
        .sheet(isPresented: $isShowingAddApiBottomSheet) {
            let baseUrl = MainViewState.shared.encryptedSettingsManager.getSettingsString(key: .baseUrl)
            NavigationStack {
                AddApiBottomSheet(apiBaseUrl: baseUrl, addKey: addKey(apiKey:_:p12:p12Password:)).environmentObject(MainViewState.shared)
            }
            .presentationDetents([.large])
        }
        .navigationTitle(String(localized: "feature_certificate_expiry_notification"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func addKey(apiKey: String, _: String, p12: Data?, p12Password: String?) {
        MainViewState.shared.encryptedSettingsManager.putSettingsString(key: .apiKey, string: apiKey)
        MainViewState.shared.encryptedSettingsManager.putSettingsData(key: .p12, data: p12)
        if let p12Password = p12Password {
            MainViewState.shared.encryptedSettingsManager.putSettingsString(key: .p12Password, string: p12Password)
        }
        isShowingAddApiBottomSheet = false

        checkCertificateExpiry()
    }

    private func removeCertificate() {
        MainViewState.shared.encryptedSettingsManager.removeSetting(key: .p12)
        MainViewState.shared.encryptedSettingsManager.removeSetting(key: .p12Password)
        MainViewState.shared.settingsManager.putSettingsBool(key: .notifyCertificateExpiry, boolean: false)
        notifyCertificateExpiry = false
        checkCertificateExpiry()
    }

    private func checkCertificateExpiry() {
        hasCertificate = MainViewState.shared.encryptedSettingsManager.getSettingsData(key: .p12) != nil

        if hasCertificate {
            if let expiryDate = APIClient.shared.getCertificateExpirationDate() {
                let text = expiryDate.futureDateDisplay()
                certificateExpiryText = String(format: NSLocalizedString("certificate_expiry_date", comment: ""), text)
            } else {
                certificateExpiryText = String(localized: "certificate_expiry_date_unknown")
            }
        } else {
            certificateExpiryText = String(localized: "no_certificate_configured")
        }
    }
}

#Preview {
    AppSettingsFeaturesNotifyCertificateExpiryView()
}
