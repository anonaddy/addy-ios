//
//  AliasMultipleSelectionBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 29/08/2026.
//

import addy_shared
import SwiftUI
import WrappingHStack

struct AliasMultipleSelectionBottomSheet: View {
    @Environment(\.dismiss) var dismiss

    let onDataChanged: () -> Void
    let onDismissAndClear: () -> Void

    @State private var aliasesList: [Aliases]

    @State private var isActive: Bool = false
    @State private var isPinned: Bool = false
    @State private var isWatched: Bool = false

    @State private var isLoading: Bool = false
    @State private var requestError: String? = nil

    @State private var isPresentingLabelsSheet: Bool = false
    @State private var isPresentingRecipientsSheet: Bool = false

    @State private var showAlert: Bool = false
    @State private var activeAlert: BulkAlert = .delete

    enum BulkAlert {
        case delete, restore, forget
    }

    private var aliasIds: [String] {
        aliasesList.map(\.id)
    }

    private var hasDeletedAliases: Bool {
        aliasesList.contains { $0.deleted_at != nil }
    }

    private var hasActiveAliases: Bool {
        aliasesList.contains { $0.deleted_at == nil }
    }

    private var allDeleted: Bool {
        !aliasesList.isEmpty && aliasesList.allSatisfy { $0.deleted_at != nil }
    }

    init(
        selectedAliases: [Aliases],
        onDataChanged: @escaping () -> Void,
        onDismissAndClear: @escaping () -> Void
    ) {
        self.onDataChanged = onDataChanged
        self.onDismissAndClear = onDismissAndClear

        _aliasesList = State(initialValue: selectedAliases)

        // Calculate initial uniform states
        let nonDeleted = selectedAliases.filter { $0.deleted_at == nil }
        let allActive = !nonDeleted.isEmpty && nonDeleted.allSatisfy { $0.active }
        let allPinned = !selectedAliases.isEmpty && selectedAliases.allSatisfy { $0.pinned }
        let watchedList = AliasWatcher().getAliasesToWatch()
        let allWatched = !selectedAliases.isEmpty && selectedAliases.allSatisfy { watchedList.contains($0.id) }

        _isActive = State(initialValue: allActive)
        _isPinned = State(initialValue: allPinned)
        _isWatched = State(initialValue: allWatched)
    }

