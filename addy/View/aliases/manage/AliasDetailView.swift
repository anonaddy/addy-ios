//
//  AliasDetailView.swift
//  addy
//
//  Created by Stijn van de Water on 08/05/2024.
//

import SwiftUI
import addy_shared
import Lottie
import UniformTypeIdentifiers

struct AliasDetailView: View {
    
    enum ActiveAlert {
        case reachedMaxAliases, deleteAliases, restoreAlias, forgetAlias, error
    }
    
    let aliasId: String
    @State var aliasEmail: String
    @State var shouldDisableAlias: Bool = false
    
    @Binding var shouldReloadDataInParent: Bool
    
    @State private var activeAlert: ActiveAlert = .reachedMaxAliases
    @State private var showAlert: Bool = false
    @State private var isDeletingAlias: Bool = false
    @State private var isRestoringAlias: Bool = false
    @State private var isForgettingAlias: Bool = false
    
    @State private var errorAlertTitle = ""
    @State private var errorAlertMessage = ""
    @EnvironmentObject var mainViewState: MainViewState
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @State private var alias: Aliases? = nil
    @State private var errorText: String? = nil
    
    @State private var sendToRecipients: String? = nil
    
    @State private var isAliasActive: Bool = false
    @State private var isSwitchingAliasActiveState: Bool = false
    @State private var isSwitchingAttachedRecipientsOnlyEnabledState: Bool = false
    @State private var isAliasBeingWatched: Bool = false
    @State private var isAttachedRecipientsOnlyEnabled: Bool = false
    @State private var isPresentingEditAliasDescriptionBottomSheet = false
    @State private var isPresentingEditAliasRecipientsBottomSheet = false
    @State private var isPresentingEditAliasFromNameBottomSheet = false
    @State private var isPresentingEditAliasSendMailRecipientBottomSheet = false
    
    @State private var copiedToClipboard: Bool = false
    @State private var aliasDeactivatedOverlayShown: Bool = false
    
    @State private var chartData: [Double] = [0,0,0,0]
    
