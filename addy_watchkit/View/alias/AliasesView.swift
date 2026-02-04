//
//  ContentView.swift
//  Addy Watchkit Watch App
//
//  Created by Stijn van de Water on 31/01/2026.
//

import SwiftUI
import addy_shared

struct AliasesView: View {
    // Inject your manager/viewmodel
        @StateObject private var viewModel = AliasViewModel()
        
        var body: some View {
            NavigationStack {
                List {
                    // Action Row (Top "Add/Manage" button equivalent)
                    Section {
                        Button(action: {
                            // Handle "AliasActionRow" click (e.g., create new)
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.blue)
                                Text("Create New Alias")
                            }
                        }
                    }
                    
                    // The Alias Items
                    Section("Active Aliases") {
                        if viewModel.isLoading {
                            ProgressView()
                        } else if viewModel.aliases.isEmpty {
                            Text("No aliases found")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(viewModel.aliases) { alias in
                                AliasRow(
                                    alias: alias,
                                    isFavorite: viewModel.favoriteAliases.contains(alias.id)
                                )
                                .swipeActions(edge: .leading) {
                                    Button {
                                        viewModel.toggleFavorite(id: alias.id)
                                    } label: {
                                        Label("Favorite", systemImage: "star")
                                    }
                                    .tint(.yellow)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Aliases")
                // watchOS 10: Colored background for the entire list container
                .containerBackground(Color.gray.opacity(0.1).gradient, for: .navigation)
                .onAppear {
                    viewModel.fetchAliases()
                }
            }
        }
    }

    // Subview for the individual row (Equivalent to your Chip)
    struct AliasRow: View {
        let alias: Aliases
        let isFavorite: Bool
        
        var body: some View {
            // NavigationLink gives you the "Card/Chip" tap effect automatically in List
            NavigationLink(value: alias) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        // Star Icon
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
            // Navigation destination would be defined in the parent NavigationStack
            .navigationDestination(for: Aliases.self) { alias in
                ManageAliasView(alias: alias)
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
            String(format: NSLocalizedString("created_at_s", comment: ""), localizedDate(createdAt))
        }

    }

    // Placeholder for Detail View
    struct ManageAliasView: View {
        let alias: Aliases
        var body: some View {
            Text("Manage \(alias.email)")
                .navigationTitle("Manage")
        }
    }

#Preview {
    AliasesView()
}
