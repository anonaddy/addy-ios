//
//  RulesView.swift
//  addy
//
//  Created by Stijn van de Water on 06/06/2024.
//


import SwiftUI
import addy_shared

struct RulesView: View {
    @EnvironmentObject var mainViewState: MainViewState
    @StateObject var rulesViewModel = RulesViewModel()
    @Binding var isShowingRulesView: Bool
    
    enum ActiveAlert {
        case error, deleteRule
    }
    @State private var activeAlert: ActiveAlert = .error
    @State private var showAlert: Bool = false
    
    @State private var ruleToDelete: Rules? = nil
    
    
    // Instead of mainStateView we have seperate states. To prevent the entire mainview from refreshing when updating
    @State private var rule_count: Int = 0
    @State private var rule_limit: Int? = 0
    
    @State private var isPresentingAddRuleBottomSheet = false
    
    @State private var shouldReloadDataInParent = false
    
    @State private var errorAlertTitle = ""
    @State private var errorAlertMessage = ""
    
    
    var body: some View {
        NavigationStack(){
            List {
                if let rules = rulesViewModel.rules{
                    Section {
                        
                        ForEach (rules.data) { rule in
                            NavigationLink(destination: CreateRulesView(ruleId: rule.id, ruleName: rule.name ,shouldReloadDataInParent: $shouldReloadDataInParent)
                                .environmentObject(mainViewState)){
                                    
                                    HStack {
                                        Image(systemName: "line.horizontal.3").opacity(0.8).padding(.trailing)

                                        VStack(alignment: .leading) {
                                            Text(rule.name)
                                                .font(.headline)
                                                .truncationMode(.tail)
                                                .frame(minWidth: 20)
                                            
                                            
                                            Text(getRuleDescription(rule: rule))
                                                    .font(.caption)
                                                    .opacity(0.625)
                                                    .lineLimit(1)
                                                    .truncationMode(.middle)
                                            
                                            
                                        }
                                        
                                    }.padding(.vertical, 4)
                                }
                                .onChange(of: shouldReloadDataInParent) {
                                    if shouldReloadDataInParent {
                                        rulesViewModel.getRules()
                                        getUserResource()
                                        self.shouldReloadDataInParent = false
                                    }
                                }
                            
                            
                            
                        }.onMove(perform: moveRule)
                            .onDelete(perform: deleteRule)
                    }header: {
                        HStack(spacing: 6){
                            Text(String(localized: "all_rules"))

                            
                            if (rulesViewModel.isLoading){
                                ProgressView()
                                    .frame(maxHeight: 4)
                                
                            }
                        }
                        
                    } footer: {
                        Label {
                            VStack(alignment: .leading) {
                                
                                
                                Text(String(format: String(localized: "you_ve_used_d_out_of_d_rules"),  String(rule_count), (mainViewState.userResource!.subscription != nil ? String(rule_limit! /* Cannot be nil since subscription is not nil */ ) : String(localized: "unlimited"))))
                                Text(String(localized: "hold_the_drag_handle_and_drag_to_change_order"))
                            }
                        } icon: {
                            Image(systemName: "info.circle")
                        }
                        
                    }
                    
                }
                
            }.refreshable {
                self.rulesViewModel.getRules()
                getUserResource()
            }
            .alert(isPresented: $showAlert) {
                switch activeAlert {
                case .deleteRule:
                    return Alert(title: Text(String(localized: "delete_rule")), message: Text(String(localized: "delete_rule_confirmation_desc")), primaryButton: .destructive(Text(String(localized: "delete"))){
                        DispatchQueue.global(qos: .background).async {
                            self.deleteRule(rule: self.ruleToDelete!)
                        }
                    }, secondaryButton: .cancel(){
                        rulesViewModel.getRules()
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
                    
                    // There is always 1 rule.
                    
                    //                    if rules.isEmpty {
                    //                        ContentUnavailableView {
                    //                            Label(String(localized: "no_rules"), systemImage: "person.2")
                    //                        } description: {
                    //                            Text(String(localized: "no_rules_desc"))
                    //                        }
                    //                    }
                    
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
                                rulesViewModel.getRules()
                                getUserResource()
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
            .navigationBarItems(leading: Button(action: {
                    self.isShowingRulesView = false
            }) {
                if UIDevice.current.userInterfaceIdiom != .pad {
                    Text(String(localized: "close"))
                }
            }, trailing: Button(action: {
                self.isPresentingAddRuleBottomSheet = true
            } ) {
                
                Image(systemName: "plus")
                    .resizable()
                    .padding(6)
                    .frame(width: 24, height: 24)
                    .background(Color.accentColor)
                    .clipShape(Circle())
                    .foregroundColor(.white)
                // Disable this image/button when the user has a subscription AND the count is ABOVE or ON limit
                    .disabled(mainViewState.userResource!.subscription != nil &&
                              rule_count >= rule_limit! /* Cannot be nil since subscription is not nil */ )
            })
        }.onAppear(perform: {
            // Set stats, update later
            rule_count = mainViewState.userResource!.active_rule_count
            rule_limit = mainViewState.userResource!.active_rule_limit
            
            if let rules = rulesViewModel.rules{
                if (rules.data.isEmpty) {
                    rulesViewModel.getRules()
                    
                }
            }
            getUserResource()
        })
        
    }
    
    private func getRuleDescription(rule: Rules) -> String{
        let descConditions = "\(rule.conditions[0].type) \(rule.conditions[0].match) \(rule.conditions[0].values[0])"
        let descActions = "\(rule.actions[0].type) \(rule.actions[0].value)"

        return String(format: NSLocalizedString("manage_rules_list_desc", comment: ""), descConditions, descActions)

    }
    
    
    private func deleteRule(rule:Rules) {
        let networkHelper = NetworkHelper()
        networkHelper.deleteRule(completion: { result in
            DispatchQueue.main.async {
                if result == "204" {
                    rulesViewModel.getRules()
                    getUserResource()
                } else {
                    activeAlert = .error
                    showAlert = true
                    errorAlertTitle = String(localized: "error_deleting_rule")
                    errorAlertMessage = result ?? String(localized: "error_unknown_refer_to_logs")
                }
            }
        },ruleId: rule.id)
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
            DispatchQueue.global(qos: .background).async {
                reorderRules(rules: rules)
            }
        }
        
    }
    
    private func reorderRules(rules:[Rules]) {
        let networkHelper = NetworkHelper()
        networkHelper.reorderRules(completion: { result in
            DispatchQueue.main.async {
                if result == "200" {
                    // No need to change anything
                    //rulesViewModel.getRules()
                    //getUserResource()
                } else {
                    activeAlert = .error
                    showAlert = true
                    errorAlertTitle = String(localized: "error_changing_rules_order")
                    errorAlertMessage = result ?? String(localized: "error_unknown_refer_to_logs")
                    // Since the order changes, reload the data
                    rulesViewModel.getRules()
                }
            }
        },rules: rules)
    }
    
    
    private func getUserResource() {
        let networkHelper = NetworkHelper()
        networkHelper.getUserResource { userResource, error in
                DispatchQueue.main.async {
                    if let userResource = userResource {
                        // Don't update mainView, this will refresh the entire view hiearchy
                        rule_limit = userResource.active_rule_limit
                        rule_count = userResource.active_rule_count
                    } else {
                        print("Error: \(String(describing: error))")
                        activeAlert = .error
                        showAlert = true
                    }
                }
            }
        }
    
}

//
//#Preview {
//    RulesView()
//}
