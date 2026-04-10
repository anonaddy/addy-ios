//
//  CreateAliasView.swift
//  addy
//
//  Created by Stijn van de Water on 07/02/2026.
//


import SwiftUI
import WatchKit
import addy_shared
import Combine

struct CreateAliasView: View {
    @StateObject private var viewModel: CreateAliasViewModel
    @State private var skipAliasCreateGuide = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var mainViewState: MainViewState

    
    init() {
        _viewModel = StateObject(wrappedValue: CreateAliasViewModel())
    }
    
    var body: some View {
        ScrollView {
            if let alias = viewModel.alias {
                CreatedAliasDetails(alias: alias)
            } else if skipAliasCreateGuide {
                ProgressView("creating_alias")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                AliasCreateGuide(
                    onIUnderstand: {
                        SettingsManager(encrypted: true).putSettingsBool(key: .watchosSkipAliasCreateGuide, boolean: true)
                        viewModel.createAlias()
                    }
                )
            }
        }
        .navigationTitle(String(localized: "add_alias", bundle: Bundle(for: SharedData.self)))
        .navigationBarTitleDisplayMode(.inline)
        .containerBackground(Color.gray.opacity(0.1).gradient, for: .navigation)
        .task {
            await viewModel.checkUserAndCreate(
                skipAliasCreateGuide: skipAliasCreateGuide,
                appState: appState,
                mainViewState: mainViewState
            )
        }
        .onAppear {
            viewModel.setDismissAction { dismiss() }
            self.skipAliasCreateGuide = SettingsManager(encrypted: true).getSettingsBool(key: .watchosSkipAliasCreateGuide)
        }
    }
}

@MainActor
class CreateAliasViewModel: ObservableObject {
    @Published var alias: Aliases?
    
    private var onDismiss: (() -> Void)?
    
    func checkUserAndCreate(
        skipAliasCreateGuide: Bool,
        appState: AppState,
        mainViewState: MainViewState
    ) async {
        guard appState.apiKey != nil else { return }
        
        if skipAliasCreateGuide {
            createAlias(domain: mainViewState.userResource?.default_alias_domain)
        }
    }
    
    func createAlias(domain: String? = nil) {
        Task {
            do {
                guard let userResource = CacheHelper.getBackgroundServiceCacheUserResource() else { return }
                
                let result = try await NetworkHelper().addAlias(
                    domain: domain ?? userResource.default_alias_domain,
                    description: String(localized: "created_on_apple_watch"),
                    format: userResource.default_alias_format == "custom" ? "random_characters" : userResource.default_alias_format,
                    localPart: "", recipients: nil
                )
                
                self.alias = result
                
            } catch {
                let okAction = WKAlertAction(title: String(localized: "close", bundle: Bundle(for: SharedData.self)), style: .default) { 
                    self.onDismiss?()
                }
                WKInterfaceDevice.current().play(.failure)
                WKExtension.shared().visibleInterfaceController?.presentAlert(
                    withTitle: String(localized: "error", bundle: Bundle(for: SharedData.self)),
                    message: error.localizedDescription,
                    preferredStyle: .alert,
                    actions: [okAction]
                )
            }
        }
    }
    
    // Call this from View after .task
    func setDismissAction(_ dismiss: @escaping () -> Void) {
        self.onDismiss = dismiss
    }
}


// MARK: - Supporting Views (stubs - implement based on your Kotlin components)
struct CreatedAliasDetails: View {
    @StateObject private var connectivity = WatchConnectivityManager()
    @State private var isSendingAliasToDevice: Bool = false
    @State private var isAliasPinned: Bool = false
    @State private var IsLoadingPinnedButton: Bool = false
    
    let alias: Aliases
    
    var body: some View {
        ZStack {
                // Full screen centering
                Text(alias.email)
                    .font(.title)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        .navigationTitle(String(localized: "add_alias", bundle: Bundle(for: SharedData.self)))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Toggle("", systemImage: isAliasPinned ? "pin.fill" : "pin", isOn: $isAliasPinned)
                        .toggleStyle(.button)
                        .foregroundStyle(isAliasPinned ? .primary : .secondary)
                        .overlay {
                            if IsLoadingPinnedButton {
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }
                        .onChange(of: isAliasPinned) { _, newValue in
                            togglePinned()
                        }
                                
                    Spacer()
                    
                
                    Button {
                        showOnPairedDevice()
                    } label: {
                        if isSendingAliasToDevice {
                            ProgressView()
                        } else {
                            Image(systemName:"iphone.gen3")
                        }
                    }
                }
        }
        .containerBackground(Color.gray.opacity(0.1).gradient, for: .navigation)
        .onAppear {
            isAliasPinned = alias.pinned
        }
    }
    
    
    private func togglePinned() {
        IsLoadingPinnedButton = true

        if (isAliasPinned) {
            Task {
               await pinAlias(alias: alias)
            }
        } else {
            Task {
                await unpinAlias(alias: alias)
            }
        }
    }
    
