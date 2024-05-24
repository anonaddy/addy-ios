//
//  RecipientView.swift
//  addy
//
//  Created by Stijn van de Water on 08/05/2024.
//

import SwiftUI
import addy_shared

struct RecipientsView: View {
    @EnvironmentObject var mainViewState: MainViewState
    @StateObject var recipientsViewModel = RecipientsViewModel()
    
    enum ActiveAlert {
        case deleteRecipients, error
    }
    @State private var activeAlert: ActiveAlert = .deleteRecipients
    @State private var showAlert: Bool = false
    
    @State private var recipientInContextMenu: Recipients? = nil
    
    @State private var isPresentingAddRecipientBottomSheet = false
    
    @State private var errorAlertTitle = ""
    @State private var errorAlertMessage = ""
    
    @State var selectedFilterChip = "all"
    @State var filterChips: [AddyChipModel] = []

    var body: some View {
        NavigationStack(){
            List {
                if let recipients = recipientsViewModel.recipients{
                    
                    
                    Section {
                        AddyChipView(chips: $filterChips, selectedChip: $selectedFilterChip, singleLine: true) { onTappedChip in
                            withAnimation {
                                selectedFilterChip = onTappedChip.chipId
                            }
                            
                            ApplyFilter(chipId: onTappedChip.chipId)
                        }
                    }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())
                    

                    
                    Section {
                        
                        ForEach (recipients) { recipient in
                            ZStack {
                                RecipientRowView(recipient: recipient,isPreview: false)
                                    .listRowBackground(Color.clear)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            self.activeAlert = .deleteRecipients
                                            self.showAlert = true
                                        } label: {
                                            Label(String(localized: "delete_recipient"), systemImage: "trash")
                                        }
                                    } preview:
                                {
                                    RecipientRowView(recipient: recipient, isPreview: true).onAppear {
                                        self.recipientInContextMenu = recipient

                                    }
                                }
                                NavigationLink(destination: RecipientsDetailView(recipientId: recipient.id, recipientEmail: recipient.email).environmentObject(mainViewState)){
                                    EmptyView()
                                }.opacity(0)
                                
                            }
                            
                        }
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
                        
                    }
                    
                }

            }.refreshable {
                self.recipientsViewModel.getRecipients()
            }.alert(isPresented: $showAlert) {
                switch activeAlert {
                case .deleteRecipients:
                    return Alert(title: Text(String(localized: "delete_recipient")), message: Text(String(localized: "delete_recipient_desc")), primaryButton: .destructive(Text(String(localized: "delete"))){
                        
                        DispatchQueue.global(qos: .background).async {
                            self.deleteRecipient(recipient: recipientInContextMenu!)
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
            .navigationBarItems(trailing: Button(action: {
                self.isPresentingAddRecipientBottomSheet = true
            } ) {
                Image(systemName: "plus")
                    .resizable()
                    .padding(6)
                    .frame(width: 24, height: 24)
                    .background(Color.accentColor)
                    .clipShape(Circle())
                    .foregroundColor(.white)
            } )
        }.onAppear(perform: {
            LoadFilter()
            
            if let recipients = recipientsViewModel.recipients{
                if (recipients.isEmpty) {
                    recipientsViewModel.getRecipients()
                    
                }
            }
        })
        
    }
    func deleteRecipient(recipient: Recipients){
        //TODO
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

    
    func GetFilterChips() -> [AddyChipModel]{
        return [
            AddyChipModel(chipId: "all",label: String(localized: "filter_all_recipients")),
            AddyChipModel(chipId: "verified_only",label: String(localized: "filter_verified_recipients"))
        ]
    }

}


#Preview {
    RecipientsView()
}
