//
//  UsernamesDetailView.swift
//  addy
//
//  Created by Stijn van de Water on 08/05/2024.
//

import SwiftUI
import addy_shared
import Lottie
import UniformTypeIdentifiers

struct UsernamesDetailView: View {
    
    enum ActiveAlert {
        case deleteUsername, error
    }
    
    let usernameId: String
    let usernameUsername: String

    
    @Binding var shouldReloadDataInParent: Bool

    
    @State private var activeAlert: ActiveAlert = .deleteUsername
    @State private var showAlert: Bool = false
    @State private var isDeletingUsername: Bool = false
    
    @State private var errorAlertTitle = ""
    @State private var errorAlertMessage = ""
    @EnvironmentObject var mainViewState: MainViewState
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @State private var username: Usernames? = nil
    @State private var errorText: String? = nil
    
    @State private var isActive: Bool = false
    @State private var catchAllEnabled: Bool = false
    @State private var canLogin: Bool = false
    @State private var isSwitchingisActiveState: Bool = false
    @State private var isSwitchingCatchAllEnabledState: Bool = false
    @State private var isSwitchingCanLoginState: Bool = false
    
    @State private var isPresentingEditUsernameDescriptionBottomSheet: Bool = false
    @State private var isPresentingEditUsernameFromNameBottomSheet: Bool = false
    @State private var isPresentingEditUsernameRecipientsBottomSheet: Bool = false
    @State private var isPresentingEditUsernameAutoCreateRegexBottomSheet: Bool = false
    
    @State private var aliasList: [String] = []
 
    @State private var totalForwarded: Int = 0
    @State private var totalBlocked: Int = 0
    @State private var totalReplies: Int = 0
    @State private var totalSent: Int = 0
    
    
    
