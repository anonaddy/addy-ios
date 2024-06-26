//
//  FailedDeliveryBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 03/06/2024.
//

import SwiftUI
import AVFoundation
import CodeScanner
import addy_shared

struct FailedDeliveryBottomSheet: View {
    @State var failedDelivery: FailedDeliveries

    let onDeleted: () -> Void

    init(failedDelivery: FailedDeliveries, onDeleted: @escaping () -> Void) {
        self.failedDelivery = failedDelivery
        self.onDeleted = onDeleted
    }
    

    @State var isLoadingDeleteButton: Bool = false
    @State private var failedDeliveryRequestError:String?

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
           
            } footer: {
                if let error = failedDeliveryRequestError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.system(size: 15))
                        .multilineTextAlignment(.leading)
                        .padding([.horizontal], 0)
                        .onAppear{
                            HapticHelper.playHapticFeedback(hapticType: .error)
                        }
                }
            
            }.textCase(nil)
            
            Section {
                AddyLoadingButton(action: {

                    isLoadingDeleteButton = true;
                    
                    Task {
                        await self.deleteFailedDelivery()
                    }
                
                }, isLoading: $isLoadingDeleteButton, style: addyLoadingButtonDeleteStyle) {
                    Text(String(localized: "delete_failed_delivery")).foregroundColor(Color.white)
                }.frame(minHeight: 56)
            }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())
            
            }.navigationTitle(String(localized: "details")).pickerStyle(.navigationLink)
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
                failedDeliveryRequestError = result
            }
        } catch {
            self.isLoadingDeleteButton = false
            failedDeliveryRequestError = error.localizedDescription
        }
    }
    
}
