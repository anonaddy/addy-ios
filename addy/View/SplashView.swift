//
//  SplashView.swift
//  addy
//
//  Created by Stijn van de Water on 06/05/2024.
//

import addy_shared
import Lottie
import SwiftUI

struct SplashView: View {
    @EnvironmentObject var mainViewState: MainViewState

    @Environment(\.openURL) var openURL

    @State private var showError = false
    @State private var isPresentUnsupportedVersionBottomDialog = false
    @State private var isShowingDetailedErrorAlert = false
    @State private var detailedError: String? = ""
    @State private var serviceStatus: ServiceStatus? = nil
    @State private var isLoadingStatus = false

    var body: some View {
        #if DEBUG
            let _ = Self._printChanges()
        #endif
        Group {
            if showError {
                errorView
            } else {
                loadingView
            }
        }.task {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-test_down") {
                await simulateDownStatus()
                return
            }
            #endif
            loadDataAndStartApp()
        }
        .alert(isPresented: $isShowingDetailedErrorAlert, content: {
            if NetworkUtils.isLocalAddress(AddyIo.API_BASE_URL) {
                Alert(
                    title: Text(String(localized: "error", bundle: Bundle(for: SharedData.self))),
                    message: Text(detailedError ?? String(localized: "unknown")),
                    primaryButton: .default(Text(String(localized: "open_settings"))) {
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsURL)
                        }
                    },
                    secondaryButton: .cancel(Text(String(localized: "close", bundle: Bundle(for: SharedData.self))))
                )
            } else {
                Alert(
                    title: Text(String(localized: "error", bundle: Bundle(for: SharedData.self))),
                    message: Text(detailedError ?? String(localized: "unknown")),
                    dismissButton: .default(Text(String(localized: "close", bundle: Bundle(for: SharedData.self))))
                )
            }
        })
        .sheet(isPresented: $isPresentUnsupportedVersionBottomDialog, onDismiss: {
            isPresentUnsupportedVersionBottomDialog = false
            Task {
                await getUserResource()
            }
        }, content: {
            NavigationStack {
                UnsupportedBottomSheet {
                    openURL(URL(string: "https://github.com/anonaddy/anonaddy/blob/master/SELF-HOSTING.md#updating")!)
                } onClickIgnore: {
                    isPresentUnsupportedVersionBottomDialog = false
                    Task {
                        await getUserResource()
                    }
                }
            }
            .presentationDetents([.fraction(0.45), .large])
            // No cancel button so a drag indicator is a nice to have
            .presentationDragIndicator(.visible)
        })
    }

    private var loadingView: some View {
        Color.accentColor
            .ignoresSafeArea(.container) // Ignore just for the color
            .overlay(
                VStack(spacing: 20) {
                    LottieView(animation: .named("ic_loading_logo.shapeshifter"))
                        .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                        .animationSpeed(Double(2))
                        .frame(maxHeight: 128)
                        .opacity(0.5)
                }
            )
    }

    private var errorView: some View {
        Color.accentColor
            .ignoresSafeArea(.container) // Ignore just for the color
            .overlay(
                VStack {
                    VStack {
                        Text(String(localized: "whoops"))
                            .foregroundStyle(.white)
                            .font(.title)
                            .fontWeight(.heavy)
                            .padding(.bottom)
                        Text(String(localized: "addyio_load_error"))
                            .foregroundStyle(.white)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding(.bottom)
                        Text(String(localized: "tap_here_to_see_the_error"))
                            .foregroundStyle(.red)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .onTapGesture {
                                isShowingDetailedErrorAlert = true
                            }

                        if AddyIo.isDefaultInstance() {
                            if let status = serviceStatus {
                                statusCard(status: status)
                                    .padding(.top, 8)
                            } else if isLoadingStatus {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.8)
                                    Text(String(localized: "status_checking"))
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .padding(.top, 8)
                            }
                        }
                    }
                    .padding()
                    #if DEBUG
                    .onLongPressGesture {
                        Task {
                            await simulateDownStatus()
                        }
                    }
                    #endif
                    Spacer()
                    LottieView(animation: .named("ic_loading_logo_error.shapeshifter"))
                        .playbackMode(.playing(.toProgress(1, loopMode: .playOnce)))
                        .animationSpeed(Double(2))
                        .frame(maxHeight: 128)
                        .opacity(0.5)
                        #if DEBUG
                        .onLongPressGesture {
                            Task {
                                await simulateDownStatus()
                            }
                        }
                        #endif
                    Spacer()
                    Spacer()
                    HStack {
                        AddyButton(action: {
                            loadDataAndStartApp()

                        }, style: AddyButtonStyle()) {
                            Text(String(localized: "try_again", bundle: Bundle(for: SharedData.self))).foregroundColor(Color.white)
                        }

                        if NetworkUtils.isLocalAddress(AddyIo.API_BASE_URL) {
                            AddyButton(action: {
                                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(settingsURL)
                                }
                            }, style: AddyButtonStyle()) {
                                Text(String(localized: "open_settings")).foregroundColor(Color.white)
                            }
                        }

                        AddyButton(action: {
                            let settingsManager = SettingsManager(encrypted: true)
                            settingsManager.clearSettingsAndCloseApp()

                        }, style: AddyButtonStyle(buttonStyle: .destructive)) { // TODO: Make red
                            Text(String(localized: "reset_app", bundle: Bundle(for: SharedData.self))).foregroundColor(Color.white)
                        }
                    }.padding()
                }
            )
    }

    private func loadDataAndStartApp() {
        showError = false
        serviceStatus = nil
        isLoadingStatus = false

        #if DEBUG
            let defaultBaseUrl = String(localized: "dev_base_url")
        #else
            let defaultBaseUrl = String(localized: "default_base_url")
        #endif

        if AddyIo.API_BASE_URL == defaultBaseUrl {
            AddyIo.VERSIONMAJOR = 9999
            AddyIo.VERSIONSTRING = String(localized: "latest")

            Task {
                await getUserResource()
            }
        } else {
            Task {
                await getAddyIoInstanceVersion()
            }
        }
    }

    private func getAddyIoInstanceVersion() async {
        do {
            let version = try await AppMaintenanceRepository.shared.getAddyIoInstanceVersion()
            AddyIo.VERSIONMAJOR = version.major
            AddyIo.VERSIONMINOR = version.minor
            AddyIo.VERSIONPATCH = version.patch
            AddyIo.VERSIONSTRING = version.version ?? String(localized: "unknown")

            if instanceHasTheMinimumRequiredVersion() {
                await getUserResource()
            } else {
                isPresentUnsupportedVersionBottomDialog = true
            }
        } catch {
            detailedError = formatErrorMessage(error: error)
            showError = true
            await checkServiceStatusIfNeeded()
        }
    }

    private func instanceHasTheMinimumRequiredVersion() -> Bool {
        if AddyIo.VERSIONMAJOR > AddyIo.MINIMUMVERSIONCODEMAJOR {
            return true
        } else if AddyIo.VERSIONMAJOR >= AddyIo.MINIMUMVERSIONCODEMAJOR {
            if AddyIo.VERSIONMINOR > AddyIo.MINIMUMVERSIONCODEMINOR {
                return true
            } else if AddyIo.VERSIONMINOR >= AddyIo.MINIMUMVERSIONCODEMINOR {
                if AddyIo.VERSIONPATCH >= AddyIo.MINIMUMVERSIONCODEPATCH {
                    return true
                }
            }
        }
        return false
    }

    private func getUserResource() async {
        do {
            let userResource = try await UserRepository.shared.getUserResource()
            mainViewState.userResource = userResource

            // Fetch UserResourceExtended data
            let recipient = try await RecipientRepository.shared.getRecipient(recipientId: userResource.default_recipient_id)
            DispatchQueue.main.async {
                withAnimation {
                    mainViewState.userResourceExtended = UserResourceExtended(default_recipient_email: recipient.email)
                }
            }
        } catch {
            detailedError = formatErrorMessage(error: error)
            showError = true
            await checkServiceStatusIfNeeded()
        }
    }

    private func formatErrorMessage(error: Error) -> String {
        var message = error.localizedDescription
        if NetworkUtils.isLocalAddress(AddyIo.API_BASE_URL) {
            message += "\n\n" + String(localized: "local_network_permission_rationale")
        }
        return message
    }

    private func checkServiceStatusIfNeeded() async {
        guard AddyIo.isDefaultInstance() else { return }
        await MainActor.run {
            isLoadingStatus = true
        }
        do {
            let status = try await AppMaintenanceRepository.shared.getServiceStatus()
            await MainActor.run {
                withAnimation {
                    self.serviceStatus = status
                    self.isLoadingStatus = false
                }
            }
        } catch {
            await MainActor.run {
                withAnimation {
                    self.isLoadingStatus = false
                }
            }
        }
    }

    /// Test method to simulate or trigger status update checks
    public func testStatusUpdateChecks(mockStatus: ServiceStatus? = nil) async {
        await MainActor.run {
            showError = true
            detailedError = "Test error: Failed to connect to addy.io"
        }
        if let mock = mockStatus {
            await MainActor.run {
                withAnimation {
                    self.serviceStatus = mock
                    self.isLoadingStatus = false
                }
            }
        } else {
            await checkServiceStatusIfNeeded()
        }
    }

    public func simulateDownStatus(
        title: String = "Unplanned downtime due to vulnerability",
        text: String = "We are temporarily offline.\n\naddy.io is currently unavailable. Due to maintenance, we have temporarily shut down our web systems.\n\nEmail delivery will continue as expected."
    ) async {
        let mock = ServiceStatus(
            pinnedUpdate: StatusUpdate(
                title: title,
                text: text,
                pinned: true,
                severity: "warning",
                time: Int(Date().timeIntervalSince1970)
            ),
            summarizedStatus: "down"
        )
        await testStatusUpdateChecks(mockStatus: mock)
    }

    @ViewBuilder
    private func statusCard(status: ServiceStatus) -> some View {
        Button(action: {
            if let url = URL(string: AddyIo.STATUS_URL) {
                openURL(url)
            }
        }) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(status.isOperational ? Color.green : Color.orange)
                        .frame(width: 10, height: 10)

                    Text(status.isOperational ? String(localized: "status_all_systems_operational") : (status.latestUpdate?.title ?? String(localized: "status_service_disruption")))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }

                if !status.isOperational, let text = status.latestUpdate?.text, !text.isEmpty {
                    Text(text.trimmingCharacters(in: .whitespacesAndNewlines))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }

                Text(String(localized: "status_addy_io"))
                    .font(.caption2)
                    .italic()
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview("Normal") {
    SplashView()
}

#Preview("Simulated Outage") {
    let view = SplashView()
    view.task {
        await view.simulateDownStatus()
    }
}
