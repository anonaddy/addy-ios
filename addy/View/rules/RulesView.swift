//
//  RulesView.swift
//  addy
//
//  Created by Stijn van de Water on 06/06/2024.
//


import SwiftUI
import addy_shared

struct RulesOption {
    static let bannerLocationOptions = ["top", "bottom", "off"]
    static let bannerLocationOptionName = [
        NSLocalizedString("rule_bannerlocation_top", comment: ""),
        NSLocalizedString("rule_bannerlocation_bottom", comment: ""),
        NSLocalizedString("rule_bannerlocation_off", comment: "")
    ]
    
    static let conditionsType = ["sender", "subject", "alias", "alias_description"]
    static let conditionsTypeName = [
        NSLocalizedString("the_sender", comment: ""),
        NSLocalizedString("the_subject", comment: ""),
        NSLocalizedString("the_alias", comment: ""),
        NSLocalizedString("the_alias_description", comment: "")
    ]
    static let conditionsMatch = ["contains", "does not contain", "is exactly", "is not", "starts with", "does not start with", "ends with", "does not end with", "matches regex", "does not match regex"]
    static let conditionsMatchName = [
        NSLocalizedString("contains", comment: ""),
        NSLocalizedString("does_not_contain", comment: ""),
        NSLocalizedString("is_exactly", comment: ""),
        NSLocalizedString("is_not", comment: ""),
        NSLocalizedString("starts_with", comment: ""),
        NSLocalizedString("does_not_start_with", comment: ""),
        NSLocalizedString("ends_with", comment: ""),
        NSLocalizedString("does_not_end_with", comment: ""),
        NSLocalizedString("matches_regex", comment: ""),
        NSLocalizedString("does_not_match_regex", comment: "")
    ]
    
    static let actionsType = ["subject", "displayFrom", "encryption", "banner", "block", "removeAttachments", "forwardTo"]
    static let actionsTypeName = [
        NSLocalizedString("replace_the_subject_with", comment: ""),
        NSLocalizedString("replace_the_from_name_with", comment: ""),
        NSLocalizedString("turn_PGP_encryption_off", comment: ""),
        NSLocalizedString("set_the_banner_information_location_to", comment: ""),
        NSLocalizedString("block_the_email", comment: ""),
        NSLocalizedString("remove_attachments", comment: ""),
        NSLocalizedString("forward_to", comment: "")
    ]
}

struct RulesView: View {
    @EnvironmentObject var mainViewState: MainViewState
    @StateObject var rulesViewModel = RulesViewModel()
    
    enum ActiveAlert {
        case error, deleteRule
    }
    @State private var activeAlert: ActiveAlert = .error
    @State private var showAlert: Bool = false
    
    @State private var ruleToDelete: Rules? = nil
    
    // Instead of mainStateView we have seperate states. To prevent the entire mainview from refreshing when updating
    @State private var rule_count: Int = 0
    @State private var rule_limit: Int? = 0
    
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
        Group() {
            if horizontalSize == .regular {
                NavigationStack(){
                    rulesViewBody
                }
            } else {
                rulesViewBody
            }
        }
        
