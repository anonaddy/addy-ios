//
//  AddRecipientBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 12/05/2024.
//

import SwiftUI

import addy_shared
import AVFoundation
import SwiftUI

struct AddRecipientBottomSheet: View {
    @State var address: String = ""
    @State var addressPlaceHolder: String = .init(localized: "address")
    let onAdded: () -> Void

    init(onAdded: @escaping () -> Void) {
        self.onAdded = onAdded
    }

    @State private var recipientValidationError: String?
    @State private var recipientRequestError: String?

    @State var IsLoadingAddButton: Bool = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        #if DEBUG
            let _ = Self._printChanges()
        #endif

        Form {
            Section {
                ValidatingTextField(value: self.$address, placeholder: self.$addressPlaceHolder, fieldType: .email, error: $recipientValidationError)

            } header: {
                VStack(alignment: .leading) {
                    let formattedString = String.localizedStringWithFormat(NSLocalizedString("add_recipient_desc", comment: ""))
                    Text(LocalizedStringKey(formattedString))
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                }.frame(maxWidth: .infinity, alignment: .center)
            } footer: {
                if let error = recipientRequestError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.system(size: 15))
                        .multilineTextAlignment(.leading)
                        .padding([.horizontal], 0)
                        .onAppear {
                            HapticHelper.playHapticFeedback(hapticType: .error)
                        }
                }

            }.textCase(nil)

        }.navigationTitle(String(localized: "add_recipient")).pickerStyle(.navigationLink)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .confirmationAction) {
                    if #available(iOS 26.0, *) {
                        saveButton().buttonStyle(.glassProminent)
                    } else {
                        saveButton()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Label(String(localized: "cancel", bundle: Bundle(for: SharedData.self)), systemImage: "xmark")
                    }
                }
            })
    }

    private func saveButton() -> some View {
        Group {
            if IsLoadingAddButton {
                AnyView(ProgressView().progressViewStyle(.circular))
            } else {
                AnyView(
                    Button {
                        // Since the ValidatingTextField is also handling validationErrors (and resetting these errors on every change)
                        // We should not allow any saving until the validationErrors are nil
                        if recipientValidationError == nil {
                            IsLoadingAddButton = true

                            Task {
                                await self.addRecipientToAccount(address: self.address)
                            }
                        } else {
                            IsLoadingAddButton = false
                        }
                    } label: {
                        Text(String(localized: "add"))
                    }
                )
            }
        }
    }

    private func addRecipientToAccount(address: String) async {
        recipientRequestError = nil
        let networkHelper = NetworkHelper()
        do {
            _ = try await networkHelper.addRecipient(address: address)
            onAdded()
        } catch {
            IsLoadingAddButton = false
            recipientRequestError = error.localizedDescription
        }
    }
}

#Preview {
    AddRecipientBottomSheet {
        // Dummy function for preview
    }
}
