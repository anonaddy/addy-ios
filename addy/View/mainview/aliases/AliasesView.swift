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
    @Binding var isPresentingProfileBottomSheet: Bool
    @Binding var isShowingFailedDeliveriesView: Bool

    @EnvironmentObject var mainViewState: MainViewState
    @StateObject var aliasesViewModel = AliasesViewModel()
    
    @State private var isPresentingFilterOptionsAliasBottomSheet = false
    @State private var isPresentingAddAliasBottomSheet = false
    
    enum ActiveAlert {
        case reachedMaxAliases, deleteAliases, restoreAlias, error
    }
    
    @State private var activeAlert: ActiveAlert = .reachedMaxAliases
    @State private var showAlert: Bool = false
    
    @State private var shouldReloadDataInParent = false

    
    @State private var aliasInContextMenu: Aliases? = nil
    @State private var aliasToSendMailFrom: Aliases? = nil
    
    @State private var errorAlertTitle = ""
    @State private var errorAlertMessage = ""

    @State var selectedFilterChip:String? = "filter_all_aliases"
    @State var filterChips: [AddyChipModel] = []
    
    var body: some View {
        NavigationStack(){
            List {
                if let aliasList = aliasesViewModel.aliasList{
                    
                    
                    Section {
                        AddyRoundedChipView(chips: $filterChips, selectedChip: $selectedFilterChip, singleLine: true) { onTappedChip in
                            withAnimation {
                                selectedFilterChip = onTappedChip.chipId
                            }
                            
                            ApplyFilter(chipId: onTappedChip.chipId)
                        }
                    }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())
                    
                    
                    
                    
                    
                    
                    // Only show the stats when the user is NOT searching and there is NO error
                    if (aliasesViewModel.searchQuery == "" &&
                        aliasesViewModel.networkError == "" && !aliasList.data.isEmpty){
                        Section {
                            
                            HStack{
                                
                                
                                VStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.accentColor)
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Image(systemName: "at.circle.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 25, height: 25)
                                                .foregroundColor(.white)
                                        )
                                    
                                    Text(String(localized: "emails_forwarded"))
                                        .font(.subheadline)
                                        .multilineTextAlignment(.center)
                                    
                                    Text(String(format: String(localized: "forwarded_blocked_stat"), "\(mainViewState.userResource!.total_emails_forwarded)", "\(mainViewState.userResource!.total_emails_blocked)"))
                                        .font(.caption)
                                        .multilineTextAlignment(.center)
                                }
                                Spacer()
                                Divider().padding(.vertical,24)
                                Spacer()
                                
                                VStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.accentColor)
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Image(systemName: "tray.and.arrow.up.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 25, height: 25)
                                                .foregroundColor(.white)
                                        )
                                    Text(String(localized: "emails_forwarded"))
                                        .font(.subheadline)
                                        .multilineTextAlignment(.center)
                                    
                                    Text(String(format: String(localized: "forwarded_blocked_stat"), "\(mainViewState.userResource!.total_emails_forwarded)", "\(mainViewState.userResource!.total_emails_blocked)"))
                                        .font(.caption)
                                        .multilineTextAlignment(.center)
                                    
                                }
                                
                                
                            }.padding(12)
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
                                            self.aliasToSendMailFrom = alias
                                      } label: {
                                            Label(String(localized: "send_mail"), systemImage: "paperplane")
                                        }
                                        
                                        if (alias.deleted_at != nil){
                                            Button() {
                                                self.activeAlert = .restoreAlias
                                                self.showAlert = true
                                            } label: {
                                                Label(String(localized: "restore_alias"), systemImage: "arrow.up.trash")
                                            }
                                        } else {
                                            
                                            if (alias.active){
                                                Button {
                                                    DispatchQueue.global(qos: .background).async {
                                                        self.deactivateAlias(alias: alias)
                                                    }                                            } label: {
                                                        Label(String(localized: "disable_alias"), systemImage: "hand.raised")
                                                    }
                                            } else {
                                                
                                                Button {
                                                    DispatchQueue.global(qos: .background).async {
                                                        self.activateAlias(alias: alias)
                                                    }
                                                } label: {
                                                    Label(String(localized: "enable_alias"), systemImage: "checkmark.circle")
                                                }
                                            }
                                            
                                            Button(role: .destructive) {
                                                self.activeAlert = .deleteAliases
                                                self.showAlert = true
                                            } label: {
                                                Label(String(localized: "delete_alias"), systemImage: "trash")
                                            }
                                        }
                                        
                                    } preview:
                                {
                                    AliasRowView(alias: alias, isPreview: true).onAppear {
                                        self.aliasInContextMenu = alias

                                    }
                                }
                            NavigationLink(destination: AliasDetailView(aliasId: alias.id, aliasEmail: alias.email, shouldReloadDataInParent: $shouldReloadDataInParent)
                                .environmentObject(mainViewState)){
                                    EmptyView()
                                }
                                .opacity(0)
                                .onChange(of: shouldReloadDataInParent) {
                                if shouldReloadDataInParent {
                                    aliasesViewModel.getAliases(forceReload: true)
                                                self.shouldReloadDataInParent = false
                                            }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        UIPasteboard.general.setValue(alias.email,forPasteboardType: UTType.plainText.identifier)
                                    } label: {
                                        Label(String(localized: "copy_alias"), systemImage: "clipboard")
                                    }.tint(Color.accentColor)
                                    Button {
                                        self.aliasToSendMailFrom = alias
                                  } label: {
                                        Label(String(localized: "send_mail"), systemImage: "paperplane")
                                  }.tint(Color.accentColor.opacity(0.8))
                                                           
                                                        }
                                
                            }
                        }.onDelete(perform: deleteAlias)

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
                            .task {
                                aliasesViewModel.loadMoreContent()
                            }
                    }
                    
                }
                
            }
            .refreshable {
                self.aliasesViewModel.getAliases(forceReload: true)
            }
            .alert(isPresented: $showAlert) {
                switch activeAlert {
                case .reachedMaxAliases:
                    return Alert(title: Text(String(localized: "aliaswatcher_max_reached")), message: Text(String(localized: "aliaswatcher_max_reached_desc")), dismissButton: .default(Text(String(localized: "understood"))))
                case .deleteAliases:
                    return Alert(title: Text(String(localized: "delete_alias")), message: Text(String(localized: "delete_alias_confirmation_desc")), primaryButton: .destructive(Text(String(localized: "delete"))){
                        
                        DispatchQueue.global(qos: .background).async {
                            self.deleteAlias(alias: aliasInContextMenu!)
                        }
                    }, secondaryButton: .cancel(){
                        aliasesViewModel.getAliases(forceReload: true)
                    })
                case .restoreAlias:
                    return Alert(title: Text(String(localized: "restore_alias")), message: Text(String(localized: "restore_alias_confirmation_desc")), primaryButton: .default(Text(String(localized: "restore"))){
                        
                        DispatchQueue.global(qos: .background).async {
                            self.restoreAlias(alias: aliasInContextMenu!)
                        }
                    }, secondaryButton: .cancel(){
                        aliasesViewModel.getAliases(forceReload: true)
                    })
                case .error:
                    return Alert(
                        title: Text(errorAlertTitle),
                        message: Text(errorAlertMessage)
                    )
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
                    } else if aliasList.data.isEmpty, aliasesViewModel.searchQuery.isEmpty {
                        ContentUnavailableView {
                            Label(String(localized: "no_aliases"), systemImage: "at.badge.plus")
                        } description: {
                            Text(String(localized: "no_aliases_desc"))
                        }
                    }
                } else {
                    // If there is NO aliasList (aka, if the list is not visible)
                    
                    
                    // No aliases, check if there is an error
                    if (aliasesViewModel.networkError != ""){
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
                        // No aliasList and no error. It must still be loading...
                        VStack(alignment: .center, spacing: 0) {
                            Spacer()
                            ContentUnavailableView {
                                Label(String(localized: "obtaining_aliases"), systemImage: "globe")
                            } description: {
                                Text(String(localized: "obtaining_desc"))
                            }
                            
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight:50)
                            Spacer()
                        }
                    }
                    
                }
            })
            .navigationTitle(String(localized: "aliases"))
            .navigationBarItems(trailing: HStack{
                Button(action: {
                    self.isShowingFailedDeliveriesView = true
                }) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.primary)
                }
                
                Button(action: {
                    self.isPresentingProfileBottomSheet = true
                }) {
                    Image(systemName: "person.crop.circle.fill")
                        .foregroundStyle(.primary)
                }
                
                Button(action: {
                    self.isPresentingAddAliasBottomSheet = true
                } ) {
                    Image(systemName: "plus")
                        .resizable()
                        .padding(6)
                        .frame(width: 24, height: 24)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                        .foregroundColor(.white)
                }
            })
            .searchable(text: $aliasesViewModel.searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: String(localized: "aliases_search"))
            .onSubmit(of: .search) {
                aliasesViewModel.searchAliases(searchQuery: aliasesViewModel.searchQuery)
            }
            .autocorrectionDisabled(true)
            .textInputAutocapitalization(.never)
            .sheet(isPresented: $isPresentingFilterOptionsAliasBottomSheet) {
                NavigationStack {
                    FilterOptionsAliasBottomSheet(aliasSortFilterRequest: self.aliasesViewModel.aliasSortFilterRequest){ aliasSortFilterRequest in
                        // This will also reload new filter in memory
                        SaveFilter(chipId: "filter_custom", aliasSortFilterRequest: aliasSortFilterRequest)
                        
                        // Hide dialog and refresh aliases
                        isPresentingFilterOptionsAliasBottomSheet = false
                        aliasesViewModel.getAliases(forceReload: true)
                    }
                }
            }
            // Replace the current .sheet modifier with this one
            .sheet(item: $aliasToSendMailFrom) { alias in
                    NavigationStack {
                        EditAliasSendMailRecipientBottomSheet(aliasEmail: alias.email) { addresses in
                            self.onPressSend(toString: addresses)
                        }
                        .onDisappear {
                            // Reset the aliasInContextMenu when the sheet disappears
                            self.aliasToSendMailFrom = nil
                        }
                    }
                
            }
            .sheet(isPresented: $isPresentingAddAliasBottomSheet) {
                NavigationStack {
                    AddAliasBottomSheet(){
                        // Hide dialog and refresh aliases
                        isPresentingAddAliasBottomSheet = false
                        aliasesViewModel.getAliases(forceReload: true)
                    }.environmentObject(mainViewState)
                    
                }
                
                
                
                
            }
        }.onAppear(perform: {
            LoadFilter()

            if let aliasList = aliasesViewModel.aliasList{
                if (aliasList.data.isEmpty) {
                    aliasesViewModel.getAliases(forceReload: true) 
                }
            } else {
                aliasesViewModel.getAliases(forceReload: true)
            }
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
        let aliasSortFilterJson = MainViewState.shared.settingsManager.getSettingsString(key: .aliasSortFilter)
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
    
    private func onPressSend(toString: String) {
        guard let alias = aliasInContextMenu else { return }
        // Get recipients
        let recipients = AnonAddyUtils.getSendAddress(recipientEmails: toString, alias: alias)
        
        // Copy the email addresses to clipboard
        UIPasteboard.general.setValue(recipients.joined(separator: ";"),forPasteboardType: UTType.plainText.identifier)
        
        // Prepare mailto URL
        let mailtoURL = AnonAddyUtils.createMailtoURL(recipients: recipients)
        
        // Open mailto URL
        if let url = mailtoURL {
            UIApplication.shared.open(url)
        }
    }
    
    private func activateAlias(alias:Aliases) {
        let networkHelper = NetworkHelper()
        networkHelper.activateSpecificAlias(completion: { alias, error in
            DispatchQueue.main.async {
                
                if alias != nil {
                    // TODO can I update this item without full reload
                    aliasesViewModel.getAliases(forceReload: true)
                } else {
                    activeAlert = .error
                    showAlert = true
                    errorAlertTitle = String(localized: "error_forgetting_alias")
                    errorAlertMessage = error ?? String(localized: "error_unknown_refer_to_logs")
                }
            }
        },aliasId: alias.id)
    }
    
    private func deactivateAlias(alias:Aliases) {
        let networkHelper = NetworkHelper()
        networkHelper.deactivateSpecificAlias(completion: { result in
            DispatchQueue.main.async {
                
                if result == "204" {
                    // TODO can I update this item without full reload
                    aliasesViewModel.getAliases(forceReload: true)
                } else {
                    activeAlert = .error
                    showAlert = true
                    errorAlertTitle = String(localized: "error_forgetting_alias")
                    errorAlertMessage = result ?? String(localized: "error_unknown_refer_to_logs")
                }
            }
        },aliasId: alias.id)
    }
    
    private func deleteAlias(alias:Aliases) {
        let networkHelper = NetworkHelper()
        networkHelper.deleteAlias(completion: { result in
            DispatchQueue.main.async {
                
                if result == "204" {
                    // TODO can I remove this item without full reload
                    aliasesViewModel.getAliases(forceReload: true)
                } else {
                    activeAlert = .error
                    showAlert = true
                    errorAlertTitle = String(localized: "error_deleting_alias")
                    errorAlertMessage = result ?? String(localized: "error_unknown_refer_to_logs")
                }
            }
        },aliasId: alias.id)
    }
    
    func deleteAlias(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            if let aliases = aliasesViewModel.aliasList?.data {
                let item = aliases[index]
                aliasInContextMenu = item
                activeAlert = .deleteAliases
                showAlert = true
                
                // Remove from the collection for the smooth animation
                aliasesViewModel.aliasList?.data.remove(atOffsets: offsets)
                
            }
        }
    }
    
    private func restoreAlias(alias:Aliases) {
        let networkHelper = NetworkHelper()
        networkHelper.restoreAlias(completion: { alias, error in
            DispatchQueue.main.async {
                
                if alias != nil {
                    // TODO can I update this item without full reload
                    aliasesViewModel.getAliases(forceReload: true)
                } else {
                    activeAlert = .error
                    showAlert = true
                    errorAlertTitle = String(localized: "error_restoring_alias")
                    errorAlertMessage = error ?? String(localized: "error_unknown_refer_to_logs")
                }
            }
        },aliasId: alias.id)
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

//
//#Preview {
//    AliasesView()
//}
