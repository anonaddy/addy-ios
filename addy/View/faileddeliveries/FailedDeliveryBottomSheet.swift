//
//  FailedDeliveryBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 03/06/2024.
//

import addy_shared
import AVFoundation
import SwiftUI

struct FailedDeliveryBottomSheet: View {
    @State var failedDelivery: FailedDeliveries
    @EnvironmentObject var mainViewState: MainViewState

    let onDeleted: () -> Void

    init(failedDelivery: FailedDeliveries, onDeleted: @escaping () -> Void) {
        self.failedDelivery = failedDelivery
        self.onDeleted = onDeleted
    }

    @State var isLoadingDeleteButton: Bool = false
    @State var isLoadingDownloadButton: Bool = false
    @State var isLoadingResendButton: Bool = false
    @State var isLoadingBlocklistButton: Bool = false
    @State private var isShowingPicker = false
    @State private var fileURL: URL?

    enum ActiveAlert {
        case error
        case resend
        case blocklist
    }

    @State private var activeAlert: ActiveAlert = .error
    @State private var showAlert: Bool = false
    @State private var errorAlertTitle = ""
    @State private var errorAlertMessage = ""

    @Environment(\.dismiss) var dismiss

    var body: some View {
        #if DEBUG
            let _ = Self._printChanges()
        #endif

        Form {
            Section {
                let formattedString = String.localizedStringWithFormat(NSLocalizedString("failed_delivery_details_text", comment: ""),
                                                                       failedDelivery.created_at,
                                                                       failedDelivery.destination ?? "",
                                                                       failedDelivery.alias_email ?? "",
                                                                       failedDelivery.sender ?? "",
                                                                       failedDelivery.remote_mta,
                                                                       failedDelivery.attempted_at,
                                                                       failedDelivery.code)
                Text(LocalizedStringKey(formattedString))
                    .multilineTextAlignment(.leading)
            } header: {
                Text(failedDelivery.email_type_text.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.1))
                    .foregroundColor(.accentColor)
                    .cornerRadius(4)
            }
        }
        .navigationTitle(String(localized: "details"))
        .sheet(isPresented: $isShowingPicker) {
            if let url = fileURL {
                DocumentPicker(fileURL: $fileURL, isPresented: $isShowingPicker, fileToSave: url)
            }
        }
        .pickerStyle(.navigationLink)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            ToolbarItem {
                Button {
                    dismiss()
                } label: {
                    Label(String(localized: "dismiss"), systemImage: "xmark")
                }
            }

            ToolbarItem(placement: .bottomBar) {
                deleteFailedDeliveryButton()
            }

            if let sender = self.failedDelivery.sender, !sender.isEmpty, !mainViewState.userResource!.hasUserFreeSubscription() {
                ToolbarItem(placement: .bottomBar) {
                    blocklistSenderButton()
                }
            }

            if self.failedDelivery.is_stored {
                ToolbarItem(placement: .bottomBar) {
                    downloadFailedDeliveryButton()
                }
            }

