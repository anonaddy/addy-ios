//
//  DomainsDetailView.swift
//  addy
//
//  Created by Stijn van de Water on 08/05/2024.
//

import SwiftUI
import addy_shared
import Lottie
import UniformTypeIdentifiers

struct DomainsDetailView: View {
    
    enum ActiveAlert {
        case deleteDomain, error
    }
    
    let domainId: String
    let domainDomain: String

    
    @Binding var shouldReloadDataInParent: Bool

    
    @State private var activeAlert: ActiveAlert = .deleteDomain
    @State private var showAlert: Bool = false
    @State private var isDeletingDomain: Bool = false
    
    @State private var errorAlertTitle = ""
    @State private var errorAlertMessage = ""
    @EnvironmentObject var mainViewState: MainViewState
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @State private var domain: Domains? = nil
    @State private var errorText: String? = nil
    
    @State private var isActive: Bool = false
    @State private var catchAllEnabled: Bool = false
    @State private var isSwitchingisActiveState: Bool = false
    @State private var isSwitchingCatchAllEnabledState: Bool = false
    
    @State private var isPresentingEditDomainDescriptionBottomSheet: Bool = false
    @State private var isPresentingEditDomainFromNameBottomSheet: Bool = false
    @State private var isPresentingEditDomainRecipientsBottomSheet: Bool = false
    @State private var isPresentingEditDomainAutoCreateRegexBottomSheet: Bool = false
    
    @State private var aliasList: [String] = []
 
    @State private var totalForwarded: Int = 0
    @State private var totalBlocked: Int = 0
    @State private var totalReplies: Int = 0
    @State private var totalSent: Int = 0
    
    
    
    init(domainId: String, domainDomain: String, shouldReloadDataInParent: Binding<Bool>) {
        self.domainId = domainId
        self.domainDomain = domainDomain
        _shouldReloadDataInParent = shouldReloadDataInParent
    }
    
    @Environment(\.openURL) var openURL

    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
        
