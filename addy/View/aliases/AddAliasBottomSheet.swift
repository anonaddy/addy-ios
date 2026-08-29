//
//  AddAliasBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 07/05/2024.
//

import addy_shared
import AppIntents
import SwiftUI
import UniformTypeIdentifiers
import WrappingHStack

struct AddAliasBottomSheet: View {
    @EnvironmentObject var mainViewState: MainViewState
    @Environment(\.dismiss) var dismiss

    #if DEBUG
        @State private var selectedFormat: String = "custom"
    #else
        @State private var selectedFormat: String = ""
    #endif

    @State private var localPart: String = ""
    @State private var localPartPlaceholder: String = .init(localized: "alias_local_part")
    @State private var description: String = ""
    @State private var descriptionPlaceholder: String = .init(localized: "description")

    @State private var aliasError: String? = ""

    @State private var formatValidationError: Bool = false
    @State private var localPartError: Bool = false

    @State private var recipientsRequestError: String? = ""

    @State var recipientsLoaded: Bool = false
    @State var selectedRecipientChips: [String] = []
    @State var recipientsChips: [AddyChipModel] = [AddyChipModel(chipId: "loading_recipients", label: String(localized: "loading_recipients"))]

    @State private var labelsRequestError: String? = ""
    @State var labelsLoaded: Bool = false
    @State var selectedLabelChips: [String] = []
    @State var labelsChips: [AddyChipModel] = [AddyChipModel(chipId: "loading_labels", label: String(localized: "loading_labels"))]

    @State var isLoadingAddButton: Bool = false

    @State private var isLabelsExpanded: Bool = false

    @State private var localPartValidationError: String?
    @State private var descriptionValidationError: String?
    @State private var showAlert: Bool = false
    @State private var errorAlertTitle = ""
    @State private var errorAlertMessage = ""
    @State private var domains: [String] = []
    @State private var sharedDomains: [String] = []
    @State private var selectedDomain: String = ""
    @State private var formats: [[String]] =
        [[String(localized: "domains_format_random_characters", comment: ""), "random_characters"],
         [String(localized: "domains_format_uuid", comment: ""), "uuid"],
         [String(localized: "domains_format_random_words", comment: ""), "random_words"],
         [String(localized: "domains_format_custom", comment: ""), "custom"],
         [String(localized: "domains_format_random_male_name", comment: ""), "random_male_name"],
         [String(localized: "domains_format_random_female_name", comment: ""), "random_female_name"],
         [String(localized: "domains_format_random_noun", comment: ""), "random_noun"]]

    let onAdded: () -> Void

    init(onAdded: @escaping () -> Void) {
        self.onAdded = onAdded
    }

