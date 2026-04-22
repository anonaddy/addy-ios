//
//  BlocklistView.swift
//  addy
//
//  Created by Stijn van de Water on 09/03/2026.
//

import addy_shared
import SwiftUI

struct BlocklistView: View {
    @EnvironmentObject var mainViewState: MainViewState

    @StateObject var blocklistEntriesViewModel = BlocklistEntriesViewModel()

    @State private var activeAlert: ActiveAlert = .error
    @State private var showAlert: Bool = false
    @State private var blocklistEntryToDelete: BlocklistEntries? = nil
    @State private var isPresentingAddblocklistEntryBottomSheet = false
    @State private var errorAlertTitle = ""
    @State private var errorAlertMessage = ""

    @State var selectedFilterChip: String = "all"
    @State var filterChips: [AddyChipModel] = []
    @Binding var horizontalSize: UserInterfaceSizeClass

    enum ActiveAlert {
        case error, deleteblocklistEntry
    }

    var onRefreshGeneralData: (() -> Void)? = nil

    var body: some View {
        #if DEBUG
            let _ = Self._printChanges()
        #endif

        // Prevent having a navstack inside a navstack when the view is openen on a compact level (inside the profilesheet)
        Group {
            if horizontalSize == .regular {
                NavigationStack {
                    blocklistEntriesViewBody
                }
            } else {
                blocklistEntriesViewBody
            }
        }.onAppear(perform: {
            LoadFilter()
            if let blocklistEntries = blocklistEntriesViewModel.blocklistEntries {
                if blocklistEntries.data.isEmpty {
                    Task {
                        await blocklistEntriesViewModel.getblocklistEntries(forceReload: true)
                    }
                }
            }
        })
    }