        if let domain = domain {
            Form {
                
                
                Section {
                    Text(String(format: String(localized: "manage_domain_basic_info"),
                                domain.domain,
                                DateTimeUtils.convertStringToLocalTimeZoneString(domain.created_at),
                                DateTimeUtils.convertStringToLocalTimeZoneString(domain.updated_at),
                                DateTimeUtils.convertStringToLocalTimeZoneString(domain.domain_verified_at),
                                DateTimeUtils.convertStringToLocalTimeZoneString(domain.domain_mx_validated_at),
                                DateTimeUtils.convertStringToLocalTimeZoneString(domain.domain_sending_verified_at),
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
                    Text(String(format: String(localized: "domain_aliases_d"),
                                String(domain.aliases_count ?? 0)))
                }
                
            
                Section {
                    
                    AddyToggle(isOn: $isActive, isLoading: isSwitchingisActiveState, title: domain.active ? String(localized: "domain_activated") : String(localized: "domain_deactivated"), description: String(localized: "domain_status_desc"))
                        .onChange(of: isActive) {
                            // Only fire when the value is NOT the same as the value already in the model
                            if (isActive != domain.active){
                                self.isSwitchingisActiveState = true
                                
                                if (domain.active){
                                    Task {
                                        await self.deactivateDomain(domain: domain)
                                    }
                                } else {
                                    Task {
                                        await self.activateDomain(domain: domain)
                                    }
                                }
                            }
                            
                        }
                    
                    AddyToggle(isOn: $catchAllEnabled, isLoading: isSwitchingCatchAllEnabledState, title: domain.catch_all ? String(localized: "catch_all_enabled") : String(localized: "catch_all_disabled"), description: String(localized: "catch_all_domain_desc"))
                        .onChange(of: catchAllEnabled) {
                            // Only fire when the value is NOT the same as the value already in the model
                            if (catchAllEnabled != domain.catch_all){
                                self.isSwitchingCatchAllEnabledState = true
                                
                                if (domain.catch_all){
                                    Task {
                                        await self.disableCatchAll(domain: domain)
                                    }
                                } else {
                                    Task {
                                        await self.enableCatchAll(domain: domain)
                                    }
                                }
                            }
                            
                        }
                    
            
                    
                    AddySection(title: String(localized: "description"), description: domain.description ?? String(localized: "domain_no_description"), leadingSystemimage: nil, trailingSystemimage: "pencil"){
                            isPresentingEditDomainDescriptionBottomSheet = true
                        }
                    
                    AddySection(title: String(localized: "from_name"), description: getFromName(domain: domain), leadingSystemimage: nil, trailingSystemimage: "pencil"){
                            if !mainViewState.userResource!.hasUserFreeSubscription(){
                                isPresentingEditDomainFromNameBottomSheet = true
                            } else {
                                HapticHelper.playHapticFeedback(hapticType: .error)
                            }
                        }
                    
                    AddySection(title: String(localized: "auto_create_regex"), description: getAutoCreateRegex(domain: domain), leadingSystemimage: nil, trailingSystemimage: "pencil"){
                            if !mainViewState.userResource!.hasUserFreeSubscription(){
                                isPresentingEditDomainAutoCreateRegexBottomSheet = true
                            } else {
                                HapticHelper.playHapticFeedback(hapticType: .error)
                            }
                        }
                    
                    AddySection(title: String(localized: "recipients"), description: getDefaultRecipient(domain: domain), leadingSystemimage: nil, trailingSystemimage: "pencil"){
                            isPresentingEditDomainRecipientsBottomSheet = true
                        }
                    
                    AddySection(title: String(localized: "check_dns"), description: getCheckDns(domain: domain), leadingSystemimage: nil, trailingSystemimage: nil){
                        openURL(URL(string: "\(AddyIo.API_BASE_URL)/domains")!)
                        }
                    
                    
                } header: {
                    Text(String(localized: "actions"))
                }
                
                Section {
                    AddySectionButton(title: String(localized: "delete_domain"), description: String(localized: "delete_domain_desc"),
                                      leadingSystemimage: "trash", colorAccent: .softRed, isLoading: isDeletingDomain){
                        activeAlert = .deleteDomain
                        showAlert = true
                    }
                }
                
            }.disabled(isDeletingDomain)
                .refreshable {
                    await getDomain(domainId: self.domainId)
                }
                .navigationTitle(self.domainDomain)
                .navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $isPresentingEditDomainDescriptionBottomSheet) {
                    NavigationStack {
                        EditDomainDescriptionBottomSheet(domainId: domain.id, description: domain.description ?? ""){ domain in
                            self.domain = domain
                            isPresentingEditDomainDescriptionBottomSheet = false
                            
                            // This changes the last updated time of the alias which is being shown in the list in the aliasesView.
                            // So we update the list when coming back
                            shouldReloadDataInParent = true

                        }
                    }
                    .presentationDetents([.large])
                }
                .sheet(isPresented: $isPresentingEditDomainFromNameBottomSheet) {
                    NavigationStack {
                        EditDomainFromNameBottomSheet(domainId: domain.id, domain: domain.domain, fromName: domain.from_name){ domain in
                            self.domain = domain
                            isPresentingEditDomainFromNameBottomSheet = false
                            
                            // This changes the last updated time of the alias which is being shown in the list in the aliasesView.
                            // So we update the list when coming back
                            shouldReloadDataInParent = true

                        }
                    }
                    .presentationDetents([.large])
                }
                .sheet(isPresented: $isPresentingEditDomainAutoCreateRegexBottomSheet) {
                    NavigationStack {
                        EditDomainAutoCreateRegexBottomSheet(domainId: domain.id, domain: domain.domain, autoCreateRegex: domain.auto_create_regex){ domain in
                            self.domain = domain
                            isPresentingEditDomainAutoCreateRegexBottomSheet = false
                            
                            // This changes the last updated time of the alias which is being shown in the list in the aliasesView.
                            // So we update the list when coming back
                            shouldReloadDataInParent = true

                        }
                    }
                    .presentationDetents([.large])
                }
                .sheet(isPresented: $isPresentingEditDomainRecipientsBottomSheet) {
                    NavigationStack {
                        EditDomainRecipientsBottomSheet(domainId: domain.id, selectedRecipientId: domain.default_recipient?.id) { domain in
                            self.domain = domain
                            isPresentingEditDomainRecipientsBottomSheet = false
                            
                            // This changes the last updated time of the alias which is being shown in the list in the aliasesView.
                            // So we update the list when coming back
                            shouldReloadDataInParent = true
                        }
                    }.presentationDetents([.medium, .large])
                }
            
            

                .alert(isPresented: $showAlert) {
                            switch activeAlert {
                           case .deleteDomain:
                                return Alert(title: Text(String(localized: "delete_domain")), message: Text(String(localized: "delete_domain_confirmation_desc")), primaryButton: .destructive(Text(String(localized: "delete"))){
                                    isDeletingDomain = true
    
                                    Task {
                                        await deleteDomain(domain: domain)
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
                        Label(String(localized: "error_obtaining_domain"), systemImage: "questionmark")
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
                await getDomain(domainId: self.domainId)
            }
            .navigationTitle(self.domainDomain)
            .navigationBarTitleDisplayMode(.inline)
        }
        
    }
    
    private func getDefaultRecipient(domain: Domains) -> String {
        if (domain.default_recipient != nil) {
            return domain.default_recipient!.email
        } else {
            return String(format: String(localized: "default_recipient_s"), mainViewState.userResourceExtended!.default_recipient_email)
        }
    }
    
    
    private func activateDomain(domain: Domains) async {
        let networkHelper = NetworkHelper()
        do {
            let activatedDomain = try await networkHelper.activateSpecificDomain(domainId: domain.id)
            self.isSwitchingisActiveState = false
            self.domain = activatedDomain
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

    private func deactivateDomain(domain: Domains) async {
        let networkHelper = NetworkHelper()
        do {
            let result = try await networkHelper.deactivateSpecificDomain(domainId: domain.id)
            self.isSwitchingisActiveState = false
            if result == "204" {
                self.domain?.active = false
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

    
    private func enableCatchAll(domain: Domains) async {
        let networkHelper = NetworkHelper()
        do {
            let enabledDomain = try await networkHelper.enableCatchAllSpecificDomain(domainId: domain.id)
            self.isSwitchingCatchAllEnabledState = false
            self.domain = enabledDomain
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

    
    private func disableCatchAll(domain: Domains) async {
        let networkHelper = NetworkHelper()
        do {
            let result = try await networkHelper.disableCatchAllSpecificDomain(domainId: domain.id)
            self.isSwitchingCatchAllEnabledState = false
            if result == "204" {
                self.domain?.catch_all = false
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
    
    private func getFromName(domain: Domains) -> String {
        
        
        if mainViewState.userResource!.hasUserFreeSubscription() {
            return String(localized: "feature_not_available_subscription")
        }
        else {
            // Set description based on alias.from_name and initialize the bottom dialog fragment
            if let fromName = domain.from_name {
                return fromName
            } else {
                return String(localized: "domain_no_from_name")
            }
        }
        
    }
    
    private func getAutoCreateRegex(domain: Domains) -> String {
        
        
        if mainViewState.userResource!.hasUserFreeSubscription() {
            return String(localized: "feature_not_available_subscription")
        }
        else {
            // Set description based on alias.auto_create_regex and initialize the bottom dialog fragment
            if let autoCreateRegex = domain.auto_create_regex {
                return autoCreateRegex
            } else {
                return String(localized: "domain_no_auto_create_regex")
            }
        }
        
    }
        
    private func getCheckDns(domain: Domains) -> String {
        if domain.domain_sending_verified_at == nil {
            return String(localized: "check_dns_desc_incorrect")
        }
        else {
            return String(localized: "check_dns_desc")
        }
        
    }
    
    private func deleteDomain(domain: Domains) async {
        let networkHelper = NetworkHelper()
        do {
            let result = try await networkHelper.deleteDomain(domainId: domain.id)
            self.isDeletingDomain = false
            if result == "204" {
                shouldReloadDataInParent = true
                self.presentationMode.wrappedValue.dismiss()
            } else {
                activeAlert = .error
                showAlert = true
                errorAlertTitle = String(localized: "error_deleting_domain")
                errorAlertMessage = result
            }
        } catch {
            self.isDeletingDomain = false
            activeAlert = .error
            showAlert = true
            errorAlertTitle = String(localized: "error_deleting_domain")
            errorAlertMessage = error.localizedDescription
        }
    }
    
    
    
    private func getDomain(domainId: String) async {
        let networkHelper = NetworkHelper()
        do {
            if let domain = try await networkHelper.getSpecificDomain(domainId: domainId){
                withAnimation {
                    self.domain = domain
                    self.isActive = domain.active
                    self.catchAllEnabled = domain.catch_all
                }
                
                // Reset total counts
                self.totalForwarded = 0
                self.totalBlocked = 0
                self.totalReplies = 0
                self.totalSent = 0
                
                await getAliasesAndAddThemToList(domain: domain)
            }
        } catch {
            withAnimation {
                self.errorText = error.localizedDescription
            }
        }
    }

    
    private func getAliasesAndAddThemToList(domain: Domains, workingAliasList: AliasesArray? = nil) async {
        let networkHelper = NetworkHelper()
        let aliasSortFilterRequest = AliasSortFilterRequest(onlyActiveAliases: false, onlyDeletedAliases: false, onlyInactiveAliases: false, onlyWatchedAliases: false, sort: nil, sortDesc: false, filter: nil)
        do {
            if let list = try await networkHelper.getAliases(aliasSortFilterRequest: aliasSortFilterRequest, page: (workingAliasList?.meta?.current_page ?? 0) + 1, size: 100, domain: domainId){
                addAliasesToList(domain: domain, aliasesArray: list, workingAliasListInbound: workingAliasList)
            }
        } catch {
            withAnimation {
                self.errorText = error.localizedDescription
            }
        }
    }

    
    
    // Function to add aliases to the list
    func addAliasesToList(domain: Domains, aliasesArray: AliasesArray, workingAliasListInbound: AliasesArray? = nil) {
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
                await getAliasesAndAddThemToList(domain: domain, workingAliasList: workingAliasList)
            }
        } else {
            // Else, set aliasList to update UI
            updateUi(aliasesArray: workingAliasList)
        }
    }
    
}

//
//#Preview {
//    DomainsDetailView(domainId: "6a866f49-5a0b-4c7e-bc45-f46bf019c4ed", domainEmail: "PLACEHOLDER")
//}
