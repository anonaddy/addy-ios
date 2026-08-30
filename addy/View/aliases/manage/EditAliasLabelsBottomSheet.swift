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

    let aliasIds: [String]
    var onSaved: (() -> Void)? = nil
    var labelsEdited: ((Aliases) -> Void)? = nil

    var body: some View {
        Form {
            Section {
                if !labelsLoaded {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if allLabels.isEmpty {
                    Text(String(localized: "no_labels"))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
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
        self.aliasIds = [aliasId]
        self._selectedLabelIds = State(initialValue: selectedLabelsIds)
        self.labelsEdited = labelsEdited
        self.onSaved = nil
    }

    init(aliasIds: [String], selectedLabelsIds: [String] = [], onSaved: @escaping () -> Void) {
        self.aliasIds = aliasIds
        self._selectedLabelIds = State(initialValue: selectedLabelsIds)
        self.onSaved = onSaved
        self.labelsEdited = nil
    }

    private func getAllLabels(forceReload: Bool = false) async {
        if !labelsLoaded || forceReload {
            do {
                let labels = try await LabelRepository.shared.getLabels().data
                self.allLabels = []
                for label in labels {
                    self.allLabels.append(AddyChipModel(chipId: label.id, label: label.name, color: label.colour))
                }
                labelsLoaded = true
            } catch {
                requestError = error.localizedDescription
            }
        }
    }

    private func editLabels() async {
        requestError = nil
        do {
            _ = try await AliasRepository.shared.bulkUpdateLabels(aliasIds: aliasIds, labelIds: selectedLabelIds)
            if aliasIds.count == 1, let aliasId = aliasIds.first, let labelsEdited = labelsEdited {
                let alias = try await AliasRepository.shared.getAlias(aliasId: aliasId)
                labelsEdited(alias)
            }
            onSaved?()
            dismiss()
        } catch {
            isLoadingSaveButton = false
            requestError = error.localizedDescription
        }
    }
}