    private var blocklistEntriesViewBody: some View {
        List {
            if let blocklistEntries = blocklistEntriesViewModel.blocklistEntries {
                Section {
                    ForEach(blocklistEntries.data) { blocklistEntry in
                            HStack(alignment: .center, spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    // Main Value (Email/Domain)
                                    Text(blocklistEntry.value)
                                        .font(.body) // Native list font size
                                        .fontWeight(.medium)
                                        .lineLimit(1)
                                        .truncationMode(.tail)

                                    // Sub-information Row
                                    HStack(spacing: 6) {
                                        // Type Badge (Small, subtle)
                                        Text(blocklistEntry.type.uppercased())
                                            .font(.system(size: 10, weight: .bold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.accentColor.opacity(0.1))
                                            .foregroundColor(.accentColor)
                                            .cornerRadius(4)

                                        Text("•")
                                            .font(.caption2)
                                            .foregroundColor(.secondary.opacity(0.5))

                                        // Blocked Count Section
                                        HStack(spacing: 3) {
                                            Image(systemName: "slash.circle")
                                                .font(.system(size: 10))
                                            Text("\(blocklistEntry.blocked ?? 0)")
                                                .font(.caption)

                                            if let lastBlocked = blocklistEntry.last_blocked, !lastBlocked.isEmpty {
                                                Text("(\(DateTimeUtils.convertStringToLocalTimeZoneString(lastBlocked)))")
                                                    .font(.caption)
                                            }
                                        }
                                        .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }.onDelete(perform: deleteblocklistEntry)

                        if !blocklistEntriesViewModel.hasArrivedAtTheLastPage {
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: 50)
                                .onAppear {
                                    blocklistEntriesViewModel.loadMoreContent()
                                }
                        }
                    } header: {
                        VStack(alignment: .leading, spacing: 24) {
                            if blocklistEntriesViewModel.networkError == "" {
                                AddyChipView(chips: $filterChips, selectedChip: $selectedFilterChip, singleLine: true) { onTappedChip in
                                    withAnimation {
                                        selectedFilterChip = onTappedChip.chipId
                                    }

                                    ApplyFilter(chipId: onTappedChip.chipId)
                                }.scrollClipDisabled()
                            }

                            HStack(spacing: 6) {
                                if selectedFilterChip != "all" {
                                    Text(String(localized: "blocklist_entries_filtered"))
                                } else {
                                    Text(String(localized: "blocklist_entries"))
                                }

                                if let count = blocklistEntriesViewModel.blocklistEntries?.meta?.total, count > 0 {
                                    Text("\(count)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.secondary.opacity(0.1))
                                        .clipShape(Capsule())
                                }

                                if blocklistEntriesViewModel.isLoading {
                                    ProgressView()
                                        .frame(maxHeight: 4)
                                }
                            }
                        }

                    } footer: {
                        Text(String(localized: "manage_blocklist_desc")).padding(.top)

                    }.textCase(nil)
            }

        }.refreshable {
            if horizontalSize == .regular {
                // When in regular size (tablet) mode, refreshing aliases also ask the mainView to update general data
                self.onRefreshGeneralData?()
            }
            await self.blocklistEntriesViewModel.getblocklistEntries(forceReload: true)
        }
        .sheet(isPresented: $isPresentingAddblocklistEntryBottomSheet) {
            NavigationStack {
                AddBlocklistEntryBottomSheet {
                    Task {
                        await blocklistEntriesViewModel.getblocklistEntries(forceReload: true)
                    }

                    isPresentingAddblocklistEntryBottomSheet = false
                }
            }
            .presentationDetents([.medium, .large])
        }
        .alert(isPresented: $showAlert) {
            switch activeAlert {
            case .deleteblocklistEntry:
                return Alert(title: Text(String(localized: "remove_from_blocklist")), message: Text(String(localized: "remove_from_blocklist_desc")), primaryButton: .destructive(Text(String(localized: "delete"))) {
                    Task {
                        await self.deleteblocklistEntry(blocklistEntry: self.blocklistEntryToDelete!)
                    }
                }, secondaryButton: .cancel {
                    Task {
                        await blocklistEntriesViewModel.getblocklistEntries(forceReload: true)
                    }
                })
            case .error:
                return Alert(
                    title: Text(errorAlertTitle),
                    message: Text(errorAlertMessage)
                )
            }
        }

        .overlay(Group {
            // If there is an blocklistEntries (aka, if the list is visible)
            if let blocklistEntries = blocklistEntriesViewModel.blocklistEntries {
                // If there is NO data inside the list AND the user has actually tried searching for something
                if blocklistEntries.data.isEmpty, !blocklistEntriesViewModel.searchQuery.isEmpty {
                    // Show the search unavailable screen
                    ContentUnavailableView.search(text: blocklistEntriesViewModel.searchQuery)
                    
                // If there is NO data inside the list AND the user has NOT tried searching for something
                } else if blocklistEntries.data.isEmpty, blocklistEntriesViewModel.searchQuery.isEmpty {
                    ContentUnavailableView {
                        Label(String(localized: "no_blocklist_entries"), systemImage: "nosign")
                    } description: {
                        Text(String(localized: "no_blocklist_entries_desc"))
                    }
                }
            } else {
                // If there is NO blocklistEntries (aka, if the list is not visible)
                // No blocklistEntries, check if there is an error
                if blocklistEntriesViewModel.networkError != "" {
                    if mainViewState.userResource!.hasUserFreeSubscription() {
                        // Error screen
                        ContentUnavailableView {
                            Label(String(localized: "no_blocklist_entries"), systemImage: "exclamationmark.triangle.fill")
                        } description: {
                            Text(String(localized: "feature_not_available_subscription"))
                        }
                    } else {
                        // Error screen
                        ContentUnavailableView {
                            Label(String(localized: "something_went_wrong_retrieving_blocklist_entries"), systemImage: "wifi.slash")
                        } description: {
                            Text(blocklistEntriesViewModel.networkError)
                        } actions: {
                            Button(String(localized: "try_again", bundle: Bundle(for: SharedData.self))) {
                                Task {
                                    await blocklistEntriesViewModel.getblocklistEntries(forceReload: true)
                                }
                            }
                        }
                    }
                } else {
                    // No blocklistEntries and no error. It must still be loading...
                    VStack(alignment: .center, spacing: 0) {
                        Spacer()
                        ContentUnavailableView {
                            Label(String(localized: "obtaining_blocklist_entries"), systemImage: "globe")
                        } description: {
                            Text(String(localized: "obtaining_desc", bundle: Bundle(for: SharedData.self)))
                        }

                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: 50)
                        Spacer()
                    }
                }
            }
        })
        .navigationTitle(String(localized: "blocklist"))
        .navigationBarTitleDisplayMode(horizontalSize == .regular ? .automatic : .inline)
        .toolbar {
            if horizontalSize == .regular {
                ToolbarItem(placement: .topBarLeading) {
                    ProfilePicture().environmentObject(mainViewState)
                }

                if #available(iOS 26.0, *) {
                    ToolbarSpacer(placement: .topBarLeading)
                }

                ToolbarItem(placement: .topBarLeading) {
                    FailedDeliveriesIcon(horizontalSize: $horizontalSize).environmentObject(mainViewState)
                }

                ToolbarItem(placement: .topBarLeading) {
                    AccountNotificationsIcon().environmentObject(mainViewState)
                }

                if #available(iOS 26.0, *) {
                    ToolbarSpacer(.flexible)
                }
            }

            if !mainViewState.userResource!.hasUserFreeSubscription() {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        self.isPresentingAddblocklistEntryBottomSheet = true
                    }) {
                        Image(systemName: "plus")
                            .frame(width: 24, height: 24)
                    }
                }
            }
        }
        .searchable(text: $blocklistEntriesViewModel.searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: String(localized: "search"))
        .onSubmit(of: .search) {
            Task {
                await blocklistEntriesViewModel.searchblocklistEntries(searchQuery: blocklistEntriesViewModel.searchQuery)
            }
        }
        .autocorrectionDisabled(true)
        .textInputAutocapitalization(.never)
    }

    func ApplyFilter(chipId: String) {
        switch chipId {
        case "email":
            blocklistEntriesViewModel.filter = "email"
        case "domain":
            blocklistEntriesViewModel.filter = "domain"
        case "all":
            blocklistEntriesViewModel.filter = nil
        default:
            blocklistEntriesViewModel.filter = nil
        }

        Task {
            await blocklistEntriesViewModel.getblocklistEntries(forceReload: true)
        }
    }

    func LoadFilter() {
        filterChips = GetFilterChips()
    }

    func GetFilterChips() -> [AddyChipModel] {
        return [
            AddyChipModel(chipId: "all", label: String(localized: "filter_all")),
            AddyChipModel(chipId: "email", label: String(localized: "email")),
            AddyChipModel(chipId: "domain", label: String(localized: "domain")),
        ]
    }

    private func deleteblocklistEntry(blocklistEntry: BlocklistEntries) async {
        let networkHelper = NetworkHelper()
        do {
            let result = try await networkHelper.deleteBlocklistEntry(blocklistId: blocklistEntry.id)
            if result == "204" {
                await blocklistEntriesViewModel.getblocklistEntries(forceReload: true)
            } else {
                activeAlert = .error
                showAlert = true
                errorAlertTitle = String(localized: "error_deleting_blocklist_entry")
                errorAlertMessage = result
            }
        } catch {
            activeAlert = .error
            showAlert = true
            errorAlertTitle = String(localized: "error_deleting_blocklist_entry")
            errorAlertMessage = error.localizedDescription
        }
    }

    func deleteblocklistEntry(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            if let blocklistEntries = blocklistEntriesViewModel.blocklistEntries?.data {
                let item = blocklistEntries[index]
                blocklistEntryToDelete = item
                activeAlert = .deleteblocklistEntry
                showAlert = true

                // Remove from the collection for the smooth animation
                blocklistEntriesViewModel.blocklistEntries?.data.remove(atOffsets: offsets)
            }
        }
    }
}
