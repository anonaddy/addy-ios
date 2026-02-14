//
//  AddySetupSheet.swift
//  addy
//
//  Created by Stijn van de Water on 01/02/2026.
//


import SwiftUI
import addy_shared

struct AddyWatchKitSetupBottomSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var mainViewState: MainViewState
    @EnvironmentObject var connectivityManager: iOSConnectivityManager
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack {
                        
                        Image("watchkit_setup")
                        
                        AddyButton(action: {
                            self.handleConfirm()
                        }) {
                            Text(String(localized: "confirm_and_setup")).foregroundColor(Color.white)
                        }
                        
                        Button(String(localized: "do_not_ask_again")) {
                            mainViewState.settingsManager.putSettingsBool(key: .enableWatchKitQuickSetupDialog, boolean: false)
                            dismiss()
                        }.frame(maxWidth: .infinity)
                    }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())
                } header: {
                    VStack(alignment: .leading) {
                        Text(String(format: String(localized: "setup_wearable_app_desc"), connectivityManager.watchName, mainViewState.userResource!.username))
                    }
                    .multilineTextAlignment(.center)
                    .padding(.bottom)
                }.textCase(nil).listRowBackground(Color.clear).listRowInsets(EdgeInsets())
            }.navigationTitle(String(localized: "setup_wearable_app"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(content: {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            dismiss()
                        } label: {
                            Label(String(localized: "dismiss"), systemImage: "xmark")
                        }
                    }
                })
            
        }
    }
    
    private func handleConfirm() {
        isLoading = true
        
        // Your setup logic here
        Task {
            var apiKey = SettingsManager(encrypted: true).getSettingsString(key: .apiKey)
            connectivityManager.setupAppleWatchApp(requestId: connectivityManager.requestId, baseUrl: AddyIo.API_BASE_URL, apiKey: apiKey!)
            
            await MainActor.run {
                isLoading = false
                dismiss()
            }
        }
    }
}


#Preview {
    AddyWatchKitSetupBottomSheet()
}
