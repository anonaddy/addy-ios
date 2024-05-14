//
//  AliasesView.swift
//  addy
//
//  Created by Stijn van de Water on 08/05/2024.
//

import SwiftUI
import addy_shared
import UniformTypeIdentifiers

struct AliasesView: View {
    @EnvironmentObject var mainViewState: MainViewState
    @State private var showError = false
    @EnvironmentObject var aliasesViewModel: AliasesViewModel
    
    private var aliasList: AliasesArray? = nil
    
    
    @State var selectedFilterChip = "filter_all_aliases"
    @State var filterChips = [
        AddyChipModel(filterId: "filter_all_aliases",label: String(localized: "filter_all_aliases")),
        AddyChipModel(filterId: "filter_active_aliases",label: String(localized: "filter_active_aliases")),
        AddyChipModel(filterId: "filter_inactive_aliases",label: String(localized: "filter_inactive_aliases")),
        AddyChipModel(filterId: "filter_deleted_aliases",label: String(localized: "filter_deleted_aliases")),
        AddyChipModel(filterId: "filter_watched_only",label: String(localized: "filter_watched_only")),
    ]
    
    var body: some View {
        NavigationStack(){
            List {
                if let aliasList = aliasesViewModel.aliasList{
                    
                    
                    Section {
                        AddyChipView(chips: $filterChips, selectedChip: $selectedFilterChip) { onTappedChip in
                            withAnimation {
                                selectedFilterChip = onTappedChip.filterId
                            }
                            
                            ApplyFilter(filterId: onTappedChip.filterId)
                        }
                    }.listRowBackground(Color.clear)
                        .listRowInsets(.init())
                    
                    
                    
                    
                    
                    
                    //Only show the stats when the user is NOT searching and there is NO error
                    if (aliasesViewModel.searchQuery == "" &&
                        aliasesViewModel.networkError == ""){
                        Section {
                            VStack{
                                CardView(){
                                    Text("PLACEHOLDER")
                                }
                                CardView(){
                                    Text("PLACEHOLDER")
                                }
                            }.frame(height: 150)
                        }header: {
                            Text(String(localized: "statistics"))
                        }
                    }
                    
                    
                    Section {
                        
                        ForEach (aliasList.data) { alias in
                            ZStack {
                                AliasRowView(alias: alias,isPreview: false)
                                    .listRowBackground(Color.clear)
                                    .contextMenu {
                                        Button {
                                            UIPasteboard.general.setValue(alias.email,forPasteboardType: UTType.plainText.identifier)
                                        } label: {
                                            Label(String(localized: "copy_alias"), systemImage: "clipboard")
                                        }
                                        Button {
                                            UIPasteboard.general.setValue(alias.email,forPasteboardType: UTType.plainText.identifier)
                                        } label: {
                                            Label(String(localized: "send_mail"), systemImage: "paperplane")
                                        }
                                        
                                        if (alias.active){
                                            Button {
                                                UIPasteboard.general.setValue(alias.email,forPasteboardType: UTType.plainText.identifier)
                                            } label: {
                                                Label(String(localized: "disable_alias"), systemImage: "hand.raised")
                                            }
                                        } else {
                                            Button {
                                                UIPasteboard.general.setValue(alias.email,forPasteboardType: UTType.plainText.identifier)
                                            } label: {
                                                Label(String(localized: "enable_alias"), systemImage: "checkmark.circle")
                                            }
                                        }
                                        
                                        if (alias.deleted_at != nil){
                                            Button() {
                                                UIPasteboard.general.setValue(alias.email,forPasteboardType: UTType.plainText.identifier)
                                            } label: {
                                                Label(String(localized: "restore_alias"), systemImage: "arrow.up.trash")
                                            }
                                        } else {
                                            Button(role: .destructive) {
                                                UIPasteboard.general.setValue(alias.email,forPasteboardType: UTType.plainText.identifier)
                                            } label: {
                                                Label(String(localized: "delete_alias"), systemImage: "trash")
                                            }
                                        }
                                        
                                    } preview:
                                {
                                    AliasRowView(alias: alias, isPreview: true)
                                }
                                NavigationLink(destination: AliasDetailView(aliasId: alias.id, aliasEmail: alias.email)){
                                    EmptyView()
                                }.opacity(0)
                                
                            }
                            
                        }
                    }header: {
                        HStack(spacing: 6){
                            Text(String(localized: "aliases"))
                            
                            if (aliasesViewModel.isLoading){
                                ProgressView()
                            }
                        }
                        
                    }
                    
                    if !aliasesViewModel.hasArrivedAtTheLastPage {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .onAppear {
                                aliasesViewModel.loadMoreContent()
                            }
                    }
                    
                }
                
            }
            .overlay(Group {
                
                
                if let aliasList = aliasesViewModel.aliasList{
                    if aliasList.data.isEmpty, !aliasesViewModel.searchQuery.isEmpty {
                        ContentUnavailableView.search(text: aliasesViewModel.searchQuery)
                    } else if aliasList.data.isEmpty, aliasesViewModel.searchQuery.isEmpty {
                        if (aliasesViewModel.isLoading){
                            VStack(alignment: .center, spacing: 0) {
                                Spacer()
                                ContentUnavailableView {
                                    Label(String(localized: "obtaining_aliases"), systemImage: "globe")
                                } description: {
                                    Text(String(localized: "obtaining_aliases_desc"))
                                }
                                
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight:50)
                                Spacer()
                            }
                            
                        } else {
                            ContentUnavailableView {
                                Label(String(localized: "no_aliases"), systemImage: "at.badge.plus")
                            } description: {
                                Text(String(localized: "no_aliases_desc"))
                            }
                        }
                        
                    }
                } else {
                    if (aliasesViewModel.isLoading){
                        VStack(alignment: .center, spacing: 0) {
                            Spacer()
                            ContentUnavailableView {
                                Label(String(localized: "obtaining_aliases"), systemImage: "globe")
                            } description: {
                                Text(String(localized: "obtaining_aliases_desc"))
                            }
                            
                            //TODO: make smaller or smoother
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight:50)
                            Spacer()
                        }
                        
                    }
                    else if (aliasesViewModel.networkError != ""){
                        ContentUnavailableView {
                            Label(String(localized: "something_went_wrong_retrieving_aliases"), systemImage: "wifi.slash")
                        } description: {
                            Text(aliasesViewModel.networkError)
                        } actions: {
                            Button(String(localized: "try_again")) {
                                aliasesViewModel.getAliases(forceReload: true)
                            }
                        }
                    } else {
                        ContentUnavailableView {
                            Label(String(localized: "bug_found"), systemImage: "ladybug")
                        } description: {
                            Text(String(localized: "bug_found_desc"))
                        }
                    }
                    
                }
            })
            .navigationTitle(String(localized: "aliases"))
            .searchable(text: $aliasesViewModel.searchQuery, placement: .navigationBarDrawer(displayMode: .automatic), prompt: String(localized: "aliases_search"))
            .autocorrectionDisabled(true)
            .textInputAutocapitalization(.never)
        }.onAppear(perform: {
            //TODO: Load filter from mem and apply
        })
        

        
    }
    
    func ApplyFilter(filterId: String){
        
        switch (filterId){
        case "filter_all_aliases":
            aliasesViewModel.aliasSortFilter.onlyWatchedAliases = false
            aliasesViewModel.aliasSortFilter.onlyActiveAliases = false
            aliasesViewModel.aliasSortFilter.onlyInactiveAliases = false
            aliasesViewModel.aliasSortFilter.onlyDeletedAliases = false
        
        case "filter_active_aliases":
            aliasesViewModel.aliasSortFilter.onlyWatchedAliases = false
            aliasesViewModel.aliasSortFilter.onlyActiveAliases = true
            aliasesViewModel.aliasSortFilter.onlyInactiveAliases = false
            aliasesViewModel.aliasSortFilter.onlyDeletedAliases = false
        
        case "filter_inactive_aliases":
            aliasesViewModel.aliasSortFilter.onlyWatchedAliases = false
            aliasesViewModel.aliasSortFilter.onlyActiveAliases = false
            aliasesViewModel.aliasSortFilter.onlyInactiveAliases = true
            aliasesViewModel.aliasSortFilter.onlyDeletedAliases = false
        
        case "filter_deleted_aliases":
            aliasesViewModel.aliasSortFilter.onlyWatchedAliases = false
            aliasesViewModel.aliasSortFilter.onlyActiveAliases = false
            aliasesViewModel.aliasSortFilter.onlyInactiveAliases = false
            aliasesViewModel.aliasSortFilter.onlyDeletedAliases = true
        
        case "filter_watched_only":
            aliasesViewModel.aliasSortFilter.onlyWatchedAliases = true
            aliasesViewModel.aliasSortFilter.onlyActiveAliases = false
            aliasesViewModel.aliasSortFilter.onlyInactiveAliases = false
            aliasesViewModel.aliasSortFilter.onlyDeletedAliases = false
        
        default:
            aliasesViewModel.aliasSortFilter.onlyWatchedAliases = false
            aliasesViewModel.aliasSortFilter.onlyActiveAliases = false
            aliasesViewModel.aliasSortFilter.onlyInactiveAliases = false
            aliasesViewModel.aliasSortFilter.onlyDeletedAliases = false
        
        }
        
        aliasesViewModel.getAliases(forceReload: true)
    }
    
}


#Preview {
    AliasesView()
}
