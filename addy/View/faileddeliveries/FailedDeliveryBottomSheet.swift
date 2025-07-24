//
//  FailedDeliveryBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 03/06/2024.
//

import SwiftUI
import AVFoundation
import addy_shared

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
        
        let addyLoadingButtonDeleteStyle = AddyLoadingButtonStyle(width: .infinity,
                                                                  height: 56,
                                                                  cornerRadius: 12,
                                                                  backgroundColor: Color.softRed,
                                                                  loadingColor: Color.accentColor.opacity(0.4),
                                                                  strokeWidth: 5,
                                                                  strokeColor: .gray)
        
        Form{
            
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
            
            Section {
            
                AddyLoadingButton(action: {
                    
                    activeAlert = .resend
                    showAlert = true
                    
                }, isLoading: $isLoadingResendButton) {
                    Text(String(localized: "resend_failed_delivery")).foregroundColor(Color.white)
                    
                }.frame(minHeight: 56).padding(.bottom)
                
                
                if (self.failedDelivery.is_stored){
                    AddyLoadingButton(action: {
                        
                        isLoadingDownloadButton = true;
                        
                        Task {
                            await self.downloadFailedDelivery()
                        }
                        
                    }, isLoading: $isLoadingDownloadButton) {
                        Text(String(localized: "download_failed_delivery")).foregroundColor(Color.white)
                        
                    }.frame(minHeight: 56).padding(.bottom)
                }
                
                AddyLoadingButton(action: {
                    
                    isLoadingDeleteButton = true;
                    
                    Task {
                        await self.deleteFailedDelivery()
                    }
                    
                }, isLoading: $isLoadingDeleteButton, style: addyLoadingButtonDeleteStyle) {
                    Text(String(localized: "delete_failed_delivery")).foregroundColor(Color.white)
                    
                }.frame(minHeight: 56)
                
                
            }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())
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
            ToolbarItem() {
                Button {
                    dismiss()
                } label: {
                    Label(String(localized: "dismiss"), systemImage: "xmark.circle.fill")
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
                return Alert(title: Text(String(localized: "resend_failed_delivery")), message: Text(String(localized: "resend_failed_delivery_confirmation_desc")), primaryButton: .default(Text(String(localized: "resend"))){
                    
                    Task {
                        await self.resendFailedDelivery()
                    }
                }, secondaryButton: .cancel(){
                    isLoadingResendButton = false
                })
            }
        }
        
        
    }
    
    
    private func deleteFailedDelivery() async {
        let networkHelper = NetworkHelper()
        do {
            let result = try await networkHelper.deleteFailedDelivery(failedDeliveryId: self.failedDelivery.id)
            self.isLoadingDeleteButton = false
            if result == "204" {
                self.onDeleted()
            } else {
                isLoadingDeleteButton = false
                errorAlertTitle = String(localized: "error_deleting_failed_delivery")
                errorAlertMessage = result
                activeAlert = .error
                showAlert = true            }
        } catch {
            self.isLoadingDeleteButton = false
            errorAlertTitle = String(localized: "error_deleting_failed_delivery")
            errorAlertMessage = error.localizedDescription
            activeAlert = .error
            showAlert = true        }
    }
    
    private func resendFailedDelivery() async {
        let networkHelper = NetworkHelper()
        do {
            let result = try await networkHelper.resendFailedDelivery(failedDeliveryId: self.failedDelivery.id)
            self.isLoadingResendButton = false
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
                showAlert = true            }
        } catch {
            self.isLoadingResendButton = false
            errorAlertTitle = String(localized: "error_resending_failed_delivery")
            errorAlertMessage = error.localizedDescription
            activeAlert = .error
            showAlert = true        }
    }
    
    private func downloadFailedDelivery() async {
        let networkHelper = NetworkHelper()
        do {
            // Assuming 'downloadFailedDelivery' returns an optional URL
            let fileURL: URL? = try await networkHelper.downloadFailedDelivery(failedDeliveryId: self.failedDelivery.id)
            self.isLoadingDownloadButton = false
            
            if let url = fileURL {
                self.fileURL = url
                self.isShowingPicker = true // Show the picker after download
                
            }
            
        } catch {
            self.isLoadingDownloadButton = false
            
            errorAlertTitle = String(localized: "error_downloading_failed_delivery")
            errorAlertMessage = error.localizedDescription
            activeAlert = .error
            showAlert = true
            
        }
    }
    
    
}
