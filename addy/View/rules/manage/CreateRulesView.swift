//
//  CreateRulesView.swift
//  addy
//
//  Created by Stijn van de Water on 06/06/2024.
//

import addy_shared
import Lottie
import SwiftUI

struct CreateRulesView: View {
    enum ActiveAlert {
        case error
    }

    let ruleId: String
    var recipients: [Recipients] = []
    @State var ruleName: String
    @State var ruleNamePlaceholder: String = .init(localized: "enter_name")

    @State private var actionToEdit: Action? = nil
    @State private var conditionToEdit: Condition? = nil

    @Binding var shouldReloadDataInParent: Bool
    @State private var activeAlert: ActiveAlert = .error
    @State private var showAlert: Bool = false
    @State private var isSavingRule: Bool = false

    @State private var conditionOperator: String = "AND"

    @State private var errorAlertTitle = ""
    @State private var errorAlertMessage = ""
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    @State var selectedChips: [String] = []
    @State var rulesRunOnChips: [AddyChipModel] = [AddyChipModel(chipId: "forwards", label: String(localized: "forwards")),
                                                   AddyChipModel(chipId: "replies", label: String(localized: "replies")),
                                                   AddyChipModel(chipId: "sends", label: String(localized: "sends"))]

    @State private var ruleNameValidationError: String?

    @State private var rule: Rules? = nil
    @State private var errorText: String? = nil

    @State private var isPresentingAddNewActionBottomSheet = false
    @State private var isPresentingAddNewConditionBottomSheet = false

    init(recipients: [Recipients], ruleId: String?, ruleName: String, shouldReloadDataInParent: Binding<Bool>) {
        self.recipients = recipients

        if let ruleId = ruleId {
            self.ruleId = ruleId
            self.ruleName = ruleName
        } else {
            // RuleId is nil, load in the template rule
            let rule = Rules(
                id: "",
                user_id: "",
                name: "First Rule",
                order: 0,
                conditions: [
                    Condition(type: "sender", match: "is exactly", values: ["will@addy.io", "no-reply@addy.io"]),
                    Condition(type: "subject", match: "contains", values: ["newsletter", "subscription"]),
                ],
                actions: [
                    Action(type: "subject", value: "SPAM"),
                    Action(type: "block", value: "true"),
                ],
                operator: "AND",
                forwards: true,
                replies: true,
                sends: true,
                active: true,
                applied: 0,
                last_applied: "",
                created_at: "",
                updated_at: ""
            )

            self.rule = rule
            self.ruleId = rule.id
            self.ruleName = rule.name
        }

        _shouldReloadDataInParent = shouldReloadDataInParent
    }

