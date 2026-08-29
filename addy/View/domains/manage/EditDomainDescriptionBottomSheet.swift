//
//  EditDomainDescriptionBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 03/06/2024.
//

import addy_shared
import SwiftUI

struct EditDomainDescriptionBottomSheet: View {
    @Environment(\.dismiss) var dismiss

    @State private var description: String
    @State private var descriptionValidationError: String?
    @State private var descriptionRequestError: String?
    @State var isLoadingSaveButton: Bool = false

    let domainId: String
    let descriptionEdited: (Domains) -> Void

    init(domainId: String, description: String, descriptionEdited: @escaping (Domains) -> Void) {
        self.domainId = domainId
        self._description = State(initialValue: description)
        self.descriptionEdited = descriptionEdited
    }

    var body: some View {
        #if DEBUG
            let _ = Self._printChanges()
        #endif
        Form {
            Section {
                ValidatingTextField(value: self.$description, placeholder: String(localized: "description"), fieldType: .bigText, error: $descriptionValidationError)

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

        }
        .navigationTitle(String(localized: "edit_description"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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
        }
    }

    private func saveButton() -> some View {
        Group {
            if isLoadingSaveButton {
                ProgressView().progressViewStyle(.circular)
            } else {
                Button {
                    // Since the ValidatingTextField is also handling validationErrors (and resetting these errors on every change)
                    // We should not allow any saving until the validationErrors are nil
                    if descriptionValidationError == nil {
                        isLoadingSaveButton = true

                        Task {
                            await self.editDescription(description: self.description)
                        }
                    } else {
                        isLoadingSaveButton = false
                    }
                } label: {
                    Text(String(localized: "save"))
                }
            }
        }
    }

    private func editDescription(description: String?) async {
        descriptionRequestError = nil
        do {
            let domain = try await DomainRepository.shared.updateDescription(domainId: domainId, description: description)
            descriptionEdited(domain)
        } catch {
            isLoadingSaveButton = false
            descriptionRequestError = error.localizedDescription
        }
    }
}

#Preview {
    EditDomainDescriptionBottomSheet(domainId: "000", description: "TEST", descriptionEdited: { _ in
        // Dummy function for preview
    })
}
