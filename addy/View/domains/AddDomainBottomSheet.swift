//
//  AddDomainBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 03/06/2024.
//

import addy_shared
import AVFoundation
import Combine
import SwiftUI

struct AddDomainBottomSheet: View {
    @Environment(\.dismiss) var dismiss

    @State var domain: String = ""
    @State var domainPlaceHolder: String = .init(localized: "address")
    @State private var domainValidationError: String?
    @State private var domainRequestError: String?
    @State private var valueCopiedToClipboard: Bool = false
    @State var domainVerificationStatusText: String = ""
    @State var IsLoadingAddButton: Bool = false
    @State var isWaitingForDomainVerification: Bool = false
    @State private var timer: Timer? = nil

    let onAdded: () -> Void

    var body: some View {
        #if DEBUG
            let _ = Self._printChanges()
        #endif
        Group {
            if isWaitingForDomainVerification {
                VStack {
                    Text(domainVerificationStatusText).transition(.opacity).multilineTextAlignment(.center).padding()

                    if self.valueCopiedToClipboard {
                        Text(String(localized: "verification_record_copied_to_clipboard")).transition(.opacity).multilineTextAlignment(.center).padding()
                    }

                    ProgressView()
                }.navigationTitle(String(localized: "add_domain")).pickerStyle(.navigationLink)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar(content: {
                        ToolbarItem(placement: .cancellationAction) {
                            Button {
                                dismiss()
                            } label: {
                                Label(String(localized: "cancel", bundle: Bundle(for: SharedData.self)), systemImage: "xmark")
                            }
                        }
                    })
            } else {
                VStack {
                    Form {
                        Section {
                            ValidatingTextField(value: self.$domain, placeholder: self.$domainPlaceHolder, fieldType: .domain, error: $domainValidationError)

                        } header: {
                            Text(String(localized: "add_domain_desc"))
                                .multilineTextAlignment(.center)
                                .padding(.bottom)

                        } footer: {
                            if let error = domainRequestError {
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

                    }.navigationTitle(String(localized: "add_domain")).pickerStyle(.navigationLink)
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
            }
        }.onDisappear {
            self.timer?.invalidate()
        }
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
                        if domainValidationError == nil {
                            IsLoadingAddButton = true

                            Task {
                                await self.addDomainToAccount(domain: self.domain)
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

    init(onAdded: @escaping () -> Void) {
        self.onAdded = onAdded
    }

    private func addDomainToAccount(domain: String) async {
        domainRequestError = nil
        let networkHelper = NetworkHelper()
        do {
            let (_, error, body) = try await networkHelper.addDomain(domain: domain)
            switch error {
            case "404": openSetup(body: String(body ?? ""))
            case "201": onAdded()
            default:
                IsLoadingAddButton = false
                domainRequestError = error
            }

        } catch {
            IsLoadingAddButton = false
            domainRequestError = error.localizedDescription
        }
    }

    private func openSetup(body: String) {
        // Copy the aa-verify=record
        if let range = body.range(of: "aa-verify=") {
            let result = body[range.lowerBound...]
            UIPasteboard.general.setValue(result, forPasteboardType: UTType.plainText.identifier)

            valueCopiedToClipboard = true
        } else {
            valueCopiedToClipboard = false
        }

        withAnimation(.easeInOut(duration: 0.5)) {
            self.isWaitingForDomainVerification = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                self.domainVerificationStatusText = body
            }
        }

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            Task {
                await self.addDomainToAccount(domain: self.domain)
            }
        }
    }
}

#Preview {
    AddDomainBottomSheet {
        // Dummy function for preview
    }
}
