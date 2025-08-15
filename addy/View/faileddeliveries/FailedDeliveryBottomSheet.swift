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

    let onDeleted: () -> Void

    init(failedDelivery: FailedDeliveries, onDeleted: @escaping () -> Void) {
        self.failedDelivery = failedDelivery
        self.onDeleted = onDeleted
    }

    @State var isLoadingDeleteButton: Bool = false
    @State var isLoadingDownloadButton: Bool = false
    @State var isLoadingResendButton: Bool = false
    @State private var isShowingPicker = false
    @State private var fileURL: URL?

    enum ActiveAlert {
        case error
        case resend
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
                                                                       failedDelivery.attempted_at,
                                                                       failedDelivery.alias_email ?? "",
                                                                       failedDelivery.recipient_email ?? "",
                                                                       failedDelivery.bounce_type,
                                                                       failedDelivery.remote_mta,
                                                                       failedDelivery.sender ?? "",
                                                                       failedDelivery.code)
                Text(LocalizedStringKey(formattedString))
                    .multilineTextAlignment(.leading)
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

            if self.failedDelivery.is_stored {
                ToolbarItem(placement: .bottomBar) {
                    downloadFailedDeliveryButton()
                }
            }

            if #available(iOS 26.0, *) {
                ToolbarSpacer(.flexible)
            }

            ToolbarItem(placement: .bottomBar) {
                resendFailedDeliveryButton()
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
