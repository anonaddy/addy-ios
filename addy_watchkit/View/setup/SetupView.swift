//
// SetupView.swift
// addy
//
// Created by Stijn van de Water on 01/02/2026.
//

import SwiftUI
import WatchConnectivity
import WatchKit
import addy_shared
import Combine

struct SetupView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var connectivity = WatchConnectivityManager()


    var body: some View {
        Group {
            VStack(spacing: 20) {
                // Animated app icon
                Image("addy_icon")
                    .resizable()
                    .frame(width: 56, height: 56)
                    .onTapGesture {
                        connectivity.nagForSetup()
                    }

                VStack(spacing: 6) {
                    Text("setup_watchos_open_addyio")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                    Text("setup_watchos_check_paired_device")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                    Text(connectivity.statusText)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .animation(.easeInOut(duration: 0.3), value: connectivity.statusText)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            }
            .padding(.top, 35)
            .frame(minHeight: 300)
        }.onAppear {
            connectivity.startPeriodicNagging()
            connectivity.onSetupComplete = { apiKey in
                self.appState.apiKey = apiKey
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
        )
    }
}