            if #available(iOS 26.0, *) {
                ToolbarSpacer(placement: .bottomBar)
            }

            if self.failedDelivery.is_stored && !self.failedDelivery.quarantined && !self.failedDelivery.resent && self.failedDelivery.email_type == "F" {
                ToolbarItem(placement: .bottomBar) {
                    resendFailedDeliveryButton()
                }
            }
            

        })
        .alert(isPresented: $showAlert) {
            switch activeAlert {
            case .error:
                return Alert(
                    title: Text(errorAlertTitle),
                    message: Text(errorAlertMessage)
                )
            case .resend:
                return Alert(title: Text(String(localized: "resend_failed_delivery")), message: Text(String(localized: "resend_failed_delivery_confirmation_desc")), primaryButton: .default(Text(String(localized: "resend"))) {
                    Task {
                        isLoadingResendButton = true
                        await self.resendFailedDelivery()
                    }
                }, secondaryButton: .cancel {
                    isLoadingResendButton = false
                })
            case .blocklist:
                return Alert(
                    title: Text(String(localized: "blocklist_add")),
                    message: Text(String(format: String(localized: "blocklist_add_confirmation"), failedDelivery.sender ?? "")),
                    primaryButton: .destructive(Text(String(localized: "blocklist_add"))) {
                        Task {
                            isLoadingBlocklistButton = true
                            await self.blocklistSender()
                        }
                    }, secondaryButton: .cancel {
                        isLoadingBlocklistButton = false
                    }
                )
            }
        }
    }

    private func downloadFailedDeliveryButton() -> some View {
        Group {
            if isLoadingDownloadButton {
                AnyView(ProgressView().progressViewStyle(.circular))
            } else {
                AnyView(
                    Button {
                        isLoadingDownloadButton = true

                        Task {
                            await self.downloadFailedDelivery()
                        }

                    } label: {
                        Label(String(localized: "download_failed_delivery"), systemImage: "square.and.arrow.down")
                    }
                )
            }
        }
    }

    private func resendFailedDeliveryButton() -> some View {
        Group {
            if isLoadingResendButton {
                AnyView(ProgressView().progressViewStyle(.circular))
            } else {
                AnyView(
                    Button {
                        activeAlert = .resend
                        showAlert = true
                    } label: {
                        Label(String(localized: "resend_failed_delivery"), systemImage: "arrowshape.turn.up.forward")
                    }
                )
            }
        }
    }

    private func deleteFailedDeliveryButton() -> some View {
        Group {
            if isLoadingDeleteButton {
                AnyView(ProgressView().progressViewStyle(.circular))
            } else {
                AnyView(
                    Button {
                        isLoadingDeleteButton = true

                        Task {
                            await self.deleteFailedDelivery()
                        }

                    } label: {
                        Label(String(localized: "delete_failed_delivery"), systemImage: "trash")
                    }
                )
            }
        }
    }

    private func blocklistSenderButton() -> some View {
        Group {
            if isLoadingBlocklistButton {
                AnyView(ProgressView().progressViewStyle(.circular))
            } else {
                AnyView(
                    Button {
                        activeAlert = .blocklist
                        showAlert = true
                    } label: {
                        Label(String(localized: "blocklist_add"), systemImage: "nosign")
                    }
                )
            }
        }
    }

    private func blocklistSender() async {
        guard let sender = failedDelivery.sender, !sender.isEmpty else {
            isLoadingBlocklistButton = false
            return
        }

        let type = sender.contains("@") ? "email" : "domain"
        let entry = NewBlocklistEntry(type: type, value: sender)
        
        let networkHelper = NetworkHelper()
        do {
            _ = try await networkHelper.addBlocklistEntry(entry: entry)
            isLoadingBlocklistButton = false
            errorAlertTitle = String(localized: "blocklist_add")
            errorAlertMessage = String(localized: "blocklist_add_success")
            activeAlert = .error
            showAlert = true
        } catch {
            isLoadingBlocklistButton = false
            errorAlertTitle = String(localized: "error", bundle: Bundle(for: SharedData.self))
            errorAlertMessage = error.localizedDescription
            activeAlert = .error
            showAlert = true
        }
    }

    private func deleteFailedDelivery() async {
        let networkHelper = NetworkHelper()
        do {
            let result = try await networkHelper.deleteFailedDelivery(failedDeliveryId: failedDelivery.id)
            isLoadingDeleteButton = false
            if result == "204" {
                onDeleted()
            } else {
                isLoadingDeleteButton = false
                errorAlertTitle = String(localized: "error_deleting_failed_delivery")
                errorAlertMessage = result
                activeAlert = .error
                showAlert = true
            }
        } catch {
            isLoadingDeleteButton = false
            errorAlertTitle = String(localized: "error_deleting_failed_delivery")
            errorAlertMessage = error.localizedDescription
            activeAlert = .error
            showAlert = true
        }
    }

    private func resendFailedDelivery() async {
        let networkHelper = NetworkHelper()
        do {
            let result = try await networkHelper.resendFailedDelivery(failedDeliveryId: failedDelivery.id)
            isLoadingResendButton = false
            if result == "204" {
                isLoadingResendButton = false
                errorAlertTitle = String(localized: "resend_failed_delivery")
                errorAlertMessage = String(localized: "failed_delivery_resend_success")
                activeAlert = .error
                showAlert = true
            } else {
                isLoadingResendButton = false
                errorAlertTitle = String(localized: "error_resending_failed_delivery")
                errorAlertMessage = result
                activeAlert = .error
                showAlert = true
            }
        } catch {
            isLoadingResendButton = false
            errorAlertTitle = String(localized: "error_resending_failed_delivery")
            errorAlertMessage = error.localizedDescription
            activeAlert = .error
            showAlert = true
        }
    }

    private func downloadFailedDelivery() async {
        let networkHelper = NetworkHelper()
        do {
            // Assuming 'downloadFailedDelivery' returns an optional URL
            let fileURL: URL? = try await networkHelper.downloadFailedDelivery(failedDeliveryId: failedDelivery.id)
            isLoadingDownloadButton = false

            if let url = fileURL {
                self.fileURL = url
                isShowingPicker = true // Show the picker after download
            }

        } catch {
            isLoadingDownloadButton = false

            errorAlertTitle = String(localized: "error_downloading_failed_delivery")
            errorAlertMessage = error.localizedDescription
            activeAlert = .error
            showAlert = true
        }
    }
}
