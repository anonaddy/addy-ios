//
//  EditDomainDescriptionBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 03/06/2024.
//

import addy_shared
import AVFoundation
import SwiftUI

struct EditDomainDescriptionBottomSheet: View {
    @Environment(\.dismiss) var dismiss

    @State private var description: String
    @State private var descriptionPlaceholder: String = .init(localized: "description")
    @State private var descriptionValidationError: String?
    @State private var descriptionRequestError: String?
    @State var IsLoadingSaveButton: Bool = false

    let domainId: String
    let descriptionEdited: (Domains) -> Void

    var body: some View {
        #if DEBUG
            let _ = Self._printChanges()
        #endif
        Form {
            Section {
                ValidatingTextField(value: self.$description, placeholder: self.$descriptionPlaceholder, fieldType: .bigText, error: $descriptionValidationError)

            } header: {
                VStack {
                    Text(String(localized: "edit_desc_domain_desc"))
                        .multilineTextAlignment(.center)
                        .padding(.bottom)

                }.frame(maxWidth: .infinity, alignment: .center)
            } footer: {
                if let error = descriptionRequestError {
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

        }.navigationTitle(String(localized: "edit_description")).pickerStyle(.navigationLink)
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
            if IsLoadingSaveButton {
                AnyView(ProgressView().progressViewStyle(.circular))
            } else {
                AnyView(
                    Button {
                        // Since the ValidatingTextField is also handling validationErrors (and resetting these errors on every change)
                        // We should not allow any saving until the validationErrors are nil
                        if descriptionValidationError == nil {
                            IsLoadingSaveButton = true

                            Task {
                                await self.editDescription(description: self.description)
                            }
                        } else {
                            IsLoadingSaveButton = false
                        }
                    } label: {
                        Text(String(localized: "save"))
                    }
                )
            }
        }
    }

    init(domainId: String, description: String, descriptionEdited: @escaping (Domains) -> Void) {
        self.domainId = domainId
        self.description = description
        self.descriptionEdited = descriptionEdited
    }

    private func editDescription(description: String?) async {
        descriptionRequestError = nil
        let networkHelper = NetworkHelper()
        do {
            if let domain = try await networkHelper.updateDescriptionSpecificDomain(domainId: domainId, description: description) {
                descriptionEdited(domain)
            }
        } catch {
            IsLoadingSaveButton = false
            descriptionRequestError = error.localizedDescription
        }
    }
}

#Preview {
    EditDomainDescriptionBottomSheet(domainId: "000", description: "TEST", descriptionEdited: { _ in
        // Dummy function for preview
    })
}
