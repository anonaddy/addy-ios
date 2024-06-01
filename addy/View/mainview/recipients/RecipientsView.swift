//
//  RecipientView.swift
//  addy
//
//  Created by Stijn van de Water on 08/05/2024.
//

import SwiftUI
import addy_shared

struct RecipientsView: View {
    @Binding var isPresentingProfileBottomSheet: Bool

    @EnvironmentObject var mainViewState: MainViewState
    @StateObject var recipientsViewModel = RecipientsViewModel()
    
    enum ActiveAlert {
        case resendConfirmationMailRecipientConfirmation, resendConfirmationMailRecipientSuccess, error, deleteRecipient
    }
    @State private var activeAlert: ActiveAlert = .resendConfirmationMailRecipientConfirmation
    @State private var showAlert: Bool = false
    
    @State private var recipientToDelete: Recipients? = nil
    
    // Instead of mainStateView we have seperate states. To prevent the entire mainview from refreshing when updating
    @State private var recipient_count: Int = 0
    @State private var recipient_limit: Int? = 0
    
    @State private var isPresentingAddRecipientBottomSheet = false
    @State private var recipientsToResendConfirmationEmailTo: Recipients? = nil
    
    @State private var shouldReloadDataInParent = false
    
    
    @State private var errorAlertTitle = ""
    @State private var errorAlertMessage = ""
    