        .onAppear(perform: {
            // Set stats, update later
            rule_count = mainViewState.userResource!.active_rule_count
            rule_limit = mainViewState.userResource!.active_rule_limit
            
            if let rules = rulesViewModel.rules{
                if (rules.data.isEmpty) {
                    Task {
                        await rulesViewModel.getRules()
                    }
                    
                }
            }
        })
        .task {
            await getUserResource()
        }
    }
    
    private var rulesViewBody: some View {
            List {
                if let rules = rulesViewModel.rules{
                    if !rules.data.isEmpty {
                    Section {
                        
                        ForEach (rules.data) { rule in
                            NavigationLink(destination: CreateRulesView(recipients: self.rulesViewModel.recipients, ruleId: rule.id, ruleName: rule.name ,shouldReloadDataInParent: $shouldReloadDataInParent)
                                .environmentObject(mainViewState)){
                                    
                                    HStack {
                                        Image(systemName: "line.horizontal.3").opacity(0.8).padding(.trailing)
                                        
                                        VStack(alignment: .leading) {
                                            
                                            if (rule.active) {
                                                Text(rule.name)
                                                    .font(.headline)
                                                    .truncationMode(.tail)
                                                    .frame(minWidth: 20)
                                            } else {
                                                Text(rule.name)
                                                    .font(.headline)
                                                    .truncationMode(.tail)
                                                    .frame(minWidth: 20)
                                                    .opacity(0.5)
                                            }
                                            
                                            
                                            
                                            if (rule.active) {
                                                Text(getRuleDescription(rule: rule, recipients: self.rulesViewModel.recipients))
                                                    .font(.caption)
                                                    .opacity(0.625)
                                                    .lineLimit(1)
                                                    .truncationMode(.middle)
                                            } else {
                                                Text(String(localized: "rule_disabled"))
                                                    .font(.caption)
                                                    .opacity(0.312)
                                                    .lineLimit(1)
                                                    .truncationMode(.middle)
                                            }
                                            
                                            
                                            
                                            
                                        }
                                        
                                    }.padding(.vertical, 4)
                                }
                                .onChange(of: shouldReloadDataInParent) {
                                    if shouldReloadDataInParent {
                                        Task {
                                            await getUserResource()
                                            await rulesViewModel.getRules()
                                        }
                                        
                                        self.shouldReloadDataInParent = false
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    if (rule.active){
                                        Button {
                                            Task {
                                                await self.deactivateRule(rule: rule)
                                            }
                                        } label: {
                                            Label(String(localized: "deactivate"), systemImage: "hand.raised.fill")
                                        }
                                        .tint(.indigo)
                                    } else {
                                        Button {
                                            Task {
                                                await self.activateRule(rule: rule)
                                            }
                                        } label: {
                                            Label(String(localized: "activate"), systemImage: "checkmark.circle")
                                        }
                                        .tint(.indigo)
                                    }
                                    
                                }
                            
                        }.onMove(perform: moveRule)
                            .onDelete(perform: deleteRule)
                        
                    } header: {
                        HStack(spacing: 6){
                            Text(String(localized: "all_rules"))
                            
                            
                            if (rulesViewModel.isLoading){
                                ProgressView()
                                    .frame(maxHeight: 4)
                                
                            }
                        }
                        
                    } footer: {
                        VStack(alignment: .leading) {
                            
                            
                            Text(String(format: String(localized: "you_ve_used_d_out_of_d_rules"),  String(rule_count), (mainViewState.userResource!.subscription != nil ? String(rule_limit! /* Cannot be nil since subscription is not nil */ ) : String(localized: "unlimited"))))
                            Text(String(localized: "hold_the_drag_handle_and_drag_to_change_order"))
                        }.padding(.top)
                        
                    }
                }
                }
                
            }.refreshable {
                if horizontalSize == .regular {
                    // When in regular size (tablet) mode, refreshing aliases also ask the mainView to update general data
                    self.onRefreshGeneralData?()
                }
                
                await self.rulesViewModel.getRules()
                await getUserResource()
            }
            .alert(isPresented: $showAlert) {
                switch activeAlert {
                case .deleteRule:
                    return Alert(title: Text(String(localized: "delete_rule")), message: Text(String(localized: "delete_rule_confirmation_desc")), primaryButton: .destructive(Text(String(localized: "delete"))){
                        Task {
                            await self.deleteRule(rule: self.ruleToDelete!)
                        }
                    }, secondaryButton: .cancel(){
                        Task {
                                                await rulesViewModel.getRules()
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
                
                
                // If there is an rules (aka, if the list is visible)
                if let rules = rulesViewModel.rules{
                    
                    
                    if rules.data.isEmpty {
                        if mainViewState.userResource!.hasUserFreeSubscription() {
                            // Error screen
                            ContentUnavailableView {
                                Label(String(localized: "no_rules"), systemImage: "checklist")
                            } description: {
                                Text(String(localized: "feature_not_available_subscription"))
                            }
                        } else {
                            ContentUnavailableView {
                                Label(String(localized: "no_rules"), systemImage: "checklist")
                            } description: {
                                Text(String(localized: "no_rules_desc"))
                            }
                        }
                        
                    }
                    
                } else {
                    // If there is NO rules (aka, if the list is not visible)
                    
                    
                    // No rules, check if there is an error
                    if (rulesViewModel.networkError != ""){
                        // Error screen
                        ContentUnavailableView {
                            Label(String(localized: "something_went_wrong_retrieving_rules"), systemImage: "wifi.slash")
                        } description: {
                            Text(rulesViewModel.networkError)
                        } actions: {
                            Button(String(localized: "try_again")) {
                                Task {
                                    await getUserResource()
                                    await rulesViewModel.getRules()
                                }
                            }
                        }
                    } else {
                        // No rules and no error. It must still be loading...
                        VStack(alignment: .center, spacing: 0) {
                            Spacer()
                            ContentUnavailableView {
                                Label(String(localized: "obtaining_rules"), systemImage: "globe")
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
            .navigationTitle(String(localized: "rules"))
            .navigationBarTitleDisplayMode(horizontalSize == .regular ? .automatic : .inline)
            .toolbar {
                if horizontalSize == .regular {
                    ProfilePicture().environmentObject(mainViewState)
                    FailedDeliveriesIcon(horizontalSize: $horizontalSize).environmentObject(mainViewState)
                }
            }
            .navigationBarItems(trailing: NavigationLink(destination: CreateRulesView(recipients: self.rulesViewModel.recipients, ruleId: nil, ruleName: "", shouldReloadDataInParent: $shouldReloadDataInParent)) {
                
                Image(systemName: "plus")
                    .frame(width: 24, height: 24)
               
            } // Disable this image/button when the user has a subscription AND the count is ABOVE or ON limit
                .disabled(mainViewState.userResource!.subscription != nil &&
                          rule_count >= rule_limit! /* Cannot be nil since subscription is not nil */ ))
    }
   
    
    private func getRuleDescription(rule: Rules, recipients: [Recipients]) -> String{
        // Get this from array (make alias_description "alias description) like ANdroid
        
        let conditionTypeIndex = RulesOption.conditionsType.firstIndex(of: rule.conditions[0].type) ?? 0
        let conditionMatchIndex = RulesOption.conditionsMatch.firstIndex(of: rule.conditions[0].match) ?? 0
        
        let typeText = RulesOption.conditionsTypeName[conditionTypeIndex]
        let matchText = RulesOption.conditionsMatchName[conditionMatchIndex]
        
        let descConditions = "\(typeText) \(matchText) \(rule.conditions[0].values[0])"
        
        
        let actionTypeIndex = RulesOption.actionsType.firstIndex(of: rule.actions[0].type) ?? 0
        let actionTypeText = RulesOption.actionsTypeName[actionTypeIndex]
        
        let descActions = if rule.actions[0].type == "forwardTo" && !recipients.isEmpty {
            "\(actionTypeText) \(recipients.first(where: {$0.id == rule.actions[0].value})!.email)"
        } else {
            "\(actionTypeText) \(rule.actions[0].value)"
        }
        
        
        return String(format: NSLocalizedString("manage_rules_list_desc", comment: ""), descConditions, descActions)
    }
    
    
    private func deleteRule(rule: Rules) async {
        let networkHelper = NetworkHelper()
        do {
            let result = try await networkHelper.deleteRule(ruleId: rule.id)
            if result == "204" {
                await getUserResource()
                await rulesViewModel.getRules()
            } else {
                activeAlert = .error
                showAlert = true
                errorAlertTitle = String(localized: "error_deleting_rule")
                errorAlertMessage = result
            }
        } catch {
            activeAlert = .error
            showAlert = true
            errorAlertTitle = String(localized: "error_deleting_rule")
            errorAlertMessage = error.localizedDescription
        }
    }

    
    
    func deleteRule(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            if let rules = rulesViewModel.rules?.data {
                let item = rules[index]
                ruleToDelete = item
                activeAlert = .deleteRule
                showAlert = true
                
                // Remove from the collection for the smooth animation
                rulesViewModel.rules?.data.remove(atOffsets: offsets)
                
            }
        }
    }
    
    // Add this function
    func moveRule(from source: IndexSet, to destination: Int) {
        rulesViewModel.rules?.data.move(fromOffsets: source, toOffset: destination)
        
        if let rules = rulesViewModel.rules?.data {
            Task {
                await reorderRules(rules: rules)
            }
        }
        
    }
    
    private func reorderRules(rules: [Rules]) async {
        let networkHelper = NetworkHelper()
        do {
            let result = try await networkHelper.reorderRules(rules: rules)
            if result != "200" {
                activeAlert = .error
                showAlert = true
                errorAlertTitle = String(localized: "error_changing_rules_order")
                errorAlertMessage = result
                await rulesViewModel.getRules()
            }
        } catch {
            activeAlert = .error
            showAlert = true
            errorAlertTitle = String(localized: "error_changing_rules_order")
            errorAlertMessage = error.localizedDescription
            await rulesViewModel.getRules()
        }
    }

    
    private func activateRule(rule: Rules) async {
        let networkHelper = NetworkHelper()
        do {
            _ = try await networkHelper.activateSpecificRule(ruleId: rule.id)
            await rulesViewModel.getRules()
        } catch {
                activeAlert = .error
                showAlert = true
                errorAlertTitle = String(localized: "error_rules_active")
                errorAlertMessage = error.localizedDescription
            
        }
    }

    
    private func deactivateRule(rule: Rules) async {
        let networkHelper = NetworkHelper()
        do {
            let result = try await networkHelper.deactivateSpecificRule(ruleId: rule.id)
            if result == "204" {
                await rulesViewModel.getRules()
            } else {
                activeAlert = .error
                showAlert = true
                errorAlertTitle = String(localized: "error_rules_active")
                errorAlertMessage = result
            }
        } catch {
            activeAlert = .error
            showAlert = true
            errorAlertTitle = String(localized: "error_rules_active")
            errorAlertMessage = error.localizedDescription
        }
    }

    
    private func getUserResource() async {
        let networkHelper = NetworkHelper()
        do {
            let userResource = try await networkHelper.getUserResource()
            if let userResource = userResource {
                // Don't update mainView, this will refresh the entire view hierarchy
                rule_limit = userResource.active_rule_limit
                rule_count = userResource.active_rule_count
            } else {
                activeAlert = .error
                showAlert = true
            }
        } catch {
            print("Failed to get user resource: \(error)")
            // viewModel will take care of putting this error into a var
        }
    }

    
}

//
//#Preview {
//    RulesView()
//}
