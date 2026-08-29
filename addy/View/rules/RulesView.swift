//
//  RulesView.swift
//  addy
//
//  Created by Stijn van de Water on 06/06/2024.
//

import addy_shared
import SwiftUI

struct RulesView: View {
    @EnvironmentObject var mainViewState: MainViewState

    @StateObject private var rulesViewModel = RulesViewModel()

    @State private var activeAlert: ActiveAlert = .error
    @State private var showAlert: Bool = false
    @State private var ruleToDelete: Rules? = nil
    @State private var rule_count: Int = 0
    @State private var rule_limit: Int? = 0
    @State private var shouldReloadDataInParent = false
    @State private var errorAlertTitle = ""
    @State private var errorAlertMessage = ""
    @Binding var horizontalSize: UserInterfaceSizeClass

    enum ActiveAlert {
        case error, deleteRule
    }

    /// Instead of mainStateView we have seperate states. To prevent the entire mainview from refreshing when updating
    var onRefreshGeneralData: (() -> Void)? = nil
    // Add this function

    var body: some View {
        #if DEBUG
            let _ = Self._printChanges()
        #endif
        // Prevent having a navstack inside a navstack when the view is openen on a compact level (inside the profilesheet)
        Group {
            if horizontalSize == .regular {
                NavigationStack {
                    rulesViewBody
                }
            } else {
                rulesViewBody
            }
        }

        .onAppear(perform: {
            // Set stats, update later
            rule_count = mainViewState.userResource?.active_rule_count ?? 0
            rule_limit = mainViewState.userResource?.active_rule_limit

            if let rules = rulesViewModel.rules {
                if rules.data.isEmpty {
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
            if let rules = rulesViewModel.rules {
                if !rules.data.isEmpty {
                    Section {
                        ForEach(rules.data) { rule in
                            NavigationLink(destination: CreateRulesView(recipients: self.rulesViewModel.recipients, ruleId: rule.id, ruleName: rule.name, shouldReloadDataInParent: $shouldReloadDataInParent)
                                .environmentObject(mainViewState))
                            {
                                HStack {
                                    Image(systemName: "line.horizontal.3").opacity(0.8).padding(.trailing)

                                    VStack(alignment: .leading) {
                                        if rule.active {
                                            Text(rule.name)
                                                .font(.headline)
                                                .lineLimit(1)
                                                .truncationMode(.tail)
                                                .frame(minWidth: 20)
                                        } else {
                                            Text(rule.name)
                                                .font(.headline)
                                                .lineLimit(1)
                                                .truncationMode(.tail)
                                                .frame(minWidth: 20)
                                                .opacity(0.5)
                                        }

                                        if rule.active {
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
                                if rule.active {
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
                        HStack(spacing: 6) {
                            Text(String(localized: "rules"))

                            if rulesViewModel.isLoading {
                                ProgressView()
                                    .frame(maxHeight: 4)
                            }

                            if let count = rulesViewModel.rules?.data.count, count > 0 {
                                Text("\(count)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }

                    } footer: {
                        VStack(alignment: .leading) {
                            Text(String(format: String(localized: "you_ve_used_d_out_of_d_rules"), String(rule_count), ((mainViewState.userResource?.subscription != nil && rule_limit != nil) ? String(rule_limit!) : String(localized: "unlimited"))))
                            Text(String(localized: "rules_view_explanation")).padding(.top)
                        }.padding(.top)

                    }.textCase(nil)
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
                return Alert(title: Text(String(localized: "delete_rule")), message: Text(String(localized: "delete_rule_confirmation_desc")), primaryButton: .destructive(Text(String(localized: "delete"))) {
                    Task {
                        await self.deleteRule(rule: self.ruleToDelete!)
                    }
                }, secondaryButton: .cancel {
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
            if let rules = rulesViewModel.rules {
                if rules.data.isEmpty {
                    if mainViewState.userResource?.hasUserFreeSubscription() ?? true {
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
                if rulesViewModel.networkError != "" {
                    // Error screen
                    ContentUnavailableView {
                        Label(String(localized: "something_went_wrong_retrieving_rules"), systemImage: "wifi.slash")
                    } description: {
                        Text(rulesViewModel.networkError)
                    } actions: {
                        Button(String(localized: "try_again", bundle: Bundle(for: SharedData.self))) {
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
                            Text(String(localized: "obtaining_desc", bundle: Bundle(for: SharedData.self)))
                        }

                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: 50)
                        Spacer()
                    }
                }
            }
        })
        .navigationTitle(String(localized: "rules"))
        .navigationBarTitleDisplayMode(horizontalSize == .regular ? .automatic : .inline)
        .toolbar {
            if horizontalSize == .regular {
                ToolbarItem(placement: .topBarLeading) {
                    ProfilePicture().environmentObject(mainViewState)
                }

                if #available(iOS 26.0, *) {
                    ToolbarSpacer(placement: .topBarLeading)
                }

                ToolbarItem(placement: .topBarLeading) {
                    FailedDeliveriesIcon(horizontalSize: $horizontalSize).environmentObject(mainViewState)
                }

                ToolbarItem(placement: .topBarLeading) {
                    AccountNotificationsIcon().environmentObject(mainViewState)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: CreateRulesView(recipients: rulesViewModel.recipients, ruleId: nil, ruleName: "", shouldReloadDataInParent: $shouldReloadDataInParent)) {
                    Image(systemName: "plus")
                        .frame(width: 24, height: 24)
                }
                // Disable this image/button when the user has a subscription AND the count is ABOVE or ON limit
                .disabled(mainViewState.userResource?.subscription != nil &&
                    rule_limit != nil && rule_count >= rule_limit!)
            }
        }
    }

    private func getRuleDescription(rule: Rules, recipients: [Recipients]) -> String {
        guard !rule.conditions.isEmpty, !rule.actions.isEmpty else {
            return ""
        }

        let firstCondition = rule.conditions[0]
        let descConditions: String
        let typeText = RulesOption.conditionTypeName(for: firstCondition.type)

        if RulesOption.isBooleanCondition(type: firstCondition.type) {
            descConditions = typeText
        } else {
            let matchText = RulesOption.matchName(for: firstCondition.match ?? "")
            let val = firstCondition.values?.first ?? ""
            descConditions = "\(typeText) \(matchText) \(val)"
        }

        let firstAction = rule.actions[0]
        let actionTypeText = RulesOption.actionTypeName(for: firstAction.type)

        let descActions: String
        if firstAction.type == "forwardTo" && !recipients.isEmpty {
            descActions = "\(actionTypeText) \(recipients.first(where: { $0.id == firstAction.value })?.email ?? String(localized: "unknown"))"
        } else if RulesOption.isBooleanAction(type: firstAction.type) {
            descActions = actionTypeText
        } else {
            descActions = "\(actionTypeText) \(firstAction.value)"
        }

        return String(format: NSLocalizedString("manage_rules_list_desc", comment: ""), descConditions, descActions)
    }

    private func deleteRule(rule: Rules) async {
        do {
            let result = try await RulesRepository.shared.deleteRule(ruleId: rule.id)
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

    func moveRule(from source: IndexSet, to destination: Int) {
        rulesViewModel.rules?.data.move(fromOffsets: source, toOffset: destination)

        if let rules = rulesViewModel.rules?.data {
            Task {
                await reorderRules(rules: rules)
            }
        }
    }

    private func reorderRules(rules: [Rules]) async {
        do {
            let result = try await RulesRepository.shared.reorderRules(rules: rules)
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
        do {
            _ = try await RulesRepository.shared.activateRule(ruleId: rule.id)
            await rulesViewModel.getRules()
        } catch {
            activeAlert = .error
            showAlert = true
            errorAlertTitle = String(localized: "error_rules_active")
            errorAlertMessage = error.localizedDescription
        }
    }

    private func deactivateRule(rule: Rules) async {
        do {
            let result = try await RulesRepository.shared.deactivateRule(ruleId: rule.id)
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
        do {
            let userResource = try await UserRepository.shared.getUserResource()
            // Don't update mainView, this will refresh the entire view hierarchy
            rule_limit = userResource.active_rule_limit
            rule_count = userResource.active_rule_count
        } catch {
            guard !Task.isCancelled, !(error is CancellationError), (error as? URLError)?.code != .cancelled else { return }
            activeAlert = .error
            showAlert = true
            errorAlertTitle = String(localized: "something_went_wrong_retrieving_rules")
            errorAlertMessage = error.localizedDescription
        }
    }
}

//
// #Preview {
//    RulesView()
// }
