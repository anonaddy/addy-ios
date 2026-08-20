//
//  SelectMailClientBottomSheet.swift
//  addy
//
//  Created by Antigravity on 20/08/2026.
//

import addy_shared
import SwiftUI

struct SelectMailClientBottomSheet: View {
    @Environment(\.dismiss) var dismiss

    var isSettingsMode: Bool = false
    @State private var currentPreferredScheme: String = ""
    @State private var setAsPreferred: Bool = false
    @State private var clients: [ThirdPartyMailClient] = []

    let onSelectClient: ((ThirdPartyMailClient?) -> Void)?

    init(isSettingsMode: Bool = false, onSelectClient: ((ThirdPartyMailClient?) -> Void)? = nil) {
        self.isSettingsMode = isSettingsMode
        self.onSelectClient = onSelectClient
    }

    var body: some View {
        #if DEBUG
            let _ = Self._printChanges()
        #endif
        NavigationStack {
            List {
                if isSettingsMode {
                    Section {
                        Button {
                            let settingsManager = SettingsManager(encrypted: false)
                            settingsManager.putSettingsString(key: .preferredMailClient, string: "")
                            currentPreferredScheme = ""
                            onSelectClient?(nil)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "questionmark.circle.fill")
                                    .foregroundColor(.gray)
                                    .frame(width: 28, height: 28)

                                Text(String(localized: "always_ask"))
                                    .foregroundColor(.primary)

                                Spacer()

                                if currentPreferredScheme.isEmpty {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }

                        ForEach(clients, id: \.self) { client in
                            Button {
                                let settingsManager = SettingsManager(encrypted: false)
                                settingsManager.putSettingsString(key: .preferredMailClient, string: client.URLScheme)
                                currentPreferredScheme = client.URLScheme
                                onSelectClient?(client)
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: client.URLScheme == ThirdPartyMailClient.systemDefault.URLScheme ? "envelope.fill" : "paperplane.fill")
                                        .foregroundColor(.accentColor)
                                        .frame(width: 28, height: 28)

                                    Text(client.name)
                                        .foregroundColor(.primary)

                                    Spacer()

                                    if currentPreferredScheme == client.URLScheme {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                        }
                    } header: {
                        Text(String(localized: "preferred_email_client"))
                    } footer: {
                        Text(String(localized: "preferred_email_client_desc"))
                    }
                } else {
                    Section {
                        ForEach(clients, id: \.self) { client in
                            Button {
                                if setAsPreferred {
                                    let settingsManager = SettingsManager(encrypted: false)
                                    settingsManager.putSettingsString(key: .preferredMailClient, string: client.URLScheme)
                                }
                                onSelectClient?(client)
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: client.URLScheme == ThirdPartyMailClient.systemDefault.URLScheme ? "envelope.fill" : "paperplane.fill")
                                        .foregroundColor(.accentColor)
                                        .frame(width: 28, height: 28)

                                    Text(client.name)
                                        .foregroundColor(.primary)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(UIColor.tertiaryLabel))
                                }
                            }
                        }
                    } header: {
                        Text(String(localized: "select_mail_client"))
                    }

                    Section {
                        Toggle(isOn: $setAsPreferred) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(String(localized: "set_as_preferred_email_client"))
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Text(String(localized: "preferred_email_client_desc"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(isSettingsMode ? String(localized: "preferred_email_client") : String(localized: "select_mail_client"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Label(String(localized: "cancel", bundle: Bundle(for: SharedData.self)), systemImage: "xmark")
                    }
                }
            }
            .onAppear {
                let settingsManager = SettingsManager(encrypted: false)
                self.currentPreferredScheme = settingsManager.getSettingsString(key: .preferredMailClient) ?? ""
                self.clients = ThirdPartyMailClient.availableClients()
            }
        }
    }
}

#Preview {
    SelectMailClientBottomSheet(isSettingsMode: true)
}
