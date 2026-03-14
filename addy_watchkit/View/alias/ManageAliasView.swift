//
//  ManageAliasView.swift
//  Addy Watchkit Watch App
//

import SwiftUI
import addy_shared

struct ManageAliasView: View {
    @State private var alias: Aliases
    @State private var isAliasActive: Bool = false
    @State private var isChangingActivationStatus: Bool = false
    @State private var isAliasPinned: Bool = false
    @State private var isSendingAliasToDevice: Bool = false
    @State private var IsLoadingPinnedButton: Bool = false

    @StateObject private var connectivity = WatchConnectivityManager()

    init(alias: Aliases) {
        _alias = State(initialValue: alias)
    }
    
    public var body: some View {
        List {

            StatRow(
                label: "Forwarded",
                count: alias.emails_forwarded,
                systemImage: "tray",
                color: .orange
            )
            StatRow(
                label: "Replied",
                count: alias.emails_replied,
                systemImage: "arrow.triangle.2.circlepath",
                color: .blue
            )
            StatRow(
                label: "Sent",
                count: alias.emails_sent,
                systemImage: "arrow.right.to.line",
                color: Color.blue.opacity(0.8)
            )
            StatRow(
                label: "Blocked",
                count: alias.emails_blocked,
                systemImage: "xmark.circle",
                color: Color.red.opacity(0.8)
            )
                
            Toggle(isOn: $isAliasActive) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isAliasActive ? String(localized: "alias_activated", bundle: Bundle(for: SharedData.self)) : String(localized: "alias_deactivated", bundle: Bundle(for: SharedData.self)))
                    Text(isChangingActivationStatus ? String(localized: "changing_status") : String(localized: "alias_status_desc", bundle: Bundle(for: SharedData.self)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .onChange(of: isAliasActive) {
                toggleActive(activate: isAliasActive)
            }
        }
        .navigationTitle(alias.email)
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
            isAliasActive = alias.active
            isAliasPinned = alias.pinned
        }
    }
    
    
    
    private func toggleActive(activate: Bool) {
        if activate {
            Task {
                await activateAlias(alias: alias)
            }
        } else {
            Task {
                await deactivateAlias(alias: alias)
            }
        }
    }
    
    private func activateAlias(alias: Aliases) async {
        let networkHelper = NetworkHelper()
        do {
            guard let activatedAlias = try await networkHelper.activateSpecificAlias(aliasId: alias.id) else { return }
            isChangingActivationStatus = false
            self.alias = activatedAlias
            isAliasActive = true
        } catch {
            isChangingActivationStatus = false
            isAliasActive = false
            
            let okAction = WKAlertAction(title: String(localized: "close", bundle: Bundle(for: SharedData.self)), style: .default) {  }
            WKInterfaceDevice.current().play(.failure)
            WKExtension.shared().visibleInterfaceController?.presentAlert(
                withTitle: String(localized: "error_edit_active", bundle: Bundle(for: SharedData.self)),
                message: error.localizedDescription,
                preferredStyle: .alert,
                actions: [okAction]
            )
        }
    }
    
    private func deactivateAlias(alias: Aliases) async {
        let networkHelper = NetworkHelper()
        do {
            let result = try await networkHelper.deactivateSpecificAlias(aliasId: alias.id)
            if result == "204" {
                isChangingActivationStatus = false
                isAliasActive = false
            } else {
                let okAction = WKAlertAction(title: String(localized: "close", bundle: Bundle(for: SharedData.self)), style: .default) {  }
                WKInterfaceDevice.current().play(.failure)
                WKExtension.shared().visibleInterfaceController?.presentAlert(
                    withTitle: String(localized: "error_edit_active", bundle: Bundle(for: SharedData.self)),
                    message: result,
                    preferredStyle: .alert,
                    actions: [okAction]
                )
            }
        } catch {
            isChangingActivationStatus = false
            isAliasActive = false
            
            let okAction = WKAlertAction(title: String(localized: "close", bundle: Bundle(for: SharedData.self)), style: .default) {  }
            WKInterfaceDevice.current().play(.failure)
            WKExtension.shared().visibleInterfaceController?.presentAlert(
                withTitle: String(localized: "error_edit_active", bundle: Bundle(for: SharedData.self)),
                message: error.localizedDescription,
                preferredStyle: .alert,
                actions: [okAction]
            )
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
            guard let pinnedAlias = try await networkHelper.pinSpecificAlias(aliasId: alias.id) else {
                IsLoadingPinnedButton = false
                isAliasPinned = false
                return
            }
            IsLoadingPinnedButton = false
            self.alias = pinnedAlias
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
                self.alias.pinned = false
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

struct StatRow: View {
    let label: String
    let count: Int
    let systemImage: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundStyle(color)
                .font(.title3)
            
            VStack(alignment: .leading) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                Text("\(count)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
            }
            
            Spacer()
        }
        
    }
}