    @State var selectedFilterChip:String? = "all"
    @State var filterChips: [AddyChipModel] = []
    
    
    var body: some View {
        NavigationStack(){
            List {
                if let recipients = recipientsViewModel.recipients{
                    
                    
                    Section {
                        AddyRoundedChipView(chips: $filterChips, selectedChip: $selectedFilterChip, singleLine: true) { onTappedChip in
                            withAnimation {
                                selectedFilterChip = onTappedChip.chipId
                            }
                            
                            ApplyFilter(chipId: onTappedChip.chipId)
                        }
                    }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())
                    
                    
                    
                    Section {
                        
                        ForEach (recipients) { recipient in
                            NavigationLink(destination: RecipientsDetailView(recipientId: recipient.id, recipientEmail: recipient.email, shouldReloadDataInParent: $shouldReloadDataInParent)
                                .environmentObject(mainViewState)){
                                    
                                    VStack(alignment: .leading) {
                                        Text(recipient.email)
                                            .font(.headline)
                                            .truncationMode(.tail)
                                            .frame(minWidth: 20)
                                        
                                        if (recipient.email_verified_at == nil){
                                            Text(String(localized: "not_verified"))
                                                .font(.caption)
                                                .opacity(0.625)
                                                .truncationMode(.middle)
                                                .foregroundStyle(.red)
                                        } else {
                                            Text(String(format: String(format: String(localized: "recipients_list_description"), String(recipient.aliases_count ?? 0))))
                                                .font(.caption)
                                                .opacity(0.625)
                                                .truncationMode(.middle)
                                        }
                                        
                                    }
                                    .padding(.vertical, 4)
                                }
                                .disabled(recipient.email_verified_at == nil).overlay(
                                    Group {
                                        if recipient.email_verified_at == nil {
                                            Color.clear
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    recipientsToResendConfirmationEmailTo = recipient
                                                    activeAlert = .resendConfirmationMailRecipientConfirmation
                                                    showAlert = true
                                                    
                                                }
                                        }
                                    }
                                )
                                .onChange(of: shouldReloadDataInParent) {
                                    if shouldReloadDataInParent {
                                        recipientsViewModel.getRecipients()
                                        getUserResource()
                                        self.shouldReloadDataInParent = false
                                    }
                                }
                            
                            
                            
                        }.onDelete(perform: deleteRecipient)
                    }header: {
                        HStack(spacing: 6){
                            if (recipientsViewModel.verifiedOnly){
                                Text(String(localized: "recipients_filtered"))
                            } else {
                                Text(String(localized: "recipients"))
                            }
                            
                            if (recipientsViewModel.isLoading){
                                ProgressView()
                                    .frame(maxHeight: 4)
                                
                            }
                        }
                        
                    } footer: {
                        Label {
                            Text(String(format: String(localized: "you_ve_used_d_out_of_d_recipients"), String(recipient_count), (mainViewState.userResource!.subscription != nil ? String(recipient_limit! /* Cannot be nil since subscription is not nil */ ) : String(localized: "unlimited"))))
                        } icon: {
                            Image(systemName: "info.circle")
                        }
                        
                    }
                    
                }
                
            }.refreshable {
                self.recipientsViewModel.getRecipients()
                getUserResource()
            }
            .sheet(isPresented: $isPresentingAddRecipientBottomSheet) {
                NavigationStack {
                    AddRecipientBottomSheet(){
                        recipientsViewModel.getRecipients()
                        getUserResource()
                        isPresentingAddRecipientBottomSheet = false
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                switch activeAlert {
                case .deleteRecipient:
                    return Alert(title: Text(String(localized: "delete_recipient")), message: Text(String(localized: "delete_recipient_desc")), primaryButton: .destructive(Text(String(localized: "delete"))){
                        DispatchQueue.global(qos: .background).async {
                            self.deleteRecipient(recipient: self.recipientToDelete!)
                        }
                    }, secondaryButton: .cancel(){
                        recipientsViewModel.getRecipients()
                    })
                case .resendConfirmationMailRecipientSuccess:
                    return Alert(title: Text(String(localized: "verification_email_has_been_sent")), dismissButton: .default(Text(String(localized: "close"))))
                case .resendConfirmationMailRecipientConfirmation:
                    return Alert(title: Text(String(localized: "verification_email_confirmation")), message: Text(String(localized: "verification_email_confirmation_desc")), primaryButton: .default(Text(String(localized: "resend_email"))){
                        
                        DispatchQueue.global(qos: .background).async {
                            self.resendConfirmationMailRecipient(recipient: recipientsToResendConfirmationEmailTo!)
                        }
                    }, secondaryButton: .cancel())
                case .error:
                    return Alert(
                        title: Text(errorAlertTitle),
                        message: Text(errorAlertMessage)
                    )
                }
            }
            .overlay(Group {
                
                
                // If there is an recipients (aka, if the list is visible)
                if let recipients = recipientsViewModel.recipients{
                    
                    // There is always 1 recipient.
                    
                    //                    if recipients.isEmpty {
                    //                        ContentUnavailableView {
                    //                            Label(String(localized: "no_recipients"), systemImage: "person.2")
                    //                        } description: {
                    //                            Text(String(localized: "no_recipients_desc"))
                    //                        }
                    //                    }
                    
                } else {
                    // If there is NO recipients (aka, if the list is not visible)
                    
                    
                    // No recipients, check if there is an error
                    if (recipientsViewModel.networkError != ""){
                        // Error screen
                        ContentUnavailableView {
                            Label(String(localized: "something_went_wrong_retrieving_recipients"), systemImage: "wifi.slash")
                        } description: {
                            Text(recipientsViewModel.networkError)
                        } actions: {
                            Button(String(localized: "try_again")) {
                                recipientsViewModel.getRecipients()
                                getUserResource()
                            }
                        }
                    } else {
                        // No recipients and no error. It must still be loading...
                        VStack(alignment: .center, spacing: 0) {
                            Spacer()
                            ContentUnavailableView {
                                Label(String(localized: "obtaining_recipients"), systemImage: "globe")
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
            .navigationTitle(String(localized: "recipients"))
            .navigationBarItems(trailing: HStack {
                
                Button(action: {
                    self.isPresentingProfileBottomSheet = true
                }) {
                    Image(systemName: "person.crop.circle.fill")
                        .foregroundStyle(.primary)
                }
                
                Button(action: {
                    self.isPresentingAddRecipientBottomSheet = true
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
                                  recipient_count >= recipient_limit! /* Cannot be nil since subscription is not nil */ )
                }
            } )
        }.onAppear(perform: {
            // Set stats, update later
            recipient_count = mainViewState.userResource!.recipient_count
            recipient_limit = mainViewState.userResource!.recipient_limit
            
            LoadFilter()
            
            if let recipients = recipientsViewModel.recipients{
                if (recipients.isEmpty) {
                    recipientsViewModel.getRecipients()
                    
                }
            }
            getUserResource()
        })
        
    }
    
    
    
    func ApplyFilter(chipId: String){
        
        switch (chipId){
        case "verified_only":
            recipientsViewModel.verifiedOnly = true
        case "all":
            recipientsViewModel.verifiedOnly = false
        default:
            recipientsViewModel.verifiedOnly = false
        }
        
        recipientsViewModel.getRecipients()
    }
    
    func LoadFilter(){
        self.filterChips = GetFilterChips()
    }
    
    func resendConfirmationMailRecipient(recipient:Recipients){
        let networkHelper = NetworkHelper()
        networkHelper.resendVerificationEmail(completion: { result in
            DispatchQueue.main.async {
                
                if result == "200" {
                    activeAlert = .resendConfirmationMailRecipientSuccess
                    showAlert = true
                } else {
                    activeAlert = .error
                    showAlert = true
                    errorAlertTitle = String(localized: "error_resend_verification")
                    errorAlertMessage = result ?? String(localized: "error_unknown_refer_to_logs")
                }
            }
        },recipientId: recipient.id)
    }
    
    private func deleteRecipient(recipient:Recipients) {
        let networkHelper = NetworkHelper()
        networkHelper.deleteRecipient(completion: { result in
            DispatchQueue.main.async {
                if result == "204" {
                    recipientsViewModel.getRecipients()
                    getUserResource()
                } else {
                    activeAlert = .error
                    showAlert = true
                    errorAlertTitle = String(localized: "error_deleting_recipient")
                    errorAlertMessage = result ?? String(localized: "error_unknown_refer_to_logs")
                }
            }
        },recipientId: recipient.id)
    }
    
    
    func deleteRecipient(at offsets: IndexSet) {
        
        for index in offsets.sorted(by: >) {
            if let recipients = recipientsViewModel.recipients {
                let item = recipients[index]
                recipientToDelete = item
                activeAlert = .deleteRecipient
                showAlert = true
                
                // Remove from the collection for the smooth animation
                recipientsViewModel.recipients?.remove(atOffsets: offsets)
                
            }
        }
        
        
    }
    
    
    func GetFilterChips() -> [AddyChipModel]{
        return [
            AddyChipModel(chipId: "all",label: String(localized: "filter_all_recipients")),
            AddyChipModel(chipId: "verified_only",label: String(localized: "filter_verified_recipients"))
        ]
    }
    
    private func getUserResource() {
        let networkHelper = NetworkHelper()
        networkHelper.getUserResource { userResource, error in
                DispatchQueue.main.async {
                    if let userResource = userResource {
                        // Don't update mainView, this will refresh the entire view hiearchy
                        recipient_limit = userResource.recipient_limit
                        recipient_count = userResource.recipient_count
                    } else {
                        print("Error: \(String(describing: error))")
                        activeAlert = .error
                        showAlert = true
                    }
                }
            }
        }
}


//#Preview {
//    RecipientsView()
//}