    var body: some View {
        #if DEBUG
            let _ = Self._printChanges()
        #endif

        // CreateRulesView: @self changed.
        if let rule = rule {
            Form {
                Section {
                    ValidatingTextField(value: self.$ruleName, placeholder: self.$ruleNamePlaceholder, fieldType: .text, error: $ruleNameValidationError)
                } header: {
                    Text(String(localized: "enter_name"))

                }.textCase(nil)

                Section {
                    AddyMultiSelectChipView(chips: $rulesRunOnChips, selectedChips: $selectedChips, singleLine: true) { onTappedChip in
                        withAnimation {
                            if selectedChips.contains(onTappedChip.chipId) {
                                if let index = selectedChips.firstIndex(of: onTappedChip.chipId) {
                                    selectedChips.remove(at: index)
                                }
                            } else {
                                selectedChips.append(onTappedChip.chipId)
                            }
                        }

                    }.scrollClipDisabled()
                } header: {
                    Text(String(localized: "run_rule_on")).padding(.horizontal)

                }.textCase(nil)

                Section {
                    if rule.conditions.isEmpty {
                        VStack {
                            Button {
                                isPresentingAddNewConditionBottomSheet = true
                            } label: {
                                Image(systemName: "plus.circle.fill").resizable().frame(width: 25, height: 25).foregroundStyle(Color.accentColor).foregroundStyle(Color.accentColor)
                            }.buttonBorderShape(.circle).apply { View in
                                if #available(iOS 26.0, *) {
                                    View.buttonStyle(.glass).glassEffect(in: Circle())
                                } else {
                                    View.buttonStyle(.plain)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ForEach(rule.conditions, id: \.self) { condition in
                            HStack {
                                Spacer().frame(width: 10)
                                VStack {
                                    let typeIndex = RulesOption.conditionsType.firstIndex(of: condition.type) ?? 0
                                    let matchIndex = RulesOption.conditionsMatch.firstIndex(of: condition.match) ?? 0

                                    let typeText = RulesOption.conditionsTypeName[typeIndex]
                                    let matchText = RulesOption.conditionsMatchName[matchIndex]

                                    Text(String(format: String(localized: "rule_if_"), "`\(typeText)` \(matchText)..."))
                                        .fontWeight(.medium)
                                        .multilineTextAlignment(.center)
                                        .padding(.bottom, 1)
                                    Text(condition.values.joined(separator: ", "))
                                        .font(.system(size: 14))
                                        .multilineTextAlignment(.center)
                                        .lineLimit(3)
                                        .opacity(0.7)
                                }.onTapGesture {
                                    conditionToEdit = condition
                                }.padding(EdgeInsets()).frame(maxWidth: .infinity)
                                VStack {
                                    Button {
                                        self.rule!.conditions.remove(at: self.rule!.conditions.firstIndex(where: { $0 == condition })!)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill").resizable().frame(width: 25, height: 25).foregroundStyle(Color.accentColor)
                                    }.buttonBorderShape(.circle).apply { View in
                                        if #available(iOS 26.0, *) {
                                            View.buttonStyle(.glass).glassEffect(in: Circle())
                                        } else {
                                            View.buttonStyle(.plain)
                                        }
                                    }
                                }.frame(width: 10)
                                
                            }.listRowSeparator(.hidden).padding()

                            VStack {
                                Capsule()
                                    .fill(rule.conditions.last == condition ? Color.accentColor : Color.gray)
                                    .frame(width: 3, height: 50)

                                if rule.conditions.last == condition {
                                    Button {
                                        isPresentingAddNewConditionBottomSheet = true
                                    } label: {
                                        Image(systemName: "plus.circle.fill").resizable().frame(width: 25, height: 25).foregroundStyle(Color.accentColor)
                                    }.buttonBorderShape(.circle).apply { View in
                                        if #available(iOS 26.0, *) {
                                            View.buttonStyle(.glass).glassEffect(in: Circle())
                                        } else {
                                            View.buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }

                } header: {
                    HStack {
                        Text(String(localized: "conditions"))
                        Spacer()

                        Picker(selection: $conditionOperator, label: Text(String(localized: "condition_operator"))) {
                            Text(String(localized: "and")).tag("AND")
                            Text(String(localized: "or")).tag("OR")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .fixedSize()
                    }

                }.textCase(nil)

                Section {
                    if rule.actions.isEmpty {
                        VStack {
                            Button {
                                isPresentingAddNewActionBottomSheet = true
                            } label: {
                                Image(systemName: "plus.circle.fill").resizable().frame(width: 25, height: 25).foregroundStyle(Color.accentColor)
                            }.buttonBorderShape(.circle).apply { View in
                                if #available(iOS 26.0, *) {
                                    View.buttonStyle(.glass).glassEffect(in: Circle())
                                } else {
                                    View.buttonStyle(.plain)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ForEach(rule.actions, id: \.self) { action in
                            HStack {
                                Spacer().frame(width: 10)
                                VStack {
                                    let typeIndex = RulesOption.actionsType.firstIndex(of: action.type) ?? 0
                                    let typeText = RulesOption.actionsTypeName[typeIndex]

                                    // Text(typeText)
                                    Text(String(format: String(localized: "rule_then_"), "`\(typeText)`"))
                                        .fontWeight(.medium)
                                        .multilineTextAlignment(.center)
                                        .padding(.bottom, 1)

                                    let value: String = action.type == "forwardTo"
                                        ? (recipients.first(where: { $0.id == action.value })?.email ?? String(localized: "unknown"))
                                        : action.value

                                    Text(value)
                                        .font(.system(size: 14))
                                        .multilineTextAlignment(.center)
                                        .lineLimit(3)
                                        .opacity(0.7)
                                }.onTapGesture {
                                    actionToEdit = action
                                }.padding(EdgeInsets()).frame(maxWidth: .infinity)
                                VStack {
                                    Button {
                                        self.rule!.actions.remove(at: self.rule!.actions.firstIndex(where: { $0 == action })!)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill").resizable().frame(width: 25, height: 25).foregroundStyle(Color.accentColor)
                                    }.buttonBorderShape(.circle).apply { View in
                                        if #available(iOS 26.0, *) {
                                            View.buttonStyle(.glass).glassEffect(in: Circle())
                                        } else {
                                            View.buttonStyle(.plain)
                                        }
                                    }
                                }.frame(width: 10)
                            }.listRowSeparator(.hidden).padding()

                            VStack {
                                Capsule()
                                    .fill(rule.actions.last == action ? Color.accentColor : Color.gray)
                                    .frame(width: 3, height: 50)

                                if rule.actions.last == action {
                                    Button {
                                        isPresentingAddNewActionBottomSheet = true
                                    } label: {
                                        Image(systemName: "plus.circle.fill").resizable().frame(width: 25, height: 25)
                                    }.buttonBorderShape(.circle).apply { View in
                                        if #available(iOS 26.0, *) {
                                            View.buttonStyle(.glass).glassEffect(in: Circle())
                                        } else {
                                            View.buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }

                } header: {
                    Text(String(localized: "actions_then"))
                } footer: {
                    Text(String(localized: "rules_create_info")).padding(.top)

                }.textCase(nil)

            }.disabled(isSavingRule)
                .navigationTitle(ruleName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(content: {
                    ToolbarItem(placement: .confirmationAction) {
                        if #available(iOS 26.0, *) {
                            saveButton().buttonStyle(.glassProminent)
                        } else {
                            saveButton()
                        }
                    }
                })
                .sheet(item: $actionToEdit) { action in
                    NavigationStack {
                        ActionBottomSheet(recipients: recipients, actionEditObject: action) { oldAction, modifiedAction in
                            if let index = self.rule?.actions.firstIndex(where: { $0.id == oldAction?.id }) {
                                self.rule?.actions[index] = modifiedAction
                            }

                            self.actionToEdit = nil
                        }
                    }.presentationDetents([.large])
                }.sheet(isPresented: $isPresentingAddNewActionBottomSheet) {
                    NavigationStack {
                        ActionBottomSheet(recipients: recipients, actionEditObject: nil) { _, modifiedAction in
                            self.rule!.actions.append(modifiedAction)
                            isPresentingAddNewActionBottomSheet = false
                        }
                    }
                    .presentationDetents([.large])
                }.sheet(item: $conditionToEdit) { condition in
                    NavigationStack {
                        ConditionBottomSheet(conditionEditObject: condition) { oldCondition, modifiedCondition in
                            if let index = self.rule?.conditions.firstIndex(where: { $0.id == oldCondition?.id }) {
                                self.rule?.conditions[index] = modifiedCondition
                            }

                            self.conditionToEdit = nil
                        }
                    }
                    .presentationDetents([.large])
                }.sheet(isPresented: $isPresentingAddNewConditionBottomSheet) {
                    NavigationStack {
                        ConditionBottomSheet(conditionEditObject: nil) { _, modifiedCondition in
                            self.rule!.conditions.append(modifiedCondition)
                            isPresentingAddNewConditionBottomSheet = false
                        }
                    }
                    .presentationDetents([.large])
                }
                .alert(isPresented: $showAlert) {
                    switch activeAlert {
                    case .error:
                        return Alert(
                            title: Text(errorAlertTitle),
                            message: Text(errorAlertMessage)
                        )
                    }
                }
        } else {
            VStack {
                if let errorText = errorText {
                    ContentUnavailableView {
                        Label(String(localized: "error_obtaining_rule"), systemImage: "questionmark")
                    } description: {
                        Text(errorText)
                    }.onAppear {
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
                // Only get rule if the ruleId is not empty
                if !self.ruleId.isEmpty {
                    await getRule(ruleId: self.ruleId)
                } else {
                    if let rule = self.rule {
                        updateUi(rule: rule)
                    }
                }
            }
            .navigationTitle(ruleName)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func saveButton() -> some View {
        Group {
            if isSavingRule {
                AnyView(ProgressView().progressViewStyle(.circular))
            } else {
                AnyView(
                    Button {
                        self.isSavingRule = true
                        if self.ruleId.isEmpty {
                            Task {
                                await self.createRule()
                            }
                        } else {
                            // ruleId is not empty, update rule instead
                            Task {
                                await self.updateRule()
                            }
                        }
                    } label: {
                        Text(String(localized: "save"))
                    }.disabled(self.ruleName.isEmpty)
                )
            }
        }
    }

    private func updateUi(rule: Rules) {
        conditionOperator = self.rule!.operator

        if rule.forwards {
            selectedChips.append("forwards")
        }
        if rule.replies {
            selectedChips.append("replies")
        }
        if rule.sends {
            selectedChips.append("sends")
        }
    }

    private func getRule(ruleId: String) async {
        let networkHelper = NetworkHelper()
        do {
            if let rule = try await networkHelper.getSpecificRule(ruleId: ruleId) {
                withAnimation {
                    self.rule = rule
                    updateUi(rule: rule)
                }
            }
        } catch {
            withAnimation {
                self.errorText = error.localizedDescription
            }
        }
    }

    func updateRuleObject() {
        rule!.name = ruleName
        rule!.operator = conditionOperator
        rule!.forwards = selectedChips.contains("forwards")
        rule!.replies = selectedChips.contains("replies")
        rule!.sends = selectedChips.contains("sends")
    }

    func updateRule() async {
        updateRuleObject()

        let networkHelper = NetworkHelper()
        do {
            let result = try await networkHelper.updateRule(ruleId: rule!.id, rule: rule!)
            if result == "200" {
                shouldReloadDataInParent = true
                presentationMode.wrappedValue.dismiss()
            } else {
                activeAlert = .error
                showAlert = true
                errorAlertTitle = String(localized: "error_creating_rule")
                errorAlertMessage = result
            }
        } catch {
            activeAlert = .error
            showAlert = true
            errorAlertTitle = String(localized: "error_creating_rule")
            errorAlertMessage = error.localizedDescription
            isSavingRule = false
        }
    }

    func createRule() async {
        updateRuleObject()

        let networkHelper = NetworkHelper()
        do {
            _ = try await networkHelper.createRule(rule: rule!)
            shouldReloadDataInParent = true
            presentationMode.wrappedValue.dismiss()
        } catch {
            activeAlert = .error
            showAlert = true
            errorAlertTitle = String(localized: "error_creating_rule")
            errorAlertMessage = error.localizedDescription
            isSavingRule = false
        }
    }
}

// #Preview {
//    CreateRulesView()
// }
