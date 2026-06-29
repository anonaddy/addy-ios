//
//  EditAliasLabelsBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 24/06/2026.
//

import addy_shared
import SwiftUI
import WrappingHStack

struct EditAliasLabelsBottomSheet: View {
    @Environment(\.dismiss) var dismiss

    @State private var labelsLoaded: Bool = false
    @State private var selectedLabelIds: [String]
    @State private var allLabels: [AddyChipModel] = [AddyChipModel(chipId: "loading_labels", label: String(localized: "loading_labels"))]
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
                            ChipView(label: label.label, isSelected: selectedLabelIds.contains(label.chipId), color: Color(hex: label.color ?? "FFFFFF"))
                                .onTapGesture {
                                    withAnimation {
                                        if selectedLabelIds.contains(label.chipId) {
                                            selectedLabelIds.removeAll { $0 == label.chipId }
                                        } else {
                                            selectedLabelIds.append(label.chipId)
                                        }
                                    }
                                }
                        }
                    }
                }
            } header: {
                VStack(alignment: .leading) {
                    Text(String(localized: "add_label_description"))
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
        .navigationTitle(String(localized: "labels"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if #available(iOS 26.0, *) {
                        saveButton().buttonStyle(.glassProminent)
                    } else {
                        saveButton()
                    }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Label(String(localized: "cancel", bundle: Bundle(for: SharedData.self)), systemImage: "xmark")
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    isPresentingAddLabelBottomSheet = true
                } label: {
                    Label(String(localized: "add_label"), systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingAddLabelBottomSheet) {
            NavigationStack {
                AddLabelBottomSheet { newLabel in
                    if let newLabel = newLabel {
                        let chip = AddyChipModel(chipId: newLabel.id, label: newLabel.name, color: newLabel.colour)
                        allLabels.append(chip)
                        if !selectedLabelIds.contains(chip.chipId) {
                            selectedLabelIds.append(chip.chipId)
                        }
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

    init(aliasId: String, selectedLabelsIds: [String], labelsEdited: @escaping (Aliases) -> Void) {
        self.aliasId = aliasId
        _selectedLabelIds = State(initialValue: selectedLabelsIds)
        self.labelsEdited = labelsEdited
    }

    private func getAllLabels(forceReload: Bool = false) async {
        if !labelsLoaded || forceReload {
            let networkHelper = NetworkHelper()
            do {
                if let labels = try await networkHelper.getLabels()?.data {
                    self.allLabels = []
                    for label in labels {
                        self.allLabels.append(AddyChipModel(chipId: label.id, label: label.name, color: label.colour))
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
            _ = try await networkHelper.updateAliasLabels(aliasIds: [aliasId], labelIds: selectedLabelIds)
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
