//
//  EditAliasLabelsBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 24/06/2026.
//

import addy_shared
import SwiftUI

struct EditAliasLabelsBottomSheet: View {
    @Environment(\.dismiss) var dismiss

    @State private var labelsLoaded: Bool = false
    @State private var selectedChips: [String] = []
    @State private var allLabels: [Labels] = []
    @State private var requestError: String? = ""
    @State private var isLoadingSaveButton: Bool = false
    @State private var isPresentingAddLabelBottomSheet = false

    let aliasId: String
    let labelsEdited: (Aliases) -> Void

    var body: some View {
        Form {
            Section {
                if !labelsLoaded {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    WrappingHStack(alignment: .leading, horizontalSpacing: 4, verticalSpacing: 4) {
                        ForEach(allLabels) { label in
                            ChipView(label: label.name, isSelected: selectedChips.contains(label.id), color: Color(hex: label.colour))
                                .onTapGesture {
                                    withAnimation {
                                        if selectedChips.contains(label.id) {
                                            selectedChips.removeAll { $0 == label.id }
                                        } else {
                                            selectedChips.append(label.id)
                                        }
                                    }
                                }
                        }
                    }
                }
            } header: {
                VStack(alignment: .leading) {
                    Text(String(localized: "alias_edit_labels_desc"))
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                }.frame(maxWidth: .infinity, alignment: .center)
            } footer: {
                if let error = requestError, !error.isEmpty {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.system(size: 15))
                        .multilineTextAlignment(.leading)
                        .padding([.horizontal], 0)
                        .onAppear {
                            HapticHelper.playHapticFeedback(hapticType: .error)
                        }
                }
            }
            .textCase(nil)
            .listRowInsets(EdgeInsets())
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .navigationTitle(String(localized: "edit_labels"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                saveButton()
            }
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Label(String(localized: "cancel", bundle: Bundle(for: SharedData.self)), systemImage: "xmark")
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    isPresentingAddLabelBottomSheet = true
                } label: {
                    Label(String(localized: "create_label"), systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingAddLabelBottomSheet) {
            NavigationStack {
                AddLabelBottomSheet {
                    Task {
                        await getAllLabels(forceReload: true)
                    }
                    isPresentingAddLabelBottomSheet = false
                }
            }
            .presentationDetents([.medium, .large])
        }
        .task {
            await getAllLabels()
        }
    }

    private func saveButton() -> some View {
        Group {
            if isLoadingSaveButton {
                ProgressView().progressViewStyle(.circular)
            } else {
                Button {
                    isLoadingSaveButton = true
                    Task {
                        await self.editLabels()
                    }
                } label: {
                    Text(String(localized: "save"))
                }
                .disabled(!labelsLoaded)
            }
        }
    }

    init(aliasId: String, selectedLabelsIds: [String]?, labelsEdited: @escaping (Aliases) -> Void) {
        self.aliasId = aliasId
        _selectedChips = State(initialValue: selectedLabelsIds ?? [])
        self.labelsEdited = labelsEdited
    }

    private func getAllLabels(forceReload: Bool = false) async {
        if !labelsLoaded || forceReload {
            let networkHelper = NetworkHelper()
            do {
                if let labels = try await networkHelper.getLabels() {
                    withAnimation {
                        self.allLabels = labels.data
                    }
                    labelsLoaded = true
                }
            } catch {
                requestError = error.localizedDescription
            }
        }
    }

    private func editLabels() async {
        requestError = nil
        let networkHelper = NetworkHelper()
        do {
            _ = try await networkHelper.updateAliasLabels(aliasIds: [aliasId], labelIds: selectedChips)
            if let alias = try await networkHelper.getSpecificAlias(aliasId: aliasId) {
                labelsEdited(alias)
                dismiss()
            }
        } catch {
            isLoadingSaveButton = false
            requestError = error.localizedDescription
        }
    }
}
