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
    @EnvironmentObject var aliasesViewModel: AliasesViewModel
    @State private var isPresentingFilterOptionsAliasBottomSheet = false
        
    
    @State var selectedFilterChip = "filter_all_aliases"
    @State var filterChips: [AddyChipModel] = []
    
    
    
    var body: some View {
        NavigationStack(){
            List {
                if let aliasList = aliasesViewModel.aliasList{
                    
                    
                    Section {
                        AddyChipView(chips: $filterChips, selectedChip: $selectedFilterChip, singleLine: true) { onTappedChip in
                            withAnimation {
                                selectedFilterChip = onTappedChip.chipId
                            }
                            
                            ApplyFilter(chipId: onTappedChip.chipId)
                        }
                    }.listRowBackground(Color.clear)
                        .listRowInsets(.init())
                    
                    
                    
                    
                    
                    
                    // Only show the stats when the user is NOT searching and there is NO error
                    if (aliasesViewModel.searchQuery != "" &&
                        aliasesViewModel.networkError == ""){
                        Section {
                            VStack{
                                HStack{
                                    Image(systemName: "at.circle")
                                        .resizable()
                                        .frame(width: 35, height: 35)
                                        .foregroundColor(.accentColor)
                                        .padding(.trailing, 12)
                                        .frame(width: 35)
                                    VStack(alignment: .leading) {
                                        Text(String(localized: "emails_forwarded"))
                                            .font(.headline)
                                        Text(String(format: String(localized: "forwarded_blocked_stat"), "\(mainViewState.userResource!.total_emails_forwarded)", "\(mainViewState.userResource!.total_emails_blocked)"))
                                            .font(.subheadline)
                                    }
                                    Spacer()
                                    
                                }.padding(.vertical, 8)
                                
                                Divider()
                                HStack{
                                    Image(systemName: "paperplane")
                                        .resizable()
                                        .frame(width: 35, height: 35)
                                        .foregroundColor(.accentColor)
                                        .padding(.trailing, 12)
                                        .frame(width: 35)
                                    VStack(alignment: .leading) {
                                        Text(String(localized: "emails_forwarded"))
                                            .font(.headline)
                                        Text(String(format: String(localized: "replied_sent_stat"), "\(mainViewState.userResource!.total_emails_replied)", "\(mainViewState.userResource!.total_emails_sent)"))
                                            .font(.subheadline)
                                    }
                                    Spacer()
                                }.padding(.vertical, 8)
                            }
                        } header: {
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
                                NavigationLink(destination: AliasDetailView(aliasId: alias.id, aliasEmail: alias.email).environmentObject(mainViewState)){
                                    EmptyView()
                                }.opacity(0)
                                
                            }
                            
                        }
                    }header: {
                        HStack(spacing: 6){
                            if (aliasesViewModel.aliasSortFilterRequest != aliasesViewModel.defaultSortFilterRequest){
                                Text(String(localized: "aliases_filtered"))
                            } else {
                                Text(String(localized: "aliases"))
                            }
                            
                            if (aliasesViewModel.isLoading){
                                ProgressView()
                                    .frame(maxHeight: 4)
                                
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
                
                
                // If there is an aliasList (aka, if the list is visible)
                if let aliasList = aliasesViewModel.aliasList{
                    
                    // If there is NO data inside the list AND the user has actually tried searching for something
                    if aliasList.data.isEmpty, !aliasesViewModel.searchQuery.isEmpty {
                        // Show the search unavailable screen
                        ContentUnavailableView.search(text: aliasesViewModel.searchQuery)
                        
                        // If there is NO data inside the list AND the user has NOT tried searching for something
                        
                        //TODO: this view is visible for 1s after clearing search when looking for aliases without results (empty list)
                    } else if aliasList.data.isEmpty, aliasesViewModel.searchQuery.isEmpty {
                            ContentUnavailableView {
                                Label(String(localized: "no_aliases"), systemImage: "at.badge.plus")
                            } description: {
                                Text(String(localized: "no_aliases_desc"))
                            }
                    }
                } else {
                    // If there is NO aliasList (aka, if the list is not visible)
                    
                    // If the viewModel is still loading
                    if (aliasesViewModel.isLoading){
                        // Obtaining screen
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
                        
                    }
                    // No aliases and not loading? Check if there is an error
                    else if (aliasesViewModel.networkError != ""){
                        // Error screen
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
                        // No aliases, not loading AND no error? How even? This must be a bug.
                        AddyBugFound()
                    }
                    
                }
            })
            .navigationTitle(String(localized: "aliases"))
            .navigationBarItems(trailing: Button(action: {
                             // button activates link
                              //self.addMode = true
                            } ) {
                            Image(systemName: "plus")
                                .resizable()
                                .padding(6)
                                .frame(width: 24, height: 24)
                                .background(Color.accentColor)
                                .clipShape(Circle())
                                .foregroundColor(.white)
                        } )
            .searchable(text: $aliasesViewModel.searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: String(localized: "aliases_search"))
            .onSubmit(of: .search) {
                    aliasesViewModel.searchAliases(searchQuery: aliasesViewModel.searchQuery)
                }
            .autocorrectionDisabled(true)
            .textInputAutocapitalization(.never)
            .sheet(isPresented: $isPresentingFilterOptionsAliasBottomSheet) {
                FilterOptionsAliasBottomSheet(aliasSortFilterRequest: self.aliasesViewModel.aliasSortFilterRequest){ aliasSortFilterRequest in
                    // This will also reload new filter in memory
                    SaveFilter(chipId: "filter_custom", aliasSortFilterRequest: aliasSortFilterRequest)
                    
                    // Hide dialog and refresh aliases
                    isPresentingFilterOptionsAliasBottomSheet = false
                    aliasesViewModel.getAliases(forceReload: true)
                }
            }
        }.onAppear(perform: {
            LoadFilter()
        })
        
        
        
    }
    
    func ApplyFilter(chipId: String){
        
        
        switch (chipId){
        case "filter_all_aliases":
            aliasesViewModel.aliasSortFilterRequest.onlyWatchedAliases = false
            aliasesViewModel.aliasSortFilterRequest.onlyActiveAliases = false
            aliasesViewModel.aliasSortFilterRequest.onlyInactiveAliases = false
            aliasesViewModel.aliasSortFilterRequest.onlyDeletedAliases = false
            aliasesViewModel.aliasSortFilterRequest.sort = "created_at"
            aliasesViewModel.aliasSortFilterRequest.sortDesc = false
        case "filter_active_aliases":
            aliasesViewModel.aliasSortFilterRequest.onlyWatchedAliases = false
            aliasesViewModel.aliasSortFilterRequest.onlyActiveAliases = true
            aliasesViewModel.aliasSortFilterRequest.onlyInactiveAliases = false
            aliasesViewModel.aliasSortFilterRequest.onlyDeletedAliases = false
            aliasesViewModel.aliasSortFilterRequest.sort = "created_at"
            aliasesViewModel.aliasSortFilterRequest.sortDesc = false
        case "filter_inactive_aliases":
            aliasesViewModel.aliasSortFilterRequest.onlyWatchedAliases = false
            aliasesViewModel.aliasSortFilterRequest.onlyActiveAliases = false
            aliasesViewModel.aliasSortFilterRequest.onlyInactiveAliases = true
            aliasesViewModel.aliasSortFilterRequest.onlyDeletedAliases = false
            aliasesViewModel.aliasSortFilterRequest.sort = "created_at"
            aliasesViewModel.aliasSortFilterRequest.sortDesc = false
        case "filter_deleted_aliases":
            aliasesViewModel.aliasSortFilterRequest.onlyWatchedAliases = false
            aliasesViewModel.aliasSortFilterRequest.onlyActiveAliases = false
            aliasesViewModel.aliasSortFilterRequest.onlyInactiveAliases = false
            aliasesViewModel.aliasSortFilterRequest.onlyDeletedAliases = true
            aliasesViewModel.aliasSortFilterRequest.sort = "created_at"
            aliasesViewModel.aliasSortFilterRequest.sortDesc = false
        case "filter_watched_only":
            aliasesViewModel.aliasSortFilterRequest.onlyWatchedAliases = true
            aliasesViewModel.aliasSortFilterRequest.onlyActiveAliases = false
            aliasesViewModel.aliasSortFilterRequest.onlyInactiveAliases = false
            aliasesViewModel.aliasSortFilterRequest.onlyDeletedAliases = false
            aliasesViewModel.aliasSortFilterRequest.sort = "created_at"
            aliasesViewModel.aliasSortFilterRequest.sortDesc = false
        case "filter_custom":
            isPresentingFilterOptionsAliasBottomSheet = true
            
        default:
            aliasesViewModel.aliasSortFilterRequest.onlyWatchedAliases = false
            aliasesViewModel.aliasSortFilterRequest.onlyActiveAliases = false
            aliasesViewModel.aliasSortFilterRequest.onlyInactiveAliases = false
            aliasesViewModel.aliasSortFilterRequest.onlyDeletedAliases = false
        }
        
        
        SaveFilter(chipId: chipId, aliasSortFilterRequest: aliasesViewModel.aliasSortFilterRequest)
        
        aliasesViewModel.getAliases(forceReload: true)
    }
    
    func SaveFilter(chipId: String, aliasSortFilterRequest: AliasSortFilterRequest){
        
        var aliasSortFilterRequestTemp = aliasSortFilterRequest
        aliasSortFilterRequestTemp.filter = nil // Never store the current searchQuery in the app
        
        let aliasSortFilter = AliasSortFilter(aliasSortFilterRequest: aliasSortFilterRequestTemp, filterId: chipId)
        
        // Store a copy of the just received data locally
        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(aliasSortFilter),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            SettingsManager(encrypted: false).putSettingsString(key: .aliasSortFilter, string: jsonString)
        }
        
        
        LoadFilter()
        
    }
    
    func LoadFilter(){
        let aliasSortFilterJson = SettingsManager(encrypted: false).getSettingsString(key: .aliasSortFilter)
        var aliasSortFilterObject: AliasSortFilter? = nil
        if let json = aliasSortFilterJson {
            aliasSortFilterObject = try? JSONDecoder().decode(AliasSortFilter.self, from: Data(json.utf8))
        }
        
        if let object = aliasSortFilterObject {
            aliasesViewModel.aliasSortFilterRequest = object.aliasSortFilterRequest
        }
        
        self.filterChips = GetFilterChips()
        
        if let i = GetFilterChips().firstIndex(where: { $0.chipId == aliasSortFilterObject?.filterId }) {
            self.selectedFilterChip = GetFilterChips()[i].chipId
        }
        
        
        // Always try to restore (re-set) the filter after loading a filter from settings.
        // When a user has entered a keyword and taps one of the quick filter badges, it clears the filter right before storing this filter in settings
        // But after loading always try to get the searchQuery back into the filter so the user can continue searching.
        
        aliasesViewModel.aliasSortFilterRequest.filter = self.aliasesViewModel.searchQuery
        
    }
    
    
    func GetFilterChips() -> [AddyChipModel]{
        return [
            AddyChipModel(chipId: "filter_all_aliases",label: String(localized: "filter_all_aliases")),
            AddyChipModel(chipId: "filter_active_aliases",label: String(localized: "filter_active_aliases")),
            AddyChipModel(chipId: "filter_inactive_aliases",label: String(localized: "filter_inactive_aliases")),
            AddyChipModel(chipId: "filter_deleted_aliases",label: String(localized: "filter_deleted_aliases")),
            AddyChipModel(chipId: "filter_watched_only",label: String(localized: "filter_watched_only")),
            AddyChipModel(chipId: "filter_custom",label: String(localized: "filter_custom"))
        ]
    }
    
}


#Preview {
    AliasesView()
}