    @State private var clients: [ThirdPartyMailClient] = []
    @State private var isPresentingEmailSelectionDialog: Bool = false

    
    init(aliasId: String, aliasEmail: String?, shouldReloadDataInParent: Binding<Bool>? = nil, shouldDisableAlias: Bool = false) {
        self.aliasId = aliasId
        self.aliasEmail = aliasEmail ?? ""
        self.shouldDisableAlias = shouldDisableAlias
        _shouldReloadDataInParent = shouldReloadDataInParent ?? .constant(false)
        
    }
    
    
    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
        if let alias = alias {
            Form {
                Section {
                    VStack(alignment: .leading){
                        HStack{
                            
                            Color.clear
                                .aspectRatio(1, contentMode: .fill)
                                    .overlay(
                                        BarChart()
                                            .data(chartData)
                                            .chartStyle(ChartStyle(backgroundColor: .white,
                                                                   foregroundColor: [ColorGradient(.portalOrange, .portalOrange.opacity(0.7)),
                                                                                     ColorGradient(.easternBlue, .easternBlue.opacity(0.7)),
                                                                                     ColorGradient(.portalBlue, .portalBlue.opacity(0.7)),
                                                                                     ColorGradient(.softRed, .softRed.opacity(0.7))]))
                                            .allowsHitTesting(false)
                                            .padding(.horizontal).padding(.top)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 13))
                                    .frame(maxWidth: 150)
                            Spacer()
                            
                            VStack(alignment: .trailing){
                                Spacer()
                                
                                Label(title: {
                                    Text(String(format: String(localized: "d_forwarded"), "\(alias.emails_forwarded)"))
                                        .font(.subheadline)
                                        .foregroundStyle(Color.gray)
                                        .minimumScaleFactor(0.5)
                                        .lineLimit(1)
                                    
                                }, icon: {
                                    Image(systemName: "tray")
                                        .foregroundColor(.portalOrange)
                                        .font(.system(size: 18, weight: .bold))
                                } )
                                Spacer()
                                Label(title: {
                                    Text(String(format: String(localized: "d_replied"), "\(alias.emails_replied)"))
                                        .font(.subheadline)
                                        .foregroundStyle(Color.gray)
                                        .minimumScaleFactor(0.5)
                                        .lineLimit(1)
                                    
                                }, icon: {
                                    Image(systemName: "arrow.turn.up.left")
                                        .foregroundColor(.easternBlue)
                                        .font(.system(size: 18, weight: .bold))
                                } )
                                Spacer()
                                Label(title: {
                                    Text(String(format: String(localized: "d_sent"), "\(alias.emails_sent)"))
                                        .font(.subheadline)
                                        .foregroundStyle(Color.gray)
                                        .minimumScaleFactor(0.5)
                                        .lineLimit(1)
                                    
                                }, icon: {
                                    Image(systemName: "paperplane")
                                        .foregroundColor(.portalBlue)
                                        .font(.system(size: 18, weight: .bold))
                                } )
                                Spacer()
                                Label(title: {
                                    Text(String(format: String(localized: "d_blocked"), "\(alias.emails_blocked)"))
                                        .font(.subheadline)
                                        .foregroundStyle(Color.gray)
                                        .minimumScaleFactor(0.5)
                                        .lineLimit(1)
                                    
                                }, icon: {
                                    Image(systemName: "slash.circle")
                                        .foregroundColor(.softRed)
                                        .font(.system(size: 18, weight: .bold))
                                } )
                                Spacer()
                                
                                
                            }
                            .padding(.leading, 15)
                            .labelStyle(MyAliasLabelStyle())
                        }
                        Spacer()
                        HStack {
                            
                            Button(action: {
                                self.copyToClipboard(alias: alias)
                            }) {
                                Label(String(localized: "copy_alias"), systemImage: "clipboard")
                                    .foregroundColor(.white)
                                    .frame(maxWidth:.infinity, maxHeight: 24).frame(alignment: .leading)
                                    .font(.system(size: 14))
                            }
                            Spacer()
                            Button(action: {
                                isPresentingEditAliasSendMailRecipientBottomSheet = true
                            }) {
                                Label(String(localized: "send_mail"), systemImage: "paperplane")
                                    .foregroundColor(.white)
                                    .frame(maxWidth:.infinity, maxHeight: 24).frame(alignment: .leading)
                                    .font(.system(size: 14))
                            }
                        }.padding(.top, 8).buttonStyle(.borderedProminent)
                        
                        
                    }.frame(height: 200)}
                
                Section {
                    
                    AddyToggle(isOn: $isAliasActive, isLoading: isSwitchingAliasActiveState, title: alias.active ? String(localized: "alias_activated") : String(localized: "alias_deactivated"), description: String(localized: "alias_status_desc"))
                        .onChange(of: isAliasActive) {
                            // Only fire when the value is NOT the same as the value already in the model
                            if (isAliasActive != alias.active){
                                self.isSwitchingAliasActiveState = true
                                
                                if (alias.active){
                                    Task {
                                        await self.deactivateAlias(alias: alias)
                                    }
                                } else {
                                    Task {
                                        await self.activateAlias(alias: alias)
                                    }
                                }
                            }
                            
                        }
                    
                    AddyToggle(isOn: $isAliasBeingWatched, title: String(localized: "watch_alias"), description: String(localized: "watch_alias_desc"))
                        .onChange(of: isAliasBeingWatched) {
                            
                            // This changes the icon on the view in aliasesview
                            // So we update the list when coming back
                            shouldReloadDataInParent = true
                            
                            // Only fire when the value is NOT the same as the value already in the model
                            if (isAliasBeingWatched != AliasWatcher().getAliasesToWatch().contains(aliasId)){
                                if (AliasWatcher().getAliasesToWatch().contains(aliasId)){
                                    AliasWatcher().removeAliasToWatch(alias: aliasId)
                                } else {
                                    if (!AliasWatcher().addAliasToWatch(alias: aliasId)) {
                                        // Could not add to watchlist (watchlist reached max?)
                                        activeAlert = .reachedMaxAliases
                                        showAlert = true
                                        isAliasBeingWatched = false
                                    }
                                }
                            }
                        }
                    
                    
                    
                    AddyToggle(isOn: $isAttachedRecipientsOnlyEnabled, isLoading: isSwitchingAttachedRecipientsOnlyEnabledState, title: String(localized: "limit_replies_sends_attached_recipients_only"), description: String(localized: "limit_replies_sends_attached_recipients_only_desc"))
                        .onChange(of: isAttachedRecipientsOnlyEnabled) {
                            // Only fire when the value is NOT the same as the value already in the model
                            if (isAttachedRecipientsOnlyEnabled != alias.attached_recipients_only){
                                self.isSwitchingAttachedRecipientsOnlyEnabledState = true
                                
                                if (alias.attached_recipients_only){
                                    Task {
                                        await self.disableAttachedRecipientsOnly(alias: alias)
                                    }
                                } else {
                                    Task {
                                        await self.enableAttachedRecipientsOnly(alias: alias)
                                    }
                                }
                            }
                            
                        }
      
                    
                    AddySection(title: String(localized: "description"), description: alias.description ?? String(localized: "alias_no_description"), leadingSystemimage: nil, trailingSystemimage: "pencil"){
                        isPresentingEditAliasDescriptionBottomSheet = true
                    }
                    
                    
                    
                    AddySection(title: String(localized: "recipients"), description: getRecipients(alias: alias), leadingSystemimage: nil, trailingSystemimage: "pencil"){
                        isPresentingEditAliasRecipientsBottomSheet = true
                    }
                    
                    AddySection(title: String(localized: "from_name"), description: getFromName(alias: alias), leadingSystemimage: nil, trailingSystemimage: "pencil"){
                        if !mainViewState.userResource!.hasUserFreeSubscription(){
                            isPresentingEditAliasFromNameBottomSheet = true
                        } else {
                            HapticHelper.playHapticFeedback(hapticType: .error)
                        }
                    }
                    
                    AddySection(title: String(localized: "last_forwarded"),
                                description: alias.last_forwarded != nil ? DateTimeUtils.convertStringToLocalTimeZoneString(alias.last_forwarded) : String(localized: "unknown"),
                                leadingSystemimage: nil, trailingSystemimage: nil){}
                    AddySection(title: String(localized: "last_replied"),
                                description: alias.last_replied != nil ? DateTimeUtils.convertStringToLocalTimeZoneString(alias.last_replied) : String(localized: "unknown"),
                                leadingSystemimage: nil, trailingSystemimage: nil){}
                    AddySection(title: String(localized: "last_sent"),
                                description: alias.last_sent != nil ? DateTimeUtils.convertStringToLocalTimeZoneString(alias.last_sent) : String(localized: "unknown"),
                                leadingSystemimage: nil, trailingSystemimage: nil){}
                    AddySection(title: String(localized: "last_blocked"),
                                description: alias.last_blocked != nil ? DateTimeUtils.convertStringToLocalTimeZoneString(alias.last_blocked) : String(localized: "unknown"),
                                leadingSystemimage: nil, trailingSystemimage: nil){}
                    AddySection(title: String(localized: "created_at"),
                                description: alias.created_at != nil ? DateTimeUtils.convertStringToLocalTimeZoneString(alias.created_at) : String(localized: "unknown"),
                                leadingSystemimage: nil, trailingSystemimage: nil){}
                    AddySection(title: String(localized: "updated_at"),
                                description: alias.updated_at != nil ? DateTimeUtils.convertStringToLocalTimeZoneString(alias.updated_at) : String(localized: "unknown"),
                                leadingSystemimage: nil, trailingSystemimage: nil){}
                    
                    
                    
                    
                }header: {
                    Text(String(localized: "general"))
                }.disabled(alias.deleted_at != nil).opacity(alias.deleted_at != nil ? 0.5 : 1.0) // If alias is deleted, disable the entire section and set opacity
                
                Section {
                    
                    // If alias is not deleted, show the delete button section
                    if alias.deleted_at == nil {
                        AddySectionButton(title: String(localized: "delete_alias"), description: String(localized: "delete_alias_desc"),
                                          leadingSystemimage: "trash", colorAccent: .softRed, isLoading: isDeletingAlias){
                            activeAlert = .deleteAliases
                            showAlert = true
                        }
                    }
                    
                    // If alias is deleted, show the restore button section
                    if alias.deleted_at != nil {
                        AddySectionButton(title: String(localized: "restore_alias"), description: String(localized: "restore_alias_desc"),
                                          leadingSystemimage: "arrow.up.trash", colorAccent: .accentColor, isLoading: isRestoringAlias){
                            activeAlert = .restoreAlias
                            showAlert = true
                        }
                    }
                    
                    AddySectionButton(title: String(localized: "forget_alias"), description: String(localized: "forget_alias_desc"),
                                      leadingSystemimage: "eraser", colorAccent: .red, isLoading: isForgettingAlias){
                        activeAlert = .forgetAlias
                        showAlert = true
                    }
                    
                }
                
            }
            .refreshable {
                await getAlias(aliasId: self.aliasId)
            }
            .overlay {
                ToastOverlay(showToast: $copiedToClipboard, text: String(localized: "copied_to_clipboard"))
                ToastOverlay(showToast: $aliasDeactivatedOverlayShown, text: String(localized: "alias_deactivated"))
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
            .onAppear(perform: {
                // Get the available mail clients
                self.clients = ThirdPartyMailClient.clients.filter( {ThirdPartyMailer.isMailClientAvailable($0)})
                self.clients.append(ThirdPartyMailClient.systemDefault)
                
                if shouldDisableAlias {
                    
                    if alias.active {
                        self.isSwitchingAliasActiveState = true
                        
                        Task {
                            await self.deactivateAlias(alias: alias, shouldShowToastOnFinished: true)
                        }
                    }
                    self.shouldDisableAlias = false
                }
            })
            .disabled(isDeletingAlias || isRestoringAlias || isForgettingAlias)
            .navigationTitle(self.aliasEmail)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isPresentingEditAliasDescriptionBottomSheet) {
                NavigationStack {
                    EditAliasDescriptionBottomSheet(aliasId: alias.id, description: alias.description ?? ""){ alias in
                        self.alias = alias
                        isPresentingEditAliasDescriptionBottomSheet = false
                        
                        // This changes the last updated time of the alias which is being shown in the list in the aliasesView.
                        // So we update the list when coming back
                        shouldReloadDataInParent = true
                        
                    }
                }
                .presentationDetents([.large])
            }
            .sheet(isPresented: $isPresentingEditAliasRecipientsBottomSheet) {
                NavigationStack {
                    EditAliasRecipientsBottomSheet(aliasId: alias.id, selectedRecipientsIds: getRecipientsIds(recipients: alias.recipients)){ alias in
                        self.alias = alias
                        isPresentingEditAliasRecipientsBottomSheet = false
                        
                        // This changes the last updated time of the alias which is being shown in the list in the aliasesView.
                        // So we update the list when coming back
                        shouldReloadDataInParent = true
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $isPresentingEditAliasFromNameBottomSheet) {
                NavigationStack {
                    EditAliasFromNameBottomSheet(aliasId: alias.id, aliasEmail: alias.email, fromName: alias.from_name){ alias in
                        self.alias = alias
                        isPresentingEditAliasFromNameBottomSheet = false
                        
                        // This changes the last updated time of the alias which is being shown in the list in the aliasesView.
                        // So we update the list when coming back
                        shouldReloadDataInParent = true
                    }
                }
                .presentationDetents([.large])
            }
            .sheet(isPresented: $isPresentingEditAliasSendMailRecipientBottomSheet) {
                NavigationStack {
                    EditAliasSendMailRecipientBottomSheet(aliasEmail: alias.email, onPressSend: { addresses in
                        self.onPressSend(client: nil, sendToRecipients: addresses)
                        isPresentingEditAliasSendMailRecipientBottomSheet = false
                    }, onPressCopy: { addresses in
                        self.onPressCopy(sendToRecipients: addresses)
                        isPresentingEditAliasSendMailRecipientBottomSheet = false
                    })
                }
                .presentationDetents([.large])
            }
            .alert(isPresented: $showAlert) {
                switch activeAlert {
                case .reachedMaxAliases:
                    return Alert(title: Text(String(localized: "aliaswatcher_max_reached")), message: Text(String(localized: "aliaswatcher_max_reached_desc")), dismissButton: .default(Text(String(localized: "understood"))))
                case .deleteAliases:
                    return Alert(title: Text(String(localized: "delete_alias")), message: Text(String(localized: "delete_alias_confirmation_desc")), primaryButton: .destructive(Text(String(localized: "delete"))){
                        isDeletingAlias = true
                        
                        Task {
                            await deleteAlias(alias: alias)
                        }
                    }, secondaryButton: .cancel())
                case .restoreAlias:
                    return Alert(title: Text(String(localized: "restore_alias")), message: Text(String(localized: "restore_alias_confirmation_desc")), primaryButton: .default(Text(String(localized: "restore"))){
                        isRestoringAlias = true
                        
                        Task {
                            await restoreAlias(alias: alias)
                        }
                    }, secondaryButton: .cancel())
                case .forgetAlias:
                    return Alert(title: Text(String(localized: "forget_alias")), message: Text(String(localized: "forget_alias_confirmation_desc")), primaryButton: .destructive(Text(String(localized: "forget"))){
                        isForgettingAlias = true
                        
                        Task {
                            await forgetAlias(alias: alias)
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
                        Label(String(localized: "error_obtaining_alias"), systemImage: "questionmark")
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
                await getAlias(aliasId: self.aliasId)
            }
            
            .navigationTitle(self.aliasEmail)
            .navigationBarTitleDisplayMode(.inline)
        }
        
    }
    
    private func addQuickActions(alias: Aliases) {
        if !mainViewState.encryptedSettingsManager.getSettingsBool(key: .privacyMode){
            // Only add shortcuts when PRIVACY_MODE is disabled to hide aliases
            UIApplication.shared.shortcutItems = [
                UIApplicationShortcutItem(type: "host.stjin.addy.shortcut_open_alias_\(alias.id)", localizedTitle: alias.email, localizedSubtitle: nil, icon: UIApplicationShortcutIcon.init(type: .time)),
            ]
        }
    }
    
    private func getRecipientsIds(recipients: [Recipients]?) -> [String] {
        var idArray = [String]()
        
        if let recipients = recipients {
            recipients.forEach { recipient in
                idArray.append(recipient.id)
            }
        }
        
        return idArray
    }
    
    private func getFromName(alias: Aliases) -> String {
        
        if mainViewState.userResource!.hasUserFreeSubscription() {
            return String(localized: "feature_not_available_subscription")
        }
        else {
            // Set description based on alias.from_name and initialize the bottom dialog fragment
            if let fromName = alias.from_name {
                return fromName
            } else {
                return String(localized: "alias_no_from_name")
            }
        }
        
    }
    
    private func updateUi(alias: Aliases){
        var aliasTotalCount =  Double(alias.emails_forwarded + alias.emails_replied + alias.emails_sent + alias.emails_blocked)
        aliasTotalCount = aliasTotalCount != 0.0 ? aliasTotalCount : 10.0 // To prevent dividing by 0
        
        
        let aliasEmailForwardedProgress =  (Double(alias.emails_forwarded) / aliasTotalCount) * 100
        let aliasEmailRepliedProgress = (Double(alias.emails_replied) / aliasTotalCount) * 100
        let aliasEmailSentProgress = (Double(alias.emails_sent) / aliasTotalCount) * 100
        let aliasEmailBlockedProgress = (Double(alias.emails_blocked) / aliasTotalCount) * 100
        
        self.chartData = [aliasEmailForwardedProgress, aliasEmailRepliedProgress, aliasEmailSentProgress, aliasEmailBlockedProgress]
        
        addQuickActions(alias: alias)
        
        
    }
    
    private func onPressSend(client: ThirdPartyMailClient? = nil, sendToRecipients: String) {
        guard let alias = alias else { return }
        
        if client == nil {
            isPresentingEmailSelectionDialog = true
            self.sendToRecipients = sendToRecipients
        } else {
            // Get recipients
            let recipients = AnonAddyUtils.getSendAddress(recipientEmails: sendToRecipients.split(separator: ",").map { String($0) }, alias: alias)
            
            onPressCopy(sendToRecipients: sendToRecipients)
            
            // Prepare mailto URL
            let mailtoURL = client!.composeURL(to: recipients)
            
            // Open mailto URL
            UIApplication.shared.open(mailtoURL)
            
        }
    }
    
    private func onPressCopy(sendToRecipients: String) {
        guard let alias = alias else { return }
        
        // Get recipients
        let recipients = AnonAddyUtils.getSendAddress(recipientEmails: sendToRecipients.split(separator: ",").map { String($0) }, alias: alias)
        
        // Copy the email addresses to clipboard
        UIPasteboard.general.setValue(recipients.joined(separator: ";"),forPasteboardType: UTType.plainText.identifier)
        showCopiedToClipboardToast()
    }
    
    func getRecipients(alias: Aliases) -> String{
        // Set recipients
        var recipients: String = ""
        var count = 0
        if let aliasRecipients = alias.recipients, !aliasRecipients.isEmpty {
            // get the first 2 recipients and list them
            var buf = ""
            for recipient in aliasRecipients {
                if count < 2 {
                    if !buf.isEmpty {
                        buf.append("\n")
                    }
                    buf.append(recipient.email)
                    count += 1
                }
            }
            recipients = buf
            
            // Check if there are more than 2 recipients in the list
            if aliasRecipients.count > 2 {
                // If this is the case add a "x more" on the third rule
                // X is the total amount minus the 2 listed above
                recipients += "\n"
                recipients += String(format: NSLocalizedString(String(localized: "_more"), comment: ""), String(aliasRecipients.count - 2))
            }
        } else {
            recipients = String(localized: "default_recipient")
        }
        
        return recipients
    }
    
    private func showCopiedToClipboardToast(){
        withAnimation(.snappy) {
            copiedToClipboard = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.snappy) {
                copiedToClipboard = false
            }
        }
    }
    
    private func showAliasDeactivatedToast(){
        withAnimation(.snappy) {
            aliasDeactivatedOverlayShown = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.snappy) {
                aliasDeactivatedOverlayShown = false
            }
        }
    }
    
    private func copyToClipboard(alias: Aliases) {
        UIPasteboard.general.setValue(alias.email,forPasteboardType: UTType.plainText.identifier)
        showCopiedToClipboardToast()
    }
    
    private func activateAlias(alias: Aliases) async {
        let networkHelper = NetworkHelper()
        do {
            let activatedAlias = try await networkHelper.activateSpecificAlias(aliasId: alias.id)
            self.isSwitchingAliasActiveState = false
            self.alias = activatedAlias
            self.isAliasActive = true
            shouldReloadDataInParent = true
        } catch {
            self.isSwitchingAliasActiveState = false
            self.isAliasActive = false
            activeAlert = .error
            showAlert = true
            errorAlertTitle = String(localized: "error_edit_active")
            errorAlertMessage = error.localizedDescription
        }
    }
    
    
    private func enableAttachedRecipientsOnly(alias: Aliases) async {
        let networkHelper = NetworkHelper()
        do {
            let activatedAlias = try await networkHelper.activateAttachedRecipientsOnly(aliasId: alias.id)
            self.isSwitchingAttachedRecipientsOnlyEnabledState = false
            self.alias = activatedAlias
            self.isAttachedRecipientsOnlyEnabled = true
            shouldReloadDataInParent = true
        } catch {
            self.isSwitchingAttachedRecipientsOnlyEnabledState = false
            self.isAttachedRecipientsOnlyEnabled = false
            activeAlert = .error
            showAlert = true
            errorAlertTitle = String(localized: "error_attached_recipients_only_status")
            errorAlertMessage = error.localizedDescription
        }
    }
    
    private func disableAttachedRecipientsOnly(alias: Aliases) async {
        let networkHelper = NetworkHelper()
        do {
            let result = try await networkHelper.deactivateAttachedRecipientsOnly(aliasId: alias.id)
            self.isSwitchingAttachedRecipientsOnlyEnabledState = false
            if result == "204" {
                self.alias?.attached_recipients_only = false
                self.isAttachedRecipientsOnlyEnabled = false
                shouldReloadDataInParent = true
            } else {
                self.isAttachedRecipientsOnlyEnabled = true
                activeAlert = .error
                showAlert = true
                errorAlertTitle = String(localized: "error_attached_recipients_only_status")
                errorAlertMessage = result
            }
        } catch {
            self.isSwitchingAttachedRecipientsOnlyEnabledState = false
            self.isAttachedRecipientsOnlyEnabled = true
            activeAlert = .error
            showAlert = true
            errorAlertTitle = String(localized: "error_forgetting_alias")
            errorAlertMessage = error.localizedDescription
        }
    }
    
    
    
    
    private func restoreAlias(alias: Aliases) async {
        let networkHelper = NetworkHelper()
        do {
            if let restoredAlias = try await networkHelper.restoreAlias(aliasId: alias.id) {
                self.isRestoringAlias = false
                self.alias = restoredAlias
                self.isAliasActive = restoredAlias.active
                shouldReloadDataInParent = true
            }
        } catch {
            self.isRestoringAlias = false
            activeAlert = .error
            showAlert = true
            errorAlertTitle = String(localized: "error_restoring_alias")
            errorAlertMessage = error.localizedDescription
        }
    }
    
    
    private func forgetAlias(alias: Aliases) async {
        let networkHelper = NetworkHelper()
        do {
            let result = try await networkHelper.forgetAlias(aliasId: alias.id)
            self.isForgettingAlias = false
            if result == "204" {
                shouldReloadDataInParent = true
                self.presentationMode.wrappedValue.dismiss()
            } else {
                activeAlert = .error
                showAlert = true
                errorAlertTitle = String(localized: "error_forgetting_alias")
                errorAlertMessage = result
            }
        } catch {
            self.isForgettingAlias = false
            activeAlert = .error
            showAlert = true
            errorAlertTitle = String(localized: "error_forgetting_alias")
            errorAlertMessage = error.localizedDescription
        }
    }
    
    private func deactivateAlias(alias: Aliases, shouldShowToastOnFinished: Bool = false) async {
        let networkHelper = NetworkHelper()
        do {
            let result = try await networkHelper.deactivateSpecificAlias(aliasId: alias.id)
            self.isSwitchingAliasActiveState = false
            if result == "204" {
                self.alias?.active = false
                self.isAliasActive = false
                shouldReloadDataInParent = true
                if shouldShowToastOnFinished {
                    showAliasDeactivatedToast()
                }
            } else {
                self.isAliasActive = true
                activeAlert = .error
                showAlert = true
                errorAlertTitle = String(localized: "error_edit_active")
                errorAlertMessage = result
            }
        } catch {
            self.isSwitchingAliasActiveState = false
            self.isAliasActive = true
            activeAlert = .error
            showAlert = true
            errorAlertTitle = String(localized: "error_edit_active")
            errorAlertMessage = error.localizedDescription
        }
    }
    
    private func deleteAlias(alias: Aliases) async {
        let networkHelper = NetworkHelper()
        do {
            let result = try await networkHelper.deleteAlias(aliasId: alias.id)
            self.isDeletingAlias = false
            if result == "204" {
                shouldReloadDataInParent = true
                self.presentationMode.wrappedValue.dismiss()
            } else {
                activeAlert = .error
                showAlert = true
                errorAlertTitle = String(localized: "error_deleting_alias")
                errorAlertMessage = result
            }
        } catch {
            self.isDeletingAlias = false
            activeAlert = .error
            showAlert = true
            errorAlertTitle = String(localized: "error_deleting_alias")
            errorAlertMessage = error.localizedDescription
        }
    }
    
    
    private func getAlias(aliasId: String) async {
        let networkHelper = NetworkHelper()
        do {
            if let alias = try await networkHelper.getSpecificAlias(aliasId: aliasId){
                withAnimation {
                    self.isAliasActive = alias.active
                    self.isAliasBeingWatched = AliasWatcher().getAliasesToWatch().contains(aliasId)
                    
                    self.alias = alias
                    self.aliasEmail = alias.email
                    self.updateUi(alias: alias)
                }
            }
        } catch {
            
            // Reset this value to prevent re-opening the AliasDetailView when coming back to the app later if the alias failed to load
            
            MainViewState.shared.showAliasWithId = nil // This will close the aliasDetailView
            MainViewState.shared.aliasToDisable = nil // This will close the aliasDetailView
            
            withAnimation {
                self.errorText = error.localizedDescription
            }
        }
    }
    
}


//#Preview {
//    AliasDetailView(aliasId: "6a866f49-5a0b-4c7e-bc45-f46bf019c4ed", aliasEmail: "PLACEHOLDER", shouldReloadDataInParent: false)
//}
