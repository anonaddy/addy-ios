//
//  ContentView.swift
//  Addy Watchkit Watch App
//
//  Created by Stijn van de Water on 31/01/2026.
//

import SwiftUI
import addy_shared

struct AliasesView: View {
    @StateObject private var aliasesViewModel = AliasViewModel()
    @StateObject private var favoritesHelper = FavoriteAliasHelper()
    @State private var showingSettings = false
    @State private var showingCreateAlias = false
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var mainViewState: MainViewState
    @Environment(\.scenePhase) private var scenePhase

    // Local state for quickly checking favorite status
    @State private var favoriteIds: Set<String> = []

    var body: some View {
        NavigationStack {
            List {

                if aliasesViewModel.isLoading {
                    loadingView
                } else if let aliasList = aliasesViewModel.aliasList {
                    if aliasList.data.isEmpty {
                        noAliasesView
                    } else {
                        
                        if !favoriteIds.isEmpty {
                            if let bulkAliasList = aliasesViewModel.bulkAliasList {
                                if !bulkAliasList.data.isEmpty {
                                    Section("aliases_favorite_aliases") {
                                        ForEach(bulkAliasList.data) { alias in
                                            AliasRow(
                                                alias: alias,
                                                isFavorite: favoriteIds.contains(alias.id)
                                            )
                                            //                                .swipeActions(edge: .leading) {
                                            //                                    Button {
                                            //                                        toggleFavorite(alias: alias)
                                            //                                    } label: {
                                            //                                        Label("favorite", systemImage: "star")
                                            //                                    }
                                            //                                    .tint(.yellow)
                                            //                                }
                                        }
                                    }
                                }
                                
                            }
                        }
                        
                        
                        Section("aliases_recent_aliases") {
                            ForEach(aliasList.data) { alias in
                                AliasRow(
                                    alias: alias,
                                    isFavorite: favoriteIds.contains(alias.id)
                                )
//                                .swipeActions(edge: .leading) {
//                                    Button {
//                                        toggleFavorite(alias: alias)
//                                    } label: {
//                                        Label("favorite", systemImage: "star")
//                                    }
//                                    .tint(.yellow)
//                                }
                            }
                        }
                    }
                } else {
                    if aliasesViewModel.networkError != "" {
                        errorView
                    } else {
                        loadingView
                    }
                }
            }
            .containerBackground(Color.gray.opacity(0.1).gradient, for: .navigation)
            .navigationDestination(for: Aliases.self) { alias in
                ManageAliasView(alias: alias)
            }
            .navigationDestination(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(appState)
            }
            .navigationDestination(isPresented: $showingCreateAlias) {
                CreateAliasView()
                    .environmentObject(appState)
                    .environmentObject(mainViewState)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        self.showingSettings = true
                    } label: {
                        Image(systemName:"gear")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        self.showingCreateAlias = true
                    } label: {
                        Image(systemName:"plus")
                    }
                }
            }
            .navigationTitle(String(localized: "aliases", bundle: Bundle(for: SharedData.self)))
            .onAppear {
                // Initialize favorites state from helper
                if let stored = favoritesHelper.getFavoriteAliases() {
                    favoriteIds = Set(stored)
                }
                
                Task {
                    await loadData()
                }
                
            }
        }
        .onChange(of: scenePhase) {
                        if scenePhase == .active {
                            Task {
                                await loadData()
                            }
                        }
                    }
    }
    
    
    private func loadData() async {
        // Cache userResource
        _ = await NetworkHelper().cacheUserResourceForWidget()
        
        // Load aliases (exclude favorites)
        await aliasesViewModel.getAliases(excludeAliases: favoriteIds.sorted())
        
        // Load favorites if any exist
        if !favoriteIds.isEmpty {
            await aliasesViewModel.bulkGetAlias(aliases: favoriteIds.sorted())
        }
    }

    

    private var loadingView: some View {
        VStack(alignment: .center, spacing: 0) {
            Spacer()
            ContentUnavailableView {
                Label(String(localized: "obtaining_aliases", bundle: Bundle(for: SharedData.self)), systemImage: "globe")
            } description: {
                Text(String(localized: "obtaining_desc", bundle: Bundle(for: SharedData.self)))
            }

            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: 50)
            Spacer()
        }
    }

    private var noAliasesView: some View {
        ContentUnavailableView {
            Label(String(localized: "no_aliases", bundle: Bundle(for: SharedData.self)), systemImage: "at.badge.plus")
        } description: {
            Text(String(localized: "no_aliases_desc"))
        }
    }

    private var errorView: some View {
        ContentUnavailableView {
            Label(String(localized: "something_went_wrong_retrieving_aliases", bundle: Bundle(for: SharedData.self)), systemImage: "wifi.slash")
        } description: {
            Text(aliasesViewModel.networkError)
        } actions: {
            Button(String(localized: "try_again", bundle: Bundle(for: SharedData.self))) {
                Task {
                    await aliasesViewModel.getAliases(excludeAliases: favoriteIds.sorted())
                    await aliasesViewModel.bulkGetAlias(aliases: favoriteIds.sorted())
                }
            }
        }
    }

//    // MARK: - Favorites
//
//    private func toggleFavorite(alias: Aliases) {
//        if favoriteIds.contains(alias.id) {
//            favoritesHelper.removeAliasAsFavorite(alias.id)
//            favoriteIds.remove(alias.id)
//        } else {
//            if favoritesHelper.addAliasAsFavorite(alias.id) {
//                favoriteIds.insert(alias.id)
//            } else {
//                // TODO: Show error to user if needed
//            }
//        }
//    }
}

// MARK: - Row

struct AliasRow: View {
    let alias: Aliases
    let isFavorite: Bool

    var body: some View {
        NavigationLink(value: alias) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.system(size: 16))
                        .foregroundStyle(isFavorite ? .yellow : .gray)

                    Text(alias.email)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Text(alias.description ?? createdText(alias.created_at))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private func localizedDate(_ dateString: String) -> String {
        do {
            return try DateTimeUtils
                .convertStringToLocalTimeZoneDate(dateString)
                .aliasRowDateDisplay()
        } catch {
            return DateTimeUtils.convertStringToLocalTimeZoneString(dateString)
        }
    }

    private func createdText(_ createdAt: String) -> String {
        String(
            format: NSLocalizedString("created_at_s", bundle: Bundle(for: SharedData.self), comment: ""),
            localizedDate(createdAt)
        )
    }
}



#Preview {
    AliasesView()
}
