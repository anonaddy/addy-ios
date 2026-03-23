//
//  ManageBlocklistView.swift
//  addy
//
//  Created by Stijn van de Water on 09/03/2026.
//


import SwiftUI

import addy_shared
import SwiftUI

struct BlocklistView: View {
    @EnvironmentObject var mainViewState: MainViewState
    @StateObject var blocklistEntriesViewModel = BlocklistEntriesViewModel()

    enum ActiveAlert {
        case error, deleteblocklistEntry
    }

    @State private var activeAlert: ActiveAlert = .error
    @State private var showAlert: Bool = false

    @State private var blocklistEntryToDelete: BlocklistEntries? = nil

    @State private var isPresentingAddblocklistEntryBottomSheet = false

    @State private var shouldReloadDataInParent = false

    @State private var errorAlertTitle = ""
    @State private var errorAlertMessage = ""
    
    @Binding var horizontalSize: UserInterfaceSizeClass
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
            if let blocklistEntries = blocklistEntriesViewModel.blocklistEntries {
                if blocklistEntries.data.isEmpty {
                    Task {
                        await blocklistEntriesViewModel.getblocklistEntries()
                    }
                }
            }
        })
    }

    private var blocklistEntriesViewBody: some View {
        List {
            if let blocklistEntries = blocklistEntriesViewModel.blocklistEntries {
                if !blocklistEntries.data.isEmpty {
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

                                                Text(DateTimeUtils.convertStringToLocalTimeZoneString(blocklistEntry.created_at))
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                            }
                        }.onDelete(perform: deleteblocklistEntry)
                    } header: {
                        HStack(spacing: 6) {
                            Text(String(localized: "blocklist_entries"))
                            
                            if blocklistEntriesViewModel.isLoading {
                                ProgressView()
                                    .frame(maxHeight: 4)
                            }
                        }
                        
                    } footer: {
                        Text(String(localized: "manage_blocklist_desc")).padding(.top)
                        
                    }
                }
            }

        }.refreshable {
            if horizontalSize == .regular {
                // When in regular size (tablet) mode, refreshing aliases also ask the mainView to update general data
                self.onRefreshGeneralData?()
            }
            await self.blocklistEntriesViewModel.getblocklistEntries()
        }
        .sheet(isPresented: $isPresentingAddblocklistEntryBottomSheet) {
            NavigationStack {
                AddBlocklistEntryBottomSheet() {
                    Task {
                        await blocklistEntriesViewModel.getblocklistEntries()
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
                        await blocklistEntriesViewModel.getblocklistEntries()
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
                if blocklistEntries.data.isEmpty {
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
                    // Error screen
                    ContentUnavailableView {
                        Label(String(localized: "something_went_wrong_retrieving_blocklist_entries"), systemImage: "wifi.slash")
                    } description: {
                        Text(blocklistEntriesViewModel.networkError)
                    } actions: {
                        Button(String(localized: "try_again", bundle: Bundle(for: SharedData.self))) {
                            Task {
                                await blocklistEntriesViewModel.getblocklistEntries()
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



    private func deleteblocklistEntry(blocklistEntry: BlocklistEntries) async {
        let networkHelper = NetworkHelper()
        do {
            let result = try await networkHelper.deleteBlocklistEntry(blocklistId: blocklistEntry.id)
            if result == "204" {
                await blocklistEntriesViewModel.getblocklistEntries()
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
