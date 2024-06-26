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
    
    @State private var isAliasActive: Bool = false
    @State private var isSwitchingAliasActiveState: Bool = false
    @State private var isAliasBeingWatched: Bool = false
    @State private var isPresentingEditAliasDescriptionBottomSheet = false
    @State private var isPresentingEditAliasRecipientsBottomSheet = false
    @State private var isPresentingEditAliasFromNameBottomSheet = false
    @State private var isPresentingEditAliasSendMailRecipientBottomSheet = false
    
    @State private var copiedToClipboard: Bool = false
    
    @State private var chartData: [Double] = [0,0,0,0]
    
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
                            BarChart()
                                .data(chartData)
                                .chartStyle(ChartStyle(backgroundColor: .white,
                                                       foregroundColor: [ColorGradient(.portalOrange, .portalOrange.opacity(0.7)),
                                                                         ColorGradient(.easternBlue, .easternBlue.opacity(0.7)),
                                                                         ColorGradient(.portalBlue, .portalBlue.opacity(0.7)),
                                                                         ColorGradient(.softRed, .softRed.opacity(0.7))]))
                                .frame(maxWidth: .infinity)
                            Spacer()
                            
                            VStack(alignment: .leading){
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
                                Label(copiedToClipboard ? String(localized: "copied") : String(localized: "copy_alias"), systemImage: "clipboard")
                                    .foregroundColor(.white)
                                    .frame(maxWidth:.infinity, maxHeight: 20).frame(alignment: .leading)
                                    .font(.system(size: 14))
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.accentColor)
                            .contentTransition(.symbolEffect(.replace))
                            Spacer()
                            Button(action: {
                                isPresentingEditAliasSendMailRecipientBottomSheet = true
                            }) {
                                Label(String(localized: "send_mail"), systemImage: "paperplane")
                                    .foregroundColor(.white)
                                    .frame(maxWidth:.infinity, maxHeight: 20).frame(alignment: .leading)
                                    .font(.system(size: 14))
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.accentColor)
                            .contentTransition(.symbolEffect(.replace))
                        }.padding(.top, 8)
                        
                        
                    }.frame(height: 200)}.buttonStyle(PlainButtonStyle())
                
                Section {
                    
                    AddyToggle(isOn: $isAliasActive, isLoading: isSwitchingAliasActiveState, title: alias.active ? String(localized: "alias_activated") : String(localized: "alias_deactivated"), description: String(localized: "watch_alias_desc"))
                        .onAppear {
                            self.isAliasActive = alias.active
                        }
                        .onChange(of: isAliasActive) {
                            
                            // Only fire when the value is NOT the same as the value already in the model
                            if (isAliasActive != alias.active){
                                //perform your action here...
                                self.isSwitchingAliasActiveState = true
                                
                                if (alias.active){
                                    DispatchQueue.global(qos: .background).async {
                                        self.deactivateAlias(alias: alias)
                                    }
                                } else {
                                    DispatchQueue.global(qos: .background).async {
                                        self.activateAlias(alias: alias)
                                    }
                                }
                            }
                            
                        }
                    
                    AddyToggle(isOn: $isAliasBeingWatched, title: String(localized: "watch_alias"), description: String(localized: "watch_alias_desc"))
                        .onAppear {
                            self.isAliasBeingWatched = AliasWatcher().getAliasesToWatch().contains(aliasId)
                        }
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
                                description: alias.last_forwarded != nil ? DateTimeUtils.turnStringIntoLocalString(alias.last_forwarded) : String(localized: "unknown"),
                                leadingSystemimage: nil, trailingSystemimage: nil){}
                    AddySection(title: String(localized: "last_replied"),
                                description: alias.last_replied != nil ? DateTimeUtils.turnStringIntoLocalString(alias.last_replied) : String(localized: "unknown"),
                                leadingSystemimage: nil, trailingSystemimage: nil){}
                    AddySection(title: String(localized: "last_sent"),
                                description: alias.last_sent != nil ? DateTimeUtils.turnStringIntoLocalString(alias.last_sent) : String(localized: "unknown"),
                                leadingSystemimage: nil, trailingSystemimage: nil){}
                    AddySection(title: String(localized: "last_blocked"),
                                description: alias.last_blocked != nil ? DateTimeUtils.turnStringIntoLocalString(alias.last_blocked) : String(localized: "unknown"),
                                leadingSystemimage: nil, trailingSystemimage: nil){}
                    
                    
                    
                    
                }header: {
                    Text(String(localized: "general"))
                }.disabled(alias.deleted_at != nil) // If alias is deleted, disable the entire section
                
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
            .onAppear(perform: {
                if shouldDisableAlias {
                    
                    if alias.active {
                        self.isSwitchingAliasActiveState = true
                        
                        DispatchQueue.global(qos: .background).async {
                            self.deactivateAlias(alias: alias)
                        }
                    }
                    self.shouldDisableAlias = false
                }
                
                // Reset this value to prevent re-opening the AliasDetailView when coming back to the app later
                mainViewState.showAliasWithId = nil
                mainViewState.aliasToDisable = nil
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
                    EditAliasSendMailRecipientBottomSheet(aliasEmail: alias.email){ addresses in
                        self.onPressSend(toString: addresses)
                        isPresentingEditAliasSendMailRecipientBottomSheet = false
                        
                    }
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
                                
                                DispatchQueue.global(qos: .background).async {
                                    deleteAlias(alias: alias)
                                }
                            }, secondaryButton: .cancel())
                        case .restoreAlias:
                            return Alert(title: Text(String(localized: "restore_alias")), message: Text(String(localized: "restore_alias_confirmation_desc")), primaryButton: .default(Text(String(localized: "restore"))){
                                isRestoringAlias = true
                                
                                DispatchQueue.global(qos: .background).async {
                                    restoreAlias(alias: alias)
                                }
                            }, secondaryButton: .cancel())
                        case .forgetAlias:
                            return Alert(title: Text(String(localized: "forget_alias")), message: Text(String(localized: "forget_alias_confirmation_desc")), primaryButton: .destructive(Text(String(localized: "forget"))){
                                isForgettingAlias = true
                                
                                DispatchQueue.global(qos: .background).async {
                                    forgetAlias(alias: alias)
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
                getAlias(aliasId: self.aliasId)
            }
           
            .navigationTitle(self.aliasEmail)
            .navigationBarTitleDisplayMode(.inline)
        }
        
    }
    
    private func addQuickActions(alias: Aliases) {
        UIApplication.shared.shortcutItems = [
            UIApplicationShortcutItem(type: "host.stjin.addy.shortcut_open_alias_\(alias.id)", localizedTitle: alias.email, localizedSubtitle: nil, icon: UIApplicationShortcutIcon.init(type: .time)),
        ]
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
            
            //            // Initialize the bottom dialog fragment
            //            editAliasFromNameBottomDialogFragment = EditAliasFromNameBottomDialogFragment.newInstance(
            //                alias.id,
            //                alias.email,
            //                alias.fromName
            //            )
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
    
    private func onPressSend(toString: String) {
            guard let alias = alias else { return }
            // Get recipients
            let recipients = AnonAddyUtils.getSendAddress(recipientEmails: toString, alias: alias)
            
            // Copy the email addresses to clipboard
            UIPasteboard.general.setValue(recipients.joined(separator: ";"),forPasteboardType: UTType.plainText.identifier)

            // Prepare mailto URL
        let mailtoURL = AnonAddyUtils.createMailtoURL(recipients: recipients)
            
            // Open mailto URL
            if let url = mailtoURL {
                UIApplication.shared.open(url)
            }
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
    
    func copyToClipboard(alias: Aliases) {
        UIPasteboard.general.setValue(alias.email,forPasteboardType: UTType.plainText.identifier)
        
        
        withAnimation {
            self.copiedToClipboard = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                self.copiedToClipboard = false
            }
        }
        
    }
    
    private func activateAlias(alias:Aliases) {
        let networkHelper = NetworkHelper()
        networkHelper.activateSpecificAlias(completion: { alias, error in
            DispatchQueue.main.async {
                self.isSwitchingAliasActiveState = false
                
                if let alias = alias {
                    self.alias = alias
                    self.isAliasActive = true
                    shouldReloadDataInParent = true
                } else {
                    self.isAliasActive = false
                    activeAlert = .error
                    showAlert = true
                    errorAlertTitle = String(localized: "error_forgetting_alias")
                    errorAlertMessage = error ?? String(localized: "error_unknown_refer_to_logs")
                }
            }
        },aliasId: alias.id)
    }
    
    private func deactivateAlias(alias:Aliases) {
        let networkHelper = NetworkHelper()
        networkHelper.deactivateSpecificAlias(completion: { result in
            DispatchQueue.main.async {
                self.isSwitchingAliasActiveState = false
                
                if result == "204" {
                    self.alias?.active = false
                    self.isAliasActive = false
                    shouldReloadDataInParent = true
                } else {
                    self.isAliasActive = true
                    activeAlert = .error
                    showAlert = true
                    errorAlertTitle = String(localized: "error_forgetting_alias")
                    errorAlertMessage = result ?? String(localized: "error_unknown_refer_to_logs")
                }
            }
        },aliasId: alias.id)
    }
    
    private func deleteAlias(alias:Aliases) {
        let networkHelper = NetworkHelper()
        networkHelper.deleteAlias(completion: { result in
            DispatchQueue.main.async {
                self.isDeletingAlias = false
                
                if result == "204" {
                    shouldReloadDataInParent = true
                    self.presentationMode.wrappedValue.dismiss()
                } else {
                    activeAlert = .error
                    showAlert = true
                    errorAlertTitle = String(localized: "error_deleting_alias")
                    errorAlertMessage = result ?? String(localized: "error_unknown_refer_to_logs")
                }
            }
        },aliasId: alias.id)
    }
    
    private func restoreAlias(alias:Aliases) {
        let networkHelper = NetworkHelper()
        networkHelper.restoreAlias(completion: { alias, error in
            DispatchQueue.main.async {
                self.isRestoringAlias = false
                
                if let alias = alias {
                    self.alias = alias
                    self.isAliasActive = alias.active
                    shouldReloadDataInParent = true

                } else {
                    activeAlert = .error
                    showAlert = true
                    errorAlertTitle = String(localized: "error_restoring_alias")
                    errorAlertMessage = error ?? String(localized: "error_unknown_refer_to_logs")
                }
            }
        },aliasId: alias.id)
    }
    
    private func forgetAlias(alias:Aliases) {
        let networkHelper = NetworkHelper()
        networkHelper.forgetAlias(completion: { result in
            DispatchQueue.main.async {
                self.isForgettingAlias = false
                
                if result == "204" {
                    shouldReloadDataInParent = true
                    self.presentationMode.wrappedValue.dismiss()
                } else {
                    activeAlert = .error
                    showAlert = true
                    errorAlertTitle = String(localized: "error_forgetting_alias")
                    errorAlertMessage = result ?? String(localized: "error_unknown_refer_to_logs")
                }
            }
        },aliasId: alias.id)
    }
    
    private func getAlias(aliasId: String) {
        let networkHelper = NetworkHelper()
        networkHelper.getSpecificAlias(completion: { alias, error in
            DispatchQueue.main.async {
                if let alias = alias {
                    withAnimation {
                        self.alias = alias
                        self.aliasEmail = alias.email
                        self.updateUi(alias: alias)
                    }
                    
                } else {
                    withAnimation {
                        self.errorText = error
                    }
                }
            }
        },aliasId: aliasId)
    }
}


//#Preview {
//    AliasDetailView(aliasId: "6a866f49-5a0b-4c7e-bc45-f46bf019c4ed", aliasEmail: "PLACEHOLDER", shouldReloadDataInParent: false)
//}
