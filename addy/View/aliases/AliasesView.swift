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
    @StateObject var aliasesViewModel = AliasesViewModel()
    
    @State private var isPresentingFilterOptionsAliasBottomSheet = false
    
    enum ActiveAlert {
        case reachedMaxAliases, deleteAlias, forgetAlias, forgetAliasConfirmation, restoreAlias, error
    }
    
    @State private var activeAlert: ActiveAlert = .reachedMaxAliases
    @State private var showAlert: Bool = false
    
    @State private var shouldReloadDataInParent = false
    
    @State private var aliasInContextMenu: Aliases? = nil
    @State private var aliasToSendMailFrom: Aliases? = nil
    @State private var aliasToSendMailFromCopy: Aliases? = nil
    
    @State private var errorAlertTitle = ""
    @State private var errorAlertMessage = ""
    
    @State var selectedFilterChip:String = "filter_all_aliases"
    @State var filterChips: [AddyChipModel] = []
    
    @Binding var horizontalSize: UserInterfaceSizeClass
    var onRefreshGeneralData: (() -> Void)? = nil
    
    @State private var copiedToClipboard = false
    
    @State private var sendToRecipients: String? = nil
    @State private var clients: [ThirdPartyMailClient] = []
    @State private var isPresentingEmailSelectionDialog: Bool = false
    
    
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
        NavigationStack(){
            List {
                
                if aliasesViewModel.networkError == "" {
                    Section {
                        AddyRoundedChipView(chips: $filterChips, selectedChip: $selectedFilterChip, singleLine: true) { onTappedChip in
                            withAnimation {
                                selectedFilterChip = onTappedChip.chipId
                            }
                            
                            ApplyFilter(chipId: onTappedChip.chipId)
                        }
                    }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())
                }
                
                if let aliasList = aliasesViewModel.aliasList{
                    Section {
                        
                        
                        if horizontalSize == .regular { // iPad and larger devices
                            
                            //TODO: make iPad layout
                            
                            ForEach(aliasList.data) { alias in
                                createAliasRow(alias: alias)
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            if let index = aliasList.data.firstIndex(of: alias) {
                                                if alias.deleted_at != nil {
                                                    forgetAlias(at: IndexSet(integer: index))
                                                } else {
                                                    deleteAlias(at: IndexSet(integer: index))
                                                }
                                            }
                                        } label: {
                                            if alias.deleted_at != nil {
                                                Text(String(localized: "forget"))
                                            } else {
                                                Text(String(localized: "delete"))
                                            }
                                            
                                        }
                                    }
                            }
                            
                            
                            //                            let columns = Array(repeating: GridItem(.flexible(), spacing: 20), count: 2)
                            //                            LazyVGrid(columns: columns, spacing: 20) {
                            //                                ForEach(aliasList.data) { alias in
                            //                                    createAliasRow(alias: alias)
                            //                                }.onDelete(perform: deleteAlias)
                            //                            }
                        } else { // iPhone and smaller devices
                            ForEach(aliasList.data) { alias in
                                createAliasRow(alias: alias)
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            if let index = aliasList.data.firstIndex(of: alias) {
                                                if alias.deleted_at != nil {
                                                    forgetAlias(at: IndexSet(integer: index))
                                                } else {
                                                    deleteAlias(at: IndexSet(integer: index))
                                                }
                                            }
                                        } label: {
                                            if alias.deleted_at != nil {
                                                Text(String(localized: "forget"))
                                            } else {
                                                Text(String(localized: "delete"))
                                            }
                                            
                                        }
                                    }
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
                            .task {
                                aliasesViewModel.loadMoreContent()
                            }
                    }
                    
                }
                
            }
            .overlay {
                ToastOverlay(showToast: $copiedToClipboard, text: String(localized: "copied_to_clipboard"))
            }
            .refreshable {
                // When refreshing aliases also ask the mainView to update general data
                self.onRefreshGeneralData?()
                await self.aliasesViewModel.getAliases(forceReload: true)
            }
            .confirmationDialog(String(localized: "send_mail"), isPresented: $isPresentingEmailSelectionDialog) {
                ForEach(clients, id: \.self) { item in
                    Button(item.name) {
                        self.onPressSend(client: item, sendToRecipients: self.sendToRecipients ?? "")
                    }
                }
                
                Button(String(localized: "cancel"), role: .cancel) { }
            } message: {
                Text(String(localized: "select_mail_client"))
            }
            
            .alert(isPresented: $showAlert) {
                switch activeAlert {
                case .reachedMaxAliases:
                    return Alert(title: Text(String(localized: "aliaswatcher_max_reached")), message: Text(String(localized: "aliaswatcher_max_reached_desc")), dismissButton: .default(Text(String(localized: "understood"))))
                case .deleteAlias:
                    return Alert(title: Text(String(localized: "delete_alias")), message: Text(String(localized: "delete_alias_confirmation_desc")), primaryButton: .destructive(Text(String(localized: "delete"))){
                        
                        Task {
                            await self.deleteAlias(alias: aliasInContextMenu!)
                        }
                    }, secondaryButton: .cancel(){
                        Task {
                            await aliasesViewModel.getAliases(forceReload: true)
                        }
                    })
                case .forgetAlias:
                    return Alert(title: Text(String(localized: "forget_alias")), message: Text(String(localized: "forget_alias_confirmation_desc")), primaryButton: .destructive(Text(String(localized: "forget"))){
                        self.activeAlert = .forgetAliasConfirmation
                        // Workaround
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.showAlert = true
                        }
                    }, secondaryButton: .cancel(){
                        Task {
                            await aliasesViewModel.getAliases(forceReload: true)
                        }
                    })
                case .forgetAliasConfirmation:
                    return Alert(title: Text(String(localized: "forget_alias")), message: Text(String(localized: "forget_alias_are_you_sure_confirmation_desc")), primaryButton: .destructive(Text(String(localized: "forget"))){
                        
                        Task {
                            await self.forgetAlias(alias: aliasInContextMenu!)
                        }
                    }, secondaryButton: .cancel(){
                        Task {
                            await aliasesViewModel.getAliases(forceReload: true)
                        }
                    })
                case .restoreAlias:
                    return Alert(title: Text(String(localized: "restore_alias")), message: Text(String(localized: "restore_alias_confirmation_desc")), primaryButton: .default(Text(String(localized: "restore"))){
                        
                        Task {
                            await self.restoreAlias(alias: aliasInContextMenu!)
                        }
                    }, secondaryButton: .cancel(){
                        Task {
                            await aliasesViewModel.getAliases(forceReload: true)
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
                                Task {
                                    await aliasesViewModel.getAliases(forceReload: true)
                                }
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
            .toolbar {
                ProfilePicture().environmentObject(mainViewState)
                FailedDeliveriesIcon(horizontalSize: $horizontalSize).environmentObject(mainViewState)
            }
            .navigationBarItems(trailing: HStack{
                Button(action: {
                    mainViewState.showAddAliasBottomSheet = true
                } ) {
                    Image(systemName: "plus")
                        .frame(width: 24, height: 24)
                }
            })
            
            .searchable(text: $aliasesViewModel.searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: String(localized: "aliases_search"))
            .onSubmit(of: .search) {
                aliasesViewModel.searchAliases(searchQuery: aliasesViewModel.searchQuery)
            }
            .autocorrectionDisabled(true)
            .textInputAutocapitalization(.never)
            .navigationDestination(item: $mainViewState.aliasToDisable, destination: { aliasToDisable in
                NavigationStack(){
                    AliasDetailView(aliasId: aliasToDisable, aliasEmail: nil, shouldReloadDataInParent: nil, shouldDisableAlias: true)
                        .environmentObject(mainViewState)
                }
            })
            .navigationDestination(item: $mainViewState.showAliasWithId, destination: { showAliasWithId in
                NavigationStack(){
                    AliasDetailView(aliasId: showAliasWithId, aliasEmail: nil, shouldReloadDataInParent: nil)
                        .environmentObject(mainViewState)
                }
            })
            .sheet(isPresented: $isPresentingFilterOptionsAliasBottomSheet) {
                NavigationStack {
                    FilterOptionsAliasBottomSheet(aliasSortFilterRequest: self.aliasesViewModel.aliasSortFilterRequest){ aliasSortFilterRequest in
                        // This will also reload new filter in memory
                        SaveFilter(chipId: "filter_custom", aliasSortFilterRequest: aliasSortFilterRequest)
                        
                        // Hide dialog and refresh aliases
                        isPresentingFilterOptionsAliasBottomSheet = false
                        
                        Task {
                            await aliasesViewModel.getAliases(forceReload: true)
                        }
                    }
                }
                .presentationDetents([.large])
            }
            .sheet(item: $aliasToSendMailFrom) { alias in
                NavigationStack {
                    EditAliasSendMailRecipientBottomSheet(aliasEmail: alias.email) { addresses in
                        self.onPressSend(client:nil, sendToRecipients: addresses)
                    }
                }
                .presentationDetents([.large])
                
            }
            .sheet(isPresented: $mainViewState.showAddAliasBottomSheet) {
                NavigationStack {
                    AddAliasBottomSheet(){
                        // Hide dialog and refresh aliases
                        mainViewState.showAddAliasBottomSheet = false
                        showCopiedToClipboardAnimation()
                        
                        Task {
                            await aliasesViewModel.getAliases(forceReload: true)
                        }
                    }.environmentObject(mainViewState)
                    
                }
                .presentationDetents([.large])
            }
        }.onAppear(perform: {
            // Get the available mail clients
            self.clients = ThirdPartyMailClient.clients.filter( {ThirdPartyMailer.isMailClientAvailable($0)})
            self.clients.append(ThirdPartyMailClient.systemDefault)
            
            LoadFilter()
            
            if let aliasList = aliasesViewModel.aliasList{
                if (aliasList.data.isEmpty) {
                    Task {
                        await aliasesViewModel.getAliases(forceReload: true)
                    }
                }
            } else {
                Task {
                    await aliasesViewModel.getAliases(forceReload: true)
                }
            }
            
        })
        
        
        
    }
    
    @ViewBuilder
    func createAliasRow(alias: Aliases) -> some View {
        ZStack {
            AliasRowView(alias: alias,isPreview: false)
                .listRowBackground(Color.clear)
                .contextMenu {
                    Button {
                        UIPasteboard.general.setValue(alias.email,forPasteboardType: UTType.plainText.identifier)
                        showCopiedToClipboardAnimation()
                        
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
                                Task {
                                    await self.deactivateAlias(alias: alias)
                                }                                            } label: {
                                    Label(String(localized: "deactivate_alias"), systemImage: "hand.raised")
                                }
                        } else {
                            
                            Button {
                                Task {
                                    await self.activateAlias(alias: alias)
                                }
                            } label: {
                                Label(String(localized: "activate_alias"), systemImage: "checkmark.circle")
                            }
                        }
                        
                        Button(role: .destructive) {
                            self.activeAlert = .deleteAlias
                            self.showAlert = true
                        } label: {
                            Label(String(localized: "delete_alias"), systemImage: "trash")
                        }
                    }
                    
                } preview:
            {
                AliasRowView(alias: alias, isPreview: true).onAppear {
                    self.aliasInContextMenu = alias
                }.frame(minWidth: 350, idealWidth: 350, maxWidth: 350, minHeight: 200, idealHeight: 200, maxHeight: 200, alignment: .center)
            }
            
            
            NavigationLink(destination: AliasDetailView(aliasId: alias.id, aliasEmail: alias.email, shouldReloadDataInParent: $shouldReloadDataInParent)
                .environmentObject(mainViewState)){
                    EmptyView().onTapGesture {
                        // Dismiss the search controller when a result is selected
                        aliasesViewModel.searchQuery = ""
                    }
                }
                .opacity(0)
                .onChange(of: shouldReloadDataInParent) {
                    if shouldReloadDataInParent {
                        Task {
                            await aliasesViewModel.getAliases(forceReload: true)
                        }
                        self.shouldReloadDataInParent = false
                    }
                }
                .swipeActions(edge: .leading) {
                    Button {
                        UIPasteboard.general.setValue(alias.email,forPasteboardType: UTType.plainText.identifier)
                        showCopiedToClipboardAnimation()
                        
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
    }
    
    func showCopiedToClipboardAnimation(){
        withAnimation(.snappy) {
            copiedToClipboard = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.snappy) {
                copiedToClipboard = false
            }
        }
    }
    
    func ApplyFilter(chipId: String){
        
        
        switch (chipId){
        case "filter_all_aliases":
            aliasesViewModel.aliasSortFilterRequest.onlyWatchedAliases = false
            aliasesViewModel.aliasSortFilterRequest.onlyActiveAliases = false
            aliasesViewModel.aliasSortFilterRequest.onlyInactiveAliases = false
            aliasesViewModel.aliasSortFilterRequest.onlyDeletedAliases = false
            aliasesViewModel.aliasSortFilterRequest.sort = nil
            aliasesViewModel.aliasSortFilterRequest.sortDesc = false
        case "filter_active_aliases":
            aliasesViewModel.aliasSortFilterRequest.onlyWatchedAliases = false
            aliasesViewModel.aliasSortFilterRequest.onlyActiveAliases = true
            aliasesViewModel.aliasSortFilterRequest.onlyInactiveAliases = false
            aliasesViewModel.aliasSortFilterRequest.onlyDeletedAliases = false
            aliasesViewModel.aliasSortFilterRequest.sort = nil
            aliasesViewModel.aliasSortFilterRequest.sortDesc = false
        case "filter_inactive_aliases":
            aliasesViewModel.aliasSortFilterRequest.onlyWatchedAliases = false
            aliasesViewModel.aliasSortFilterRequest.onlyActiveAliases = false
            aliasesViewModel.aliasSortFilterRequest.onlyInactiveAliases = true
            aliasesViewModel.aliasSortFilterRequest.onlyDeletedAliases = false
            aliasesViewModel.aliasSortFilterRequest.sort = nil
            aliasesViewModel.aliasSortFilterRequest.sortDesc = false
        case "filter_deleted_aliases":
            aliasesViewModel.aliasSortFilterRequest.onlyWatchedAliases = false
            aliasesViewModel.aliasSortFilterRequest.onlyActiveAliases = false
            aliasesViewModel.aliasSortFilterRequest.onlyInactiveAliases = false
            aliasesViewModel.aliasSortFilterRequest.onlyDeletedAliases = true
            aliasesViewModel.aliasSortFilterRequest.sort = nil
            aliasesViewModel.aliasSortFilterRequest.sortDesc = false
        case "filter_watched_only":
            aliasesViewModel.aliasSortFilterRequest.onlyWatchedAliases = true
            aliasesViewModel.aliasSortFilterRequest.onlyActiveAliases = false
            aliasesViewModel.aliasSortFilterRequest.onlyInactiveAliases = false
            aliasesViewModel.aliasSortFilterRequest.onlyDeletedAliases = false
            aliasesViewModel.aliasSortFilterRequest.sort = nil
            aliasesViewModel.aliasSortFilterRequest.sortDesc = false
        case "filter_custom":
            isPresentingFilterOptionsAliasBottomSheet = true
            return // Nothing to save yet so let's return
            
        default:
            aliasesViewModel.aliasSortFilterRequest.onlyWatchedAliases = false
            aliasesViewModel.aliasSortFilterRequest.onlyActiveAliases = false
            aliasesViewModel.aliasSortFilterRequest.onlyInactiveAliases = false
            aliasesViewModel.aliasSortFilterRequest.onlyDeletedAliases = false
        }
        
        
        SaveFilter(chipId: chipId, aliasSortFilterRequest: aliasesViewModel.aliasSortFilterRequest)
        
        Task {
            await aliasesViewModel.getAliases(forceReload: true)
        }
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
    
    
    
    private func onPressSend(client: ThirdPartyMailClient? = nil, sendToRecipients: String) {
        
        // aliasToSendMailFrom will be set to nil when the EditAliasSendMailRecipientBottomSheet gets dismissed, therefore we make a copy of the item and
        // return if both are nil
        guard let alias = aliasToSendMailFrom ?? aliasToSendMailFromCopy else {return}
        
        
        if client == nil {
            isPresentingEmailSelectionDialog = true
            self.sendToRecipients = sendToRecipients
            self.aliasToSendMailFromCopy = alias
        } else {
            // Get recipients
            let recipients = AnonAddyUtils.getSendAddress(recipientEmails: sendToRecipients.split(separator: ",").map { String($0) }, alias: alias)
            
            // Copy the email addresses to clipboard
            UIPasteboard.general.setValue(recipients.joined(separator: ";"),forPasteboardType: UTType.plainText.identifier)
            showCopiedToClipboardAnimation()
            
            // Prepare mailto URL
            let mailtoURL = client!.composeURL(to: recipients)
            
            // Open mailto URL
            UIApplication.shared.open(mailtoURL)
            
            // Set aliasToSendMailFromCopy to nil
            aliasToSendMailFromCopy = nil
            
        }
    }
    
    private func activateAlias(alias: Aliases) async {
        let networkHelper = NetworkHelper()
        do {
            let _ = try await networkHelper.activateSpecificAlias(aliasId: alias.id)
            await aliasesViewModel.getAliases(forceReload: true)
        } catch {
            activeAlert = .error
            showAlert = true
            errorAlertTitle = String(localized: "error_forgetting_alias")
            errorAlertMessage = error.localizedDescription
        }
    }
    
    private func deactivateAlias(alias: Aliases) async {
        let networkHelper = NetworkHelper()
        do {
            let result = try await networkHelper.deactivateSpecificAlias(aliasId: alias.id)
            if result == "204" {
                await aliasesViewModel.getAliases(forceReload: true)
            } else {
                activeAlert = .error
                showAlert = true
                errorAlertTitle = String(localized: "error_forgetting_alias")
                errorAlertMessage = result
            }
        } catch {
            activeAlert = .error
            showAlert = true
            errorAlertTitle = String(localized: "error_forgetting_alias")
            errorAlertMessage = error.localizedDescription
        }
    }
    
    private func deleteAlias(alias: Aliases) async {
        let networkHelper = NetworkHelper()
        do {
            let result = try await networkHelper.deleteAlias(aliasId: alias.id)
            if result == "204" {
                await aliasesViewModel.getAliases(forceReload: true)
            } else {
                activeAlert = .error
                showAlert = true
                errorAlertTitle = String(localized: "error_forgetting_alias")
                errorAlertMessage = result
            }
        } catch {
            activeAlert = .error
            showAlert = true
            errorAlertTitle = String(localized: "error_forgetting_alias")
            errorAlertMessage = error.localizedDescription
        }
        
        
    }
    
    private func forgetAlias(alias: Aliases) async {
        let networkHelper = NetworkHelper()
        do {
            let result = try await networkHelper.forgetAlias(aliasId: alias.id)
            if result == "204" {
                await aliasesViewModel.getAliases(forceReload: true)
            } else {
                activeAlert = .error
                showAlert = true
                errorAlertTitle = String(localized: "error_deleting_alias")
                errorAlertMessage = result
            }
        } catch {
            activeAlert = .error
            showAlert = true
            errorAlertTitle = String(localized: "error_deleting_alias")
            errorAlertMessage = error.localizedDescription
        }
    }

        
        
    private func deleteAlias(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            
            if let aliases = aliasesViewModel.aliasList?.data {
                let item = aliases[index]
                aliasInContextMenu = item
                
                activeAlert = .deleteAlias
                showAlert = true
                
                // Remove from the collection for the smooth animation
                aliasesViewModel.aliasList?.data.remove(atOffsets: offsets)
            }
        }
    }
    
    private func forgetAlias(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            
            if let aliases = aliasesViewModel.aliasList?.data {
                let item = aliases[index]
                aliasInContextMenu = item
                
                activeAlert = .forgetAlias
                showAlert = true
                
                // Remove from the collection for the smooth animation
                aliasesViewModel.aliasList?.data.remove(atOffsets: offsets)
            }
        }
    }
    
    private func restoreAlias(alias: Aliases) async {
        let networkHelper = NetworkHelper()
        do {
            let restoredAlias = try await networkHelper.restoreAlias(aliasId: alias.id)
            if restoredAlias != nil {
                await aliasesViewModel.getAliases(forceReload: true)
            } else {
                activeAlert = .error
                showAlert = true
                errorAlertTitle = String(localized: "error_restoring_alias")
                errorAlertMessage = String(localized: "error_unknown_refer_to_logs")
            }
        } catch {
            activeAlert = .error
            showAlert = true
            errorAlertTitle = String(localized: "error_restoring_alias")
            errorAlertMessage = error.localizedDescription
        }
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