    private func pinAlias(alias: Aliases) async {
        let networkHelper = NetworkHelper()
        do {
            guard (try await networkHelper.pinSpecificAlias(aliasId: alias.id)) != nil else { return }
            IsLoadingPinnedButton = false
            isAliasPinned = true
        } catch {
            IsLoadingPinnedButton = false
            isAliasPinned = false
            
            let okAction = WKAlertAction(title: String(localized: "close", bundle: Bundle(for: SharedData.self)), style: .default) {  }
            WKInterfaceDevice.current().play(.failure)
            WKExtension.shared().visibleInterfaceController?.presentAlert(
                withTitle: String(localized: "error_edit_pinned", bundle: Bundle(for: SharedData.self)),
                message: error.localizedDescription,
                preferredStyle: .alert,
                actions: [okAction]
            )
        }
    }
    
    private func unpinAlias(alias: Aliases) async {
        let networkHelper = NetworkHelper()
        do {
            let result = try await networkHelper.unpinSpecificAlias(aliasId: alias.id)
            IsLoadingPinnedButton = false
            if result == "204" {
                isAliasPinned = false
            } else {
                isAliasPinned = true
            
                let okAction = WKAlertAction(title: String(localized: "close", bundle: Bundle(for: SharedData.self)), style: .default) {  }
                WKInterfaceDevice.current().play(.failure)
                WKExtension.shared().visibleInterfaceController?.presentAlert(
                    withTitle: String(localized: "error_edit_pinned", bundle: Bundle(for: SharedData.self)),
                    message: result,
                    preferredStyle: .alert,
                    actions: [okAction]
                )
            }
        } catch {
            IsLoadingPinnedButton = false
            isAliasPinned = true
            
            let okAction = WKAlertAction(title: String(localized: "close", bundle: Bundle(for: SharedData.self)), style: .default) {  }
            WKInterfaceDevice.current().play(.failure)
            WKExtension.shared().visibleInterfaceController?.presentAlert(
                withTitle: String(localized: "error_edit_pinned", bundle: Bundle(for: SharedData.self)),
                message: error.localizedDescription,
                preferredStyle: .alert,
                actions: [okAction]
            )
        }
    }
    
    private func showOnPairedDevice() {
        self.isSendingAliasToDevice = true
        
        connectivity.showAliasOnWatch(aliasId: alias.id, email: alias.email, replyHandler: { reply in
            DispatchQueue.main.async {
                self.isSendingAliasToDevice = false
                
                let successAction = WKAlertAction(title: String(localized: "close", bundle: Bundle(for: SharedData.self)) , style: .default) {  }
                WKInterfaceDevice.current().play(.success)
                WKExtension.shared().visibleInterfaceController?.presentAlert(
                    withTitle: String(localized: "success"),
                    message: String(localized: "show_on_paired_device_success"),
                    preferredStyle: .alert,
                    actions: [successAction]
                )
                
                // Dismiss after 2s
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    WKExtension.shared().visibleInterfaceController?.dismiss()
                }
            }
        }, errorHandler: { error in
            DispatchQueue.main.async {
                self.isSendingAliasToDevice = false
                
                
                let okAction = WKAlertAction(title: String(localized: "close", bundle: Bundle(for: SharedData.self)), style: .default) {  }
                WKInterfaceDevice.current().play(.failure)
                WKExtension.shared().visibleInterfaceController?.presentAlert(
                    withTitle: String(localized: "error", bundle: Bundle(for: SharedData.self)),
                    message: error.localizedDescription,
                    preferredStyle: .alert,
                    actions: [okAction]
                )
            }
        })
    }
}



struct AliasCreateGuide: View {
    let onIUnderstand: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text(String(localized: "watchos_create_alias_guide"))
                .foregroundStyle(.secondary)
            
            if #available(watchOS 26.0, *) {
                Button(String(localized: "understood", bundle: Bundle(for: SharedData.self))) {
                    onIUnderstand()
                }.buttonStyle(.glassProminent)
            } else {
                Button(String(localized: "understood", bundle: Bundle(for: SharedData.self))) {
                    onIUnderstand()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