    var body: some View {
        Form {
            Section {
                // Active toggle (disabled if all aliases are deleted)
                Toggle(isOn: $isActive) {
                    Label(String(localized: "alias_status_active"), systemImage: "power")
                }
                .disabled(allDeleted || isLoading)
                .onChange(of: isActive) { newValue in
                    Task {
                        await toggleActive(active: newValue)
                    }
                }

                // Watched toggle
                Toggle(isOn: $isWatched) {
                    Label {
                        Text(String(localized: "watch_alias"))
                    } icon: {
                        Image("ic_watch_alias")
                            .renderingMode(.template)
                    }
                }
                .disabled(isLoading)
                .onChange(of: isWatched) { newValue in
                    toggleWatched(watched: newValue)
                }

                // Pinned toggle
                Toggle(isOn: $isPinned) {
                    Label(String(localized: "pin_alias", bundle: Bundle(for: SharedData.self)), systemImage: "pin.fill")
                }
                .disabled(isLoading)
                .onChange(of: isPinned) { newValue in
                    Task {
                        await togglePinned(pinned: newValue)
                    }
                }

                // Labels action
                Button {
                    isPresentingLabelsSheet = true
                } label: {
                    HStack {
                        Label(String(localized: "labels"), systemImage: "tag.fill")
                            .tint(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                .disabled(isLoading)

                // Recipients action
                Button {
                    isPresentingRecipientsSheet = true
                } label: {
                    HStack {
                        Label(String(localized: "recipients"), systemImage: "person.2.fill")
                            .tint(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                .disabled(isLoading)

                // Restore action
                if hasDeletedAliases {
                    Button {
                        activeAlert = .restore
                        showAlert = true
                    } label: {
                        Label(String(localized: "restore_alias"), systemImage: "arrow.counterclockwise")
                            .foregroundColor(.blue)
                    }
                    .disabled(isLoading)
                }

                // Delete action
                if hasActiveAliases {
                    Button(role: .destructive) {
                        activeAlert = .delete
                        showAlert = true
                    } label: {
                        Label(String(localized: "delete_alias"), systemImage: "trash")
                            .foregroundColor(.red)
                    }
                    .disabled(isLoading)
                }

                // Forget action (available for all selected aliases)
                Button(role: .destructive) {
                    activeAlert = .forget
                    showAlert = true
                } label: {
                    Label(String(localized: "forget_alias"), systemImage: "trash.fill")
                        .foregroundColor(.red)
                }
                .disabled(isLoading)
            } header: {
                Text(String(localized: "general"))
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    Text(String(localized: "multiple_alias_selected_desc"))
                    if let error = requestError, !error.isEmpty {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
        }
        .navigationTitle(String.localizedStringWithFormat(NSLocalizedString("multiple_alias_selected", comment: ""), aliasesList.count))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Label(String(localized: "close"), systemImage: "xmark")
                }
            }
        }
        .overlay {
            if isLoading {
                ProgressView()
                    .padding()
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(12)
            }
        }
        .sheet(isPresented: $isPresentingLabelsSheet) {
            NavigationStack {
                BulkEditLabelsSheet(aliasIds: aliasIds) {
                    onDataChanged()
                }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $isPresentingRecipientsSheet) {
            NavigationStack {
                BulkEditRecipientsSheet(aliasIds: aliasIds) {
                    onDataChanged()
                }
            }
            .presentationDetents([.medium, .large])
        }
        .alert(isPresented: $showAlert) {
            switch activeAlert {
            case .delete:
                return Alert(
                    title: Text(String(localized: "delete_alias")),
                    message: Text(String(localized: "delete_alias_confirmation_desc")),
                    primaryButton: .destructive(Text(String(localized: "delete"))) {
                        Task {
                            await deleteSelected()
                        }
                    },
                    secondaryButton: .cancel(Text(String(localized: "cancel", bundle: Bundle(for: SharedData.self))))
                )
            case .restore:
                return Alert(
                    title: Text(String(localized: "restore_alias")),
                    message: Text(String(localized: "restore_alias_confirmation_desc")),
                    primaryButton: .default(Text(String(localized: "restore"))) {
                        Task {
                            await restoreSelected()
                        }
                    },
                    secondaryButton: .cancel(Text(String(localized: "cancel", bundle: Bundle(for: SharedData.self))))
                )
            case .forget:
                return Alert(
                    title: Text(String(localized: "forget_alias")),
                    message: Text(String(localized: "forget_alias_confirmation_desc")),
                    primaryButton: .destructive(Text(String(localized: "forget"))) {
                        Task {
                            await forgetSelected()
                        }
                    },
                    secondaryButton: .cancel(Text(String(localized: "cancel", bundle: Bundle(for: SharedData.self))))
                )
            }
        }
    }

    private func toggleActive(active: Bool) async {
        isLoading = true
        requestError = nil
        do {
            if active {
                _ = try await AliasRepository.shared.bulkActivateAliases(aliasIds: aliasIds)
            } else {
                _ = try await AliasRepository.shared.bulkDeactivateAliases(aliasIds: aliasIds)
            }
            // Update local state without dismissing
            aliasesList = aliasesList.map { alias in
                var copy = alias
                if copy.deleted_at == nil {
                    copy.active = active
                }
                return copy
            }
            isLoading = false
            onDataChanged()
        } catch {
            isLoading = false
            requestError = error.localizedDescription
            HapticHelper.playHapticFeedback(hapticType: .error)
        }
    }

    private func togglePinned(pinned: Bool) async {
        isLoading = true
        requestError = nil
        do {
            if pinned {
                _ = try await AliasRepository.shared.bulkPinAliases(aliasIds: aliasIds)
            } else {
                _ = try await AliasRepository.shared.bulkUnpinAliases(aliasIds: aliasIds)
            }
            // Update local state without dismissing
            aliasesList = aliasesList.map { alias in
                var copy = alias
                copy.pinned = pinned
                return copy
            }
            isLoading = false
            onDataChanged()
        } catch {
            isLoading = false
            requestError = error.localizedDescription
            HapticHelper.playHapticFeedback(hapticType: .error)
        }
    }

    private func toggleWatched(watched: Bool) {
        let watcher = AliasWatcher()
        for alias in aliasesList {
            if watched {
                _ = watcher.addAliasToWatch(alias: alias.id)
            } else {
                watcher.removeAliasToWatch(alias: alias.id)
            }
        }
        onDataChanged()
    }

    private func deleteSelected() async {
        isLoading = true
        requestError = nil
        do {
            let activeIds = aliasesList.filter { $0.deleted_at == nil }.map(\.id)
            _ = try await AliasRepository.shared.bulkDeleteAliases(aliasIds: activeIds)
            isLoading = false
            onDismissAndClear()
            dismiss()
        } catch {
            isLoading = false
            requestError = error.localizedDescription
            HapticHelper.playHapticFeedback(hapticType: .error)
        }
    }

    private func restoreSelected() async {
        isLoading = true
        requestError = nil
        do {
            let deletedIds = aliasesList.filter { $0.deleted_at != nil }.map(\.id)
            _ = try await AliasRepository.shared.bulkRestoreAliases(aliasIds: deletedIds)
            isLoading = false
            onDismissAndClear()
            dismiss()
        } catch {
            isLoading = false
            requestError = error.localizedDescription
            HapticHelper.playHapticFeedback(hapticType: .error)
        }
    }

    private func forgetSelected() async {
        isLoading = true
        requestError = nil
        do {
            _ = try await AliasRepository.shared.bulkForgetAliases(aliasIds: aliasIds)
            isLoading = false
            onDismissAndClear()
            dismiss()
        } catch {
            isLoading = false
            requestError = error.localizedDescription
            HapticHelper.playHapticFeedback(hapticType: .error)
        }
    }
}

// MARK: - Bulk Edit Labels Sheet Helper
private struct BulkEditLabelsSheet: View {
    @Environment(\.dismiss) var dismiss
    let aliasIds: [String]
    let onSaved: () -> Void

    @State private var labelsLoaded: Bool = false
    @State private var selectedLabelIds: [String] = []
    @State private var allLabels: [AddyChipModel] = []
    @State private var requestError: String? = nil
    @State private var isLoadingSaveButton: Bool = false

    var body: some View {
        Form {
            Section {
                if !labelsLoaded {
                    ProgressView().frame(maxWidth: .infinity, alignment: .center)
                } else {
                    AddyMultiSelectChipView(chips: $allLabels, selectedChips: $selectedLabelIds, singleLine: false) { chip in
                        withAnimation {
                            if let idx = selectedLabelIds.firstIndex(of: chip.chipId) {
                                selectedLabelIds.remove(at: idx)
                            } else {
                                selectedLabelIds.append(chip.chipId)
                            }
                        }
                    }
                }
            } header: {
                Text(String(localized: "add_label_description"))
            } footer: {
                if let error = requestError, !error.isEmpty {
                    Text(error).foregroundColor(.red).font(.caption)
                }
            }
        }
        .navigationTitle(String(localized: "labels"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(String(localized: "save")) {
                    saveLabels()
                }
                .disabled(isLoadingSaveButton)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button(String(localized: "cancel", bundle: Bundle(for: SharedData.self))) {
                    dismiss()
                }
            }
        }
        .task {
            await loadLabels()
        }
    }

    private func loadLabels() async {
        do {
            let labelsArray = try await LabelRepository.shared.getLabels()
            allLabels = labelsArray.data.map { AddyChipModel(chipId: $0.id, label: $0.name, color: $0.colour) }
            labelsLoaded = true
        } catch {
            labelsLoaded = true
            requestError = error.localizedDescription
        }
    }

    private func saveLabels() {
        isLoadingSaveButton = true
        requestError = nil
        Task {
            do {
                _ = try await AliasRepository.shared.bulkUpdateLabels(aliasIds: aliasIds, labelIds: selectedLabelIds)
                onSaved()
                dismiss()
            } catch {
                isLoadingSaveButton = false
                requestError = error.localizedDescription
            }
        }
    }
}

// MARK: - Bulk Edit Recipients Sheet Helper
private struct BulkEditRecipientsSheet: View {
    @Environment(\.dismiss) var dismiss
    let aliasIds: [String]
    let onSaved: () -> Void

    @State private var recipientsLoaded: Bool = false
    @State private var selectedRecipientIds: [String] = []
    @State private var allRecipients: [AddyChipModel] = []
    @State private var requestError: String? = nil
    @State private var isLoadingSaveButton: Bool = false

    var body: some View {
        Form {
            Section {
                if !recipientsLoaded {
                    ProgressView().frame(maxWidth: .infinity, alignment: .center)
                } else {
                    AddyMultiSelectChipView(chips: $allRecipients, selectedChips: $selectedRecipientIds, singleLine: false) { chip in
                        withAnimation {
                            if let idx = selectedRecipientIds.firstIndex(of: chip.chipId) {
                                selectedRecipientIds.remove(at: idx)
                            } else {
                                selectedRecipientIds.append(chip.chipId)
                            }
                        }
                    }
                }
            } header: {
                Text(String(localized: "select_recipients_for_this_alias"))
            } footer: {
                if let error = requestError, !error.isEmpty {
                    Text(error).foregroundColor(.red).font(.caption)
                }
            }
        }
        .navigationTitle(String(localized: "recipients"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(String(localized: "save")) {
                    saveRecipients()
                }
                .disabled(isLoadingSaveButton)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button(String(localized: "cancel", bundle: Bundle(for: SharedData.self))) {
                    dismiss()
                }
            }
        }
        .task {
            await loadRecipients()
        }
    }

    private func loadRecipients() async {
        do {
            let recipients = try await RecipientRepository.shared.getRecipients(verifiedOnly: true)
            allRecipients = recipients.map { AddyChipModel(chipId: $0.id, label: $0.email) }
            recipientsLoaded = true
        } catch {
            recipientsLoaded = true
            requestError = error.localizedDescription
        }
    }

    private func saveRecipients() {
        isLoadingSaveButton = true
        requestError = nil
        Task {
            do {
                _ = try await AliasRepository.shared.bulkUpdateRecipients(aliasIds: aliasIds, recipientIds: selectedRecipientIds)
                onSaved()
                dismiss()
            } catch {
                isLoadingSaveButton = false
                requestError = error.localizedDescription
            }
        }
    }
}