    init(usernameId: String, usernameUsername: String, shouldReloadDataInParent: Binding<Bool>) {
        self.usernameId = usernameId
        self.usernameUsername = usernameUsername
        _shouldReloadDataInParent = shouldReloadDataInParent
    }
    
    
    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
        if let username = username {
            Form {
                
                
                Section {
                    Text(String(format: String(localized: "manage_username_basic_info"),
                                username.username,
                                DateTimeUtils.turnStringIntoLocalString(username.created_at),
                                DateTimeUtils.turnStringIntoLocalString(username.updated_at),
                                String(totalForwarded), String(totalBlocked), String(totalReplies), String(totalSent)))
                    
                    
                }header: {
                    Text(String(localized: "basic"))
                }
                
                Section {
                    Text(aliasList.joined(separator: "\n"))
                        .font(.system(size: 14)) // Set initial font size
                        .minimumScaleFactor(0.5) // Set minimum scale factor to resize text
                        .padding(.top, 5)
                    
                    
                } header: {
                    Text(String(format: String(localized: "username_aliases_d"),
                                String(username.aliases_count ?? 0)))
                }
                
            
                Section {
                    
                    AddyToggle(isOn: $isActive, isLoading: isSwitchingisActiveState, title: username.active ? String(localized: "username_activated") : String(localized: "username_deactivated"), description: String(localized: "username_status_desc"))
                        .onAppear {
                            self.isActive = username.active
                        }
                        .onChange(of: isActive) {
                            // Only fire when the value is NOT the same as the value already in the model
                            if (isActive != username.active){
                                self.isSwitchingisActiveState = true
                                
                                if (username.active){
                                    Task {
                                        await self.deactivateUsername(username: username)
                                    }
                                } else {
                                    Task {
                                        await self.activateUsername(username: username)
                                    }
                                }
                            }
                            
                        }
                    
                    AddyToggle(isOn: $catchAllEnabled, isLoading: isSwitchingCatchAllEnabledState, title: username.catch_all ? String(localized: "catch_all_enabled") : String(localized: "catch_all_disabled"), description: String(localized: "catch_all_username_desc"))
                        .onAppear {
                            self.catchAllEnabled = username.catch_all
                        }
                        .onChange(of: catchAllEnabled) {
                            // Only fire when the value is NOT the same as the value already in the model
                            if (catchAllEnabled != username.catch_all){
                                self.isSwitchingCatchAllEnabledState = true
                                
                                if (username.catch_all){
                                    Task {
                                        await self.disableCatchAll(username: username)
                                    }
                                } else {
                                    Task {
                                        await self.enableCatchAll(username: username)
                                    }
                                }
                            }
                            
                        }
                    
                    
                    AddyToggle(isOn: $canLogin, isLoading: isSwitchingCanLoginState, title: username.can_login ? String(localized: "can_login_enabled") : String(localized: "can_login_disabled"), description: String(localized: "can_login_username_desc"))
                        .onAppear {
                            self.canLogin = username.can_login
                        }
                        .onChange(of: canLogin) {
                            // Only fire when the value is NOT the same as the value already in the model
                            if (canLogin != username.can_login){
                                self.isSwitchingCanLoginState = true
                                
                                if (username.can_login){
                                    Task {
                                        await self.disableCanLogin(username: username)
                                    }
                                } else {
                                    Task {
                                        await self.enableCanLogin(username: username)
                                    }
                                }
                            }
                            
                        }
                    
                    AddySection(title: String(localized: "description"), description: username.description ?? String(localized: "username_no_description"), leadingSystemimage: nil, trailingSystemimage: "pencil"){
                            isPresentingEditUsernameDescriptionBottomSheet = true
                        }
                    
                    AddySection(title: String(localized: "from_name"), description: getFromName(username: username), leadingSystemimage: nil, trailingSystemimage: "pencil"){
                            if !mainViewState.userResource!.hasUserFreeSubscription(){
                                isPresentingEditUsernameFromNameBottomSheet = true
                            } else {
                                HapticHelper.playHapticFeedback(hapticType: .error)
                            }
                        }
                     AddySection(title: String(localized: "auto_create_regex"), description: getAutoCreateRegex(username: username), leadingSystemimage: nil, trailingSystemimage: "pencil"){
                            if !mainViewState.userResource!.hasUserFreeSubscription(){
                                isPresentingEditUsernameAutoCreateRegexBottomSheet = true
                            } else {
                                HapticHelper.playHapticFeedback(hapticType: .error)
                            }
                        }
                    
                    AddySection(title: String(localized: "recipients"), description: getDefaultRecipient(username: username), leadingSystemimage: nil, trailingSystemimage: "pencil"){
                            isPresentingEditUsernameRecipientsBottomSheet = true
                        }
                    
                    
                } header: {
                    Text(String(localized: "actions"))
                }
                
                Section {
                    AddySectionButton(title: String(localized: "delete_username"), description: String(localized: "delete_username_desc"),
                                      leadingSystemimage: "trash", colorAccent: .softRed, isLoading: isDeletingUsername){
                        activeAlert = .deleteUsername
                        showAlert = true
                    }
                }
                
            }.disabled(isDeletingUsername)
                .navigationTitle(self.usernameUsername)
                .navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $isPresentingEditUsernameDescriptionBottomSheet) {
                    NavigationStack {
                        EditUsernameDescriptionBottomSheet(usernameId: username.id, description: username.description ?? ""){ username in
                            self.username = username
                            isPresentingEditUsernameDescriptionBottomSheet = false
                            
                            // This changes the last updated time of the alias which is being shown in the list in the aliasesView.
                            // So we update the list when coming back
                            shouldReloadDataInParent = true

                        }
                    }
                    .presentationDetents([.large])
                }
                .sheet(isPresented: $isPresentingEditUsernameFromNameBottomSheet) {
                    NavigationStack {
                        EditUsernameFromNameBottomSheet(usernameId: username.id, username: username.username, fromName: username.from_name){ username in
                            self.username = username
                            isPresentingEditUsernameFromNameBottomSheet = false
                            
                            // This changes the last updated time of the alias which is being shown in the list in the aliasesView.
                            // So we update the list when coming back
                            shouldReloadDataInParent = true

                        }
                    }
                    .presentationDetents([.large])
                }
                .sheet(isPresented: $isPresentingEditUsernameAutoCreateRegexBottomSheet) {
                    NavigationStack {
                        EditUsernameAutoCreateRegexBottomSheet(usernameId: username.id, username: username.username, autoCreateRegex: username.auto_create_regex){ username in
                            self.username = username
                            isPresentingEditUsernameAutoCreateRegexBottomSheet = false
                            
                            // This changes the last updated time of the alias which is being shown in the list in the aliasesView.
                            // So we update the list when coming back
                            shouldReloadDataInParent = true

                        }
                    }
                    .presentationDetents([.large])
                }
                .sheet(isPresented: $isPresentingEditUsernameRecipientsBottomSheet) {
                    NavigationStack {
                        EditUsernameRecipientsBottomSheet(usernameId: username.id, selectedRecipientId: username.default_recipient?.id) { username in
                            self.username = username
                            isPresentingEditUsernameRecipientsBottomSheet = false
                            
                            // This changes the last updated time of the alias which is being shown in the list in the aliasesView.
                            // So we update the list when coming back
                            shouldReloadDataInParent = true
                        }
                    }
                    .presentationDetents([.medium, .large])
                }
            
            

