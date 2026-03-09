//
//  AddBlocklistEntryBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 09/03/2026.
//


import SwiftUI
import addy_shared

struct AddBlocklistEntryBottomSheet: View {
    // 1. Added state for type selection
    @State var blocklistType: String = "email"
    @State var blocklistEntry: String = ""
    @State var blocklistEntryPlaceHolder: String = .init(localized: "blocklist_add_hint")
    let onAdded: () -> Void

    init(onAdded: @escaping () -> Void) {
        self.onAdded = onAdded
    }

    @State private var blocklistEntryValidationError: String?
    @State private var blocklistEntryRequestError: String?

    @State var IsLoadingAddButton: Bool = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        #if DEBUG
            let _ = Self._printChanges()
        #endif
        Form {
            Section {
                // 2. Added the Picker for Type
                Picker(String(localized: "type"), selection: $blocklistType) {
                    Text(String(localized: "email")).tag("email")
                    Text(String(localized: "domain")).tag("domain")
                }
                .onChange(of: blocklistType) {
                    // Reset errors when changing type
                    blocklistEntryValidationError = nil
                    blocklistEntryRequestError = nil
                }

                ValidatingTextField(value: self.$blocklistEntry,
                                   placeholder: self.$blocklistEntryPlaceHolder,
                                   fieldType: blocklistType == "email" ? .email : .domain,
                                   error: $blocklistEntryValidationError)

            } header: {
                VStack {
                    Text(String(localized: "blocklist_add_desc"))
                        .multilineTextAlignment(.center)
                        .padding(.bottom)

                }.frame(maxWidth: .infinity, alignment: .center)
            } footer: {
                if let error = blocklistEntryRequestError {
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
        .navigationTitle(String(localized: "blocklist_add"))
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
                        if blocklistEntryValidationError == nil && !blocklistEntry.isEmpty {
                            IsLoadingAddButton = true

                            // 3. Construct the NewBlocklistEntry object using current state
                            let entry = NewBlocklistEntry(type: self.blocklistType, value: self.blocklistEntry)
                            
                            Task {
                                await self.addblocklistEntryToAccount(blocklistEntry: entry)
                            }
                        } else {
                            // Trigger haptic if user tries to save while empty/invalid
                            HapticHelper.playHapticFeedback(hapticType: .error)
                            IsLoadingAddButton = false
                        }
                    } label: {
                        Text(String(localized: "add"))
                    }
                )
            }
        }
    }

    private func addblocklistEntryToAccount(blocklistEntry: NewBlocklistEntry) async {
        blocklistEntryRequestError = nil
        let networkHelper = NetworkHelper()
        do {
            _ = try await networkHelper.addBlocklistEntry(entry: blocklistEntry)
            onAdded()
            dismiss() // Close the sheet on success
        } catch {
            IsLoadingAddButton = false
            blocklistEntryRequestError = error.localizedDescription
        }
    }
}
#Preview {
    AddBlocklistEntryBottomSheet() {
        // Dummy function for preview
    }
}