    var body: some View {
        #if DEBUG
            let _ = Self._printChanges()
        #endif

        Form {
            Section {
                Picker(String(localized: "domain"), selection: $selectedDomain) {
                    ForEach(domains, id: \.self) { domain in
                        Text(domain).tag(domain)
                    }
                }

                Picker(String(localized: "alias_format"), selection: $selectedFormat) {
                    ForEach(formats, id: \.self) { format in
                        Text(format[0]).tag(format[1])
                    }
                }
                .foregroundColor(formatValidationError ? .red : nil)
                .onChange(of: selectedFormat) {
                    // When selecting another format it should reset the error
                    formatValidationError = false
                    aliasError = ""
                }

                if selectedFormat == "custom" {
                    ValidatingTextField(value: self.$localPart, placeholder: self.$localPartPlaceholder, fieldType: .text, error: $localPartValidationError)
                        .foregroundColor(localPartError ? .red : nil)
                }

            } header: {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        Text(String(format: String(localized: "add_alias_desc"), self.mainViewState.userResource?.username ?? "")).multilineTextAlignment(.center)
                        Spacer(minLength: 25)
                    }

                    VStack(alignment: .leading) {
                        Text(String(localized: "alias"))
                    }
                }.frame(maxWidth: .infinity, alignment: .center)
            } footer: {
                if let error = aliasError {
                    if !error.isEmpty {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.system(size: 15))
                            .multilineTextAlignment(.leading)
                            .padding([.horizontal], 0)
                            .onAppear {
                                HapticHelper.playHapticFeedback(hapticType: .error)
                            }
                    }
                }

            }.textCase(nil)

            Section {
                ValidatingTextField(value: self.$description, placeholder: self.$descriptionPlaceholder, fieldType: .bigText, error: $descriptionValidationError)
            } header: {
                Text(String(localized: "description"))
            }.textCase(nil)

            Section {
                AddyMultiSelectChipView(chips: $recipientsChips, selectedChips: $selectedRecipientChips, singleLine: false) { onTappedChip in
                    withAnimation {
                        if selectedRecipientChips.contains(onTappedChip.chipId) {
                            if let index = selectedRecipientChips.firstIndex(of: onTappedChip.chipId) {
                                selectedRecipientChips.remove(at: index)
                            }
                        } else {
                            selectedRecipientChips.append(onTappedChip.chipId)
                        }
                    }

                }.disabled(!recipientsLoaded)
            } header: {
                Text(String(localized: "recipients"))
            }

            DisclosureGroup(isExpanded: $isLabelsExpanded) {
                WrappingHStack(alignment: .leading, horizontalSpacing: 4, verticalSpacing: 4) {
                    ForEach(labelsChips) { chip in
                        ChipView(label: chip.label, isSelected: selectedLabelChips.contains(chip.chipId), color: Color(hex: chip.color ?? "FFFFFF"))
                            .onTapGesture {
                                withAnimation {
                                    if selectedLabelChips.contains(chip.chipId) {
                                        selectedLabelChips.removeAll { $0 == chip.chipId }
                                    } else {
                                        selectedLabelChips.append(chip.chipId)
                                    }
                                }
                            }
                    }
                }
                .disabled(!labelsLoaded).padding(.leading, -15)
            } label: {
                Text(String(localized: "labels"))
            }

            Section {
                SiriTipView(
                    intent: CreateNewAliasIntent()
                )
                .siriTipViewStyle(.automatic)
            }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())
        }
        .navigationTitle(String(localized: "add_alias", bundle: Bundle(for: SharedData.self)))
        .task {
            if domains.isEmpty {
                await loadDomains()
            }

            // By default there is 1 chip. (the loading recipients...)
            if recipientsChips.contains(where: { $0.chipId == "loading_recipients" }) {
                await getAllRecipients()
            }

            if labelsChips.contains(where: { $0.chipId == "loading_labels" }) {
                await getAllLabels()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            ToolbarItem(placement: .confirmationAction) {
                if #available(iOS 26.0, *) {
                    addAliasButton().buttonStyle(.glassProminent)
                } else {
                    addAliasButton()
                }
            }

            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Label(String(localized: "cancel", bundle: Bundle(for: SharedData.self)), systemImage: "xmark")
                }
            }
        })
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(errorAlertTitle),
                message: Text(errorAlertMessage)
            )
        }
    }

    private func addAliasButton() -> some View {
        Group {
            if isLoadingAddButton {
                ProgressView().progressViewStyle(.circular)
            } else {
                Button {
                    withAnimation {
                        isLoadingAddButton = true
                    }
                    addAlias()
                } label: {
                    Text(String(localized: "add"))
                }
            }
        }
    }

    private func addAlias() {
        // Do all the check before creating the alias
        formatValidationError = false

        if selectedFormat == "random_words" {
            if mainViewState.userResource?.hasUserFreeSubscription() ?? true {
                aliasError = String(localized: "domains_format_not_available_for_this_subscription")
                formatValidationError = true
                isLoadingAddButton = false

                return
            }
        } else if selectedFormat == "random_male_name" {
            if mainViewState.userResource?.hasUserFreeSubscription() ?? true {
                aliasError = String(localized: "domains_format_not_available_for_this_subscription")
                formatValidationError = true
                isLoadingAddButton = false
                return
            }
        } else if selectedFormat == "random_female_name" {
            if mainViewState.userResource?.hasUserFreeSubscription() ?? true {
                aliasError = String(localized: "domains_format_not_available_for_this_subscription")
                formatValidationError = true
                isLoadingAddButton = false
                return
            }
        } else if selectedFormat == "random_noun" {
            if mainViewState.userResource?.hasUserFreeSubscription() ?? true {
                aliasError = String(localized: "domains_format_not_available_for_this_subscription")
                formatValidationError = true
                isLoadingAddButton = false
                return
            }
        } else if selectedFormat == "custom" {
            // Only check on hosted instance
            if AddyIo.isUsingHostedInstance() {
                // Custom format on shared domains is possible, but only if the user has a paid subscription.
                // If the selected domain is a shared domain AND the user is a free user don't allow it.
                if sharedDomains.contains(selectedDomain), mainViewState.userResource?.hasUserFreeSubscription() ?? true {
                    aliasError = String(localized: "domains_format_custom_not_available_for_this_domain")
                    formatValidationError = true
                    isLoadingAddButton = false

                    return
                }
            }

            if localPart.isEmpty {
                aliasError = String(localized: "this_field_cannot_be_empty")
                localPartError = true
                isLoadingAddButton = false

                return
            }
        }

        Task {
            await addAliasToAccount(selectedDomain: selectedDomain, description: description, selectedFormat: selectedFormat, localPart: localPart, selectedRecipients: selectedRecipientChips, selectedLabels: selectedLabelChips)
        }
    }

    private func addAliasToAccount(selectedDomain: String, description: String, selectedFormat: String, localPart: String, selectedRecipients: [String], selectedLabels: [String]) async {
        do {
            let alias = try await AliasRepository.shared.addAlias(domain: selectedDomain, description: description, format: selectedFormat, localPart: localPart, recipients: selectedRecipients, labelIds: selectedLabels)
            UIPasteboard.general.setValue(alias.email, forPasteboardType: UTType.plainText.identifier)
            onAdded()
        } catch {
            isLoadingAddButton = false
            showAlert = true
            errorAlertTitle = String(localized: "error_adding_alias")
            errorAlertMessage = error.localizedDescription
        }
    }

    private func loadDomains() async {
        do {
            let domainOptions = try await DomainRepository.shared.getDomainOptions()
            domains = domainOptions.data
            sharedDomains = domainOptions.sharedDomains
            selectedDomain = domainOptions.defaultAliasDomain
            selectedFormat = domainOptions.defaultAliasFormat
        } catch {
            showAlert = true
            errorAlertTitle = String(localized: "something_went_wrong_retrieving_domains")
            errorAlertMessage = error.localizedDescription
        }
    }

    private func getAllRecipients() async {
        do {
            let recipients = try await RecipientRepository.shared.getRecipients(verifiedOnly: true)
            recipientsChips = []
            recipientsLoaded = true
            withAnimation {
                for recipient in recipients {
                    recipientsChips.append(AddyChipModel(chipId: recipient.id, label: recipient.email))
                }
            }
        } catch {
            recipientsRequestError = error.localizedDescription
        }
    }

    private func getAllLabels() async {
        do {
            let labels = try await LabelRepository.shared.getLabels()
            labelsChips = []
            labelsLoaded = true
            withAnimation {
                for label in labels.data {
                    labelsChips.append(AddyChipModel(chipId: label.id, label: label.name, color: label.colour))
                }
            }
        } catch {
            labelsRequestError = error.localizedDescription
        }
    }
}

#Preview {
    AddAliasBottomSheet(onAdded: {
        // Dummy function for preview
    })
}