                .alert(isPresented: $showAlert) {
                            switch activeAlert {
                           case .deleteUsername:
                                return Alert(title: Text(String(localized: "delete_username")), message: Text(String(localized: "delete_username_confirmation_desc")), primaryButton: .destructive(Text(String(localized: "delete"))){
                                    isDeletingUsername = true
    
                                    Task {
                                        await deleteUsername(username: username)
                                    }
                                }, secondaryButton: .cancel())
                            case .error:
                                return Alert(
                                    title: Text(errorAlertTitle),
                                    message: Text(errorAlertMessage)
                                )
                            }
                        }
    
        } else {
            
            VStack {
                if let errorText = errorText
                {
                    ContentUnavailableView {
                        Label(String(localized: "error_obtaining_username"), systemImage: "questionmark")
                    } description: {
                        Text(errorText)
                    }.onAppear{
                        HapticHelper.playHapticFeedback(hapticType: .error)
                    }
                } else {
                    VStack(spacing: 20) {
                        LottieView(animation: .named("gray_ic_loading_logo.shapeshifter"))
                            .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                            .animationSpeed(Double(2))
                            .frame(maxHeight: 128)
                            .opacity(0.5)
                        
                    }
                }
            }.task {
                await getUsername(usernameId: self.usernameId)
            }
            .navigationTitle(self.usernameUsername)
            .navigationBarTitleDisplayMode(.inline)
        }
        
    }
    
    private func getDefaultRecipient(username: Usernames) -> String {
        if (username.default_recipient != nil) {
            return username.default_recipient!.email
        } else {
            return String(format: String(localized: "default_recipient_s"), mainViewState.userResourceExtended!.default_recipient_email)
        }
    }
    
    
    private func activateUsername(username: Usernames) async {
        let networkHelper = NetworkHelper()
        do {
            let activatedUsername = try await networkHelper.activateSpecificUsername(usernameId: username.id)
            self.isSwitchingisActiveState = false
            self.username = activatedUsername
            self.isActive = true
        } catch {
            self.isSwitchingisActiveState = false
            self.isActive = false
            activeAlert = .error
            showAlert = true
            errorAlertTitle = String(localized: "error_edit_active")
            errorAlertMessage = error.localizedDescription
        }
    }

    private func deactivateUsername(username: Usernames) async {
        let networkHelper = NetworkHelper()
        do {
            let result = try await networkHelper.deactivateSpecificUsername(usernameId: username.id)
            self.isSwitchingisActiveState = false
            if result == "204" {
                self.username?.active = false
                self.isActive = false
            } else {
                self.isActive = true
                activeAlert = .error
                showAlert = true
                errorAlertTitle = String(localized: "error_edit_active")
                errorAlertMessage = result
            }
        } catch {
            self.isSwitchingisActiveState = false
            self.isActive = true
            activeAlert = .error
            showAlert = true
            errorAlertTitle = String(localized: "error_edit_active")
            errorAlertMessage = error.localizedDescription
        }
    }

    
    private func enableCatchAll(username: Usernames) async {
        let networkHelper = NetworkHelper()
        do {
            let enabledUsername = try await networkHelper.enableCatchAllSpecificUsername(usernameId: username.id)
            self.isSwitchingCatchAllEnabledState = false
            self.username = enabledUsername
            self.catchAllEnabled = true
        } catch {
            self.isSwitchingCatchAllEnabledState = false
            self.catchAllEnabled = false
            activeAlert = .error
            showAlert = true
            errorAlertTitle = String(localized: "error_edit_catch_all")
            errorAlertMessage = error.localizedDescription
        }
    }

    
    private func disableCatchAll(username: Usernames) async {
        let networkHelper = NetworkHelper()
        do {
            let result = try await networkHelper.disableCatchAllSpecificUsername(usernameId: username.id)
            self.isSwitchingCatchAllEnabledState = false
            if result == "204" {
                self.username?.catch_all = false
                self.catchAllEnabled = false
            } else {
                self.catchAllEnabled = true
                activeAlert = .error
                showAlert = true
                errorAlertTitle = String(localized: "error_edit_catch_all")
                errorAlertMessage = result
            }
        } catch {
            self.isSwitchingCatchAllEnabledState = false
            self.catchAllEnabled = true
            activeAlert = .error
            showAlert = true
            errorAlertTitle = String(localized: "error_edit_catch_all")
            errorAlertMessage = error.localizedDescription
        }
    }

          
    private func enableCanLogin(username: Usernames) async {
        let networkHelper = NetworkHelper()
        do {
            let enabledUsername = try await networkHelper.enableCanLoginSpecificUsername(usernameId: username.id)
            self.isSwitchingCanLoginState = false
            self.username = enabledUsername
            self.canLogin = true
        } catch {
            self.isSwitchingCanLoginState = false
            self.canLogin = false
            activeAlert = .error
            showAlert = true
            errorAlertTitle = String(localized: "error_edit_can_login")
            errorAlertMessage = error.localizedDescription
        }
    }

    
    private func disableCanLogin(username: Usernames) async {
        let networkHelper = NetworkHelper()
        do {
            let result = try await networkHelper.disableCanLoginSpecificUsername(usernameId: username.id)
            self.isSwitchingCanLoginState = false
            if result == "204" {
                self.username?.can_login = false
                self.canLogin = false
            } else {
                self.canLogin = true
                activeAlert = .error
                showAlert = true
                errorAlertTitle = String(localized: "error_edit_can_login")
                errorAlertMessage = result
            }
        } catch {
            self.isSwitchingCanLoginState = false
            self.canLogin = true
            activeAlert = .error
            showAlert = true
            errorAlertTitle = String(localized: "error_edit_can_login")
            errorAlertMessage = error.localizedDescription
        }
    }

    
   
    
    private func updateUi(aliasesArray: AliasesArray?){
        
        if let aliasesArray = aliasesArray {
            let sortedAliasesData = aliasesArray.data.sorted(by: { $0.email < $1.email })
            
            aliasList = sortedAliasesData.map { alias in
                totalForwarded += alias.emails_forwarded
                totalBlocked += alias.emails_blocked
                totalReplies += alias.emails_replied
                totalSent += alias.emails_sent
                return alias.email
            }
            
            
        }
    }
    
    private func getFromName(username: Usernames) -> String {
        
        
        if mainViewState.userResource!.hasUserFreeSubscription() {
            return String(localized: "feature_not_available_subscription")
        }
        else {
            // Set description based on alias.from_name and initialize the bottom dialog fragment
            if let fromName = username.from_name {
                return fromName
            } else {
                return String(localized: "username_no_from_name")
            }
        }
        
    }
        private func getAutoCreateRegex(username: Usernames) -> String {
        
        
        if mainViewState.userResource!.hasUserFreeSubscription() {
            return String(localized: "feature_not_available_subscription")
        }
        else {
            // Set description based on alias.auto_create_regex and initialize the bottom dialog fragment
            if let autoCreateRegex = username.auto_create_regex {
                return autoCreateRegex
            } else {
                return String(localized: "username_no_auto_create_regex")
            }
        }
        
    }
    
    
    private func deleteUsername(username: Usernames) async {
        let networkHelper = NetworkHelper()
        do {
            let result = try await networkHelper.deleteUsername(usernameId: username.id)
            self.isDeletingUsername = false
            if result == "204" {
                shouldReloadDataInParent = true
                self.presentationMode.wrappedValue.dismiss()
            } else {
                activeAlert = .error
                showAlert = true
                errorAlertTitle = String(localized: "error_deleting_username")
                errorAlertMessage = result
            }
        } catch {
            self.isDeletingUsername = false
            activeAlert = .error
            showAlert = true
            errorAlertTitle = String(localized: "error_deleting_username")
            errorAlertMessage = error.localizedDescription
        }
    }

    
    
    
    private func getUsername(usernameId: String) async {
        let networkHelper = NetworkHelper()
        do {
            if let username = try await networkHelper.getSpecificUsername(usernameId: usernameId){
                withAnimation {
                    self.username = username
                }
                await getAliasesAndAddThemToList(username: username)
            }
        } catch {
            withAnimation {
                self.errorText = error.localizedDescription
            }
        }
    }

    
    private func getAliasesAndAddThemToList(username: Usernames, workingAliasList: AliasesArray? = nil) async {
        let networkHelper = NetworkHelper()
        let aliasSortFilterRequest = AliasSortFilterRequest(onlyActiveAliases: false, onlyDeletedAliases: false, onlyInactiveAliases: false, onlyWatchedAliases: false, sort: nil, sortDesc: false, filter: nil)
        do {
            if let list = try await networkHelper.getAliases(aliasSortFilterRequest: aliasSortFilterRequest, page: (workingAliasList?.meta?.current_page ?? 0) + 1, size: 100, username: usernameId){
                addAliasesToList(username: username, aliasesArray: list, workingAliasListInbound: workingAliasList)
            }
        } catch {
                withAnimation {
                    self.errorText = error.localizedDescription
                }
            
        }
    }

    
    
    // Function to add aliases to the list
    func addAliasesToList(username: Usernames, aliasesArray: AliasesArray, workingAliasListInbound: AliasesArray? = nil) {
        var workingAliasList = workingAliasListInbound

        // If the aliasList is nil, completely set it
        if workingAliasList == nil {
            workingAliasList = aliasesArray
        } else {
            // If not, update meta, links and append aliases
            workingAliasList?.meta = aliasesArray.meta
            workingAliasList?.links = aliasesArray.links
            workingAliasList?.data.append(contentsOf: aliasesArray.data)
        }
        
        // Check if there are more aliases to obtain (are there more pages)
        // If so, repeat.
        if (workingAliasList?.meta?.current_page ?? 0) < (workingAliasList?.meta?.last_page ?? 0) {
            Task {
                await getAliasesAndAddThemToList(username: username, workingAliasList: workingAliasList)
            }
        } else {
                // Else, set aliasList to update UI
                updateUi(aliasesArray: workingAliasList)
            
        }
    }
    
}

//
//#Preview {
//    UsernamesDetailView(usernameId: "6a866f49-5a0b-4c7e-bc45-f46bf019c4ed", usernameEmail: "PLACEHOLDER")
//}
