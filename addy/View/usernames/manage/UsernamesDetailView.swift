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
                                    DispatchQueue.global(qos: .background).async {
                                        self.deactivateUsername(username: username)
                                    }
                                } else {
                                    DispatchQueue.global(qos: .background).async {
                                        self.activateUsername(username: username)
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
                                    DispatchQueue.global(qos: .background).async {
                                        self.disableCatchAll(username: username)
                                    }
                                } else {
                                    DispatchQueue.global(qos: .background).async {
                                        self.enableCatchAll(username: username)
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
                                    DispatchQueue.global(qos: .background).async {
                                        self.disableCanLogin(username: username)
                                    }
                                } else {
                                    DispatchQueue.global(qos: .background).async {
                                        self.enableCanLogin(username: username)
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
    
                                    DispatchQueue.global(qos: .background).async {
                                        deleteUsername(username: username)
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
                getUsername(usernameId: self.usernameId)
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
    
    
    private func activateUsername(username:Usernames) {
        let networkHelper = NetworkHelper()
        networkHelper.activateSpecificUsername(completion: { username, result in
            DispatchQueue.main.async {
                self.isSwitchingisActiveState = false
                
                if let username = username {
                    self.username = username
                    self.isActive = true
                } else {
                    self.isActive = false
                    activeAlert = .error
                    showAlert = true
                    errorAlertTitle = String(localized: "error_edit_active")
                    errorAlertMessage = result ?? String(localized: "error_unknown_refer_to_logs")
                }
            }
        },usernameId: username.id)
    }
    
    private func deactivateUsername(username:Usernames) {
        let networkHelper = NetworkHelper()
        networkHelper.deactivateSpecificUsername(completion: { result in
            DispatchQueue.main.async {
                self.isSwitchingisActiveState = false
                
                if result == "204" {
                    self.username?.active = false
                    self.isActive = false
                } else {
                    self.isActive = true
                    activeAlert = .error
                    showAlert = true
                    errorAlertTitle = String(localized: "error_edit_active")
                    errorAlertMessage = result ?? String(localized: "error_unknown_refer_to_logs")
                }
            }
        },usernameId: username.id)
    }     
       private func enableCatchAll(username:Usernames) {
        let networkHelper = NetworkHelper()
        networkHelper.enableCatchAllSpecificUsername(completion: { username, result in
            DispatchQueue.main.async {
                self.isSwitchingCatchAllEnabledState = false
                
                if let username = username {
                    self.username = username
                    self.catchAllEnabled = true
                } else {
                    self.catchAllEnabled = false
                    activeAlert = .error
                    showAlert = true
                    errorAlertTitle = String(localized: "error_edit_catch_all")
                    errorAlertMessage = result ?? String(localized: "error_unknown_refer_to_logs")
                }
            }
        },usernameId: username.id)
    }
    
    private func disableCatchAll(username:Usernames) {
        let networkHelper = NetworkHelper()
        networkHelper.disableCatchAllSpecificUsername(completion: { result in
            DispatchQueue.main.async {
                self.isSwitchingCatchAllEnabledState = false
                
                if result == "204" {
                    self.username?.catch_all = false
                    self.catchAllEnabled = false
                } else {
                    self.catchAllEnabled = true
                    activeAlert = .error
                    showAlert = true
                    errorAlertTitle = String(localized: "error_edit_catch_all")
                    errorAlertMessage = result ?? String(localized: "error_unknown_refer_to_logs")
                }
            }
        },usernameId: username.id)
    }     
          
    private func enableCanLogin(username:Usernames) {
        let networkHelper = NetworkHelper()
        networkHelper.enableCanLoginSpecificUsername(completion: { username, result in
            DispatchQueue.main.async {
                self.isSwitchingCanLoginState = false
                
                if let username = username {
                    self.username = username
                    self.canLogin = true
                } else {
                    self.canLogin = false
                    activeAlert = .error
                    showAlert = true
                    errorAlertTitle = String(localized: "error_edit_can_login")
                    errorAlertMessage = result ?? String(localized: "error_unknown_refer_to_logs")
                }
            }
        },usernameId: username.id)
    }
    
    private func disableCanLogin(username:Usernames) {
        let networkHelper = NetworkHelper()
        networkHelper.disableCanLoginSpecificUsername(completion: { result in
            DispatchQueue.main.async {
                self.isSwitchingCanLoginState = false
                
                if result == "204" {
                    self.username?.can_login = false
                    self.canLogin = false
                } else {
                    self.canLogin = true
                    activeAlert = .error
                    showAlert = true
                    errorAlertTitle = String(localized: "error_edit_can_login")
                    errorAlertMessage = result ?? String(localized: "error_unknown_refer_to_logs")
                }
            }
        },usernameId: username.id)
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
    
    
    private func deleteUsername(username:Usernames) {
        let networkHelper = NetworkHelper()
        networkHelper.deleteUsername(completion: { result in
            DispatchQueue.main.async {
                self.isDeletingUsername = false
                
                if result == "204" {
                    shouldReloadDataInParent = true
                    self.presentationMode.wrappedValue.dismiss()
                } else {
                    activeAlert = .error
                    showAlert = true
                    errorAlertTitle = String(localized: "error_deleting_username")
                    errorAlertMessage = result ?? String(localized: "error_unknown_refer_to_logs")
                }
            }
        },usernameId: username.id)
    }
    
    
    
    private func getUsername(usernameId: String) {
        let networkHelper = NetworkHelper()
        networkHelper.getSpecificUsername(completion: { username, error in
            
            if let username = username {
                DispatchQueue.main.async {
                    withAnimation {
                        self.username = username
                    }
                }
                
                DispatchQueue.global(qos: .background).async {
                    getAliasesAndAddThemToList(username: username)
                }
            } else {
                DispatchQueue.main.async {
                    withAnimation {
                        self.errorText = error
                    }
                }
            }
        },usernameId: usernameId)
    }
    
    private func getAliasesAndAddThemToList(username: Usernames, workingAliasList: AliasesArray? = nil) {
        let networkHelper = NetworkHelper()

        networkHelper.getAliases(completion: { list, error in
            if let list = list {
                addAliasesToList(username: username, aliasesArray: list, workingAliasListInbound: workingAliasList)
            } else {
                DispatchQueue.main.async {
                    withAnimation {
                        self.errorText = error
                    }
                }
            }
        },aliasSortFilterRequest: AliasSortFilterRequest(onlyActiveAliases: false, onlyDeletedAliases: false, onlyInactiveAliases: false, onlyWatchedAliases: false, sort: nil, sortDesc: false, filter: nil),
                                 page: (workingAliasList?.meta?.current_page ?? 0) + 1,
                                 size: 100,
                                 username: usernameId)
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
            getAliasesAndAddThemToList(username: username, workingAliasList: workingAliasList)
        } else {
            DispatchQueue.main.async {
                // Else, set aliasList to update UI
                updateUi(aliasesArray: workingAliasList)
            }
        }
    }
    
}

//
//#Preview {
//    UsernamesDetailView(usernameId: "6a866f49-5a0b-4c7e-bc45-f46bf019c4ed", usernameEmail: "PLACEHOLDER")
//}
