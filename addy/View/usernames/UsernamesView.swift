//
//  UsernamesView.swift
//  addy
//
//  Created by Stijn van de Water on 01/06/2024.
//

import SwiftUI
import addy_shared

struct UsernamesView: View {
    @EnvironmentObject var mainViewState: MainViewState
    @StateObject var usernamesViewModel = UsernamesViewModel()
    
    enum ActiveAlert {
        case error, deleteUsername
    }
    @State private var activeAlert: ActiveAlert = .error
    @State private var showAlert: Bool = false
    
    @State private var usernameToDelete: Usernames? = nil
    
    
    // Instead of mainStateView we have seperate states. To prevent the entire mainview from refreshing when updating
    @State private var username_count: Int = 0
    @State private var username_limit: Int = 0
    
    @State private var isPresentingAddUsernameBottomSheet = false
    
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
                    usernamesViewBody
                }
            } else {
                usernamesViewBody
            }
        }.onAppear(perform: {
            // Set stats, update later
            username_count = mainViewState.userResource!.username_count
            username_limit = mainViewState.userResource!.username_limit
            
            if let usernames = usernamesViewModel.usernames{
                if (usernames.data.isEmpty) {
                    Task {
                        await usernamesViewModel.getUsernames()
                    }
                    
                }
            }
        })
        .task {
            await getUserResource()
        }
        
    }
    
    private var usernamesViewBody: some View {
        List {
            if let usernames = usernamesViewModel.usernames{
                Section {
                    
                    ForEach (usernames.data) { username in
                        NavigationLink(destination: UsernamesDetailView(usernameId: username.id, usernameUsername: username.username ,shouldReloadDataInParent: $shouldReloadDataInParent)
                            .environmentObject(mainViewState)){
                                
                                VStack(alignment: .leading) {
                                    Text(username.username)
                                        .font(.headline)
                                        .truncationMode(.tail)
                                        .frame(minWidth: 20)
                                    
                                    
                                    Text(getUsernameDescription(username: username))
                                        .font(.caption)
                                        .opacity(0.625)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    
                                    
                                }
                                .padding(.vertical, 4)
                            }
                            .onChange(of: shouldReloadDataInParent) {
                                if shouldReloadDataInParent {
                                    Task {
                                                            await getUserResource()
                                        await usernamesViewModel.getUsernames()
                                                        }
                                    self.shouldReloadDataInParent = false
                                }
                            }
                        
                        
                        
                    }.onDelete(perform: deleteUsername)
                }header: {
                    HStack(spacing: 6){
                        Text(String(localized: "all_usernames"))
                        
                        
                        if (usernamesViewModel.isLoading){
                            ProgressView()
                                .frame(maxHeight: 4)
                            
                        }
                    }
                    
                } footer: {
                    Label {
                        Text(String(format: String(localized: "you_ve_used_d_out_of_d_usernames"), String(username_count), String(username_limit)))
                    } icon: {
                        Image(systemName: "info.circle")
                    }.padding(.top)
                    
                }
                
            }
            
        }.refreshable {
            if horizontalSize == .regular {
                // When in regular size (tablet) mode, refreshing aliases also ask the mainView to update general data
                self.onRefreshGeneralData?()
            }
            
            await self.usernamesViewModel.getUsernames()
            await getUserResource()
        }
        .sheet(isPresented: $isPresentingAddUsernameBottomSheet) {
            NavigationStack {
                AddUsernameBottomSheet(usernameLimit: mainViewState.userResource!.username_limit){
                    Task {
                                            await getUserResource()
                        await usernamesViewModel.getUsernames()
                                        }
               
                    isPresentingAddUsernameBottomSheet = false
                }
            }
            .presentationDetents([.medium, .large])
        }
        .alert(isPresented: $showAlert) {
            switch activeAlert {
            case .deleteUsername:
                return Alert(title: Text(String(localized: "delete_username")), message: Text(String(localized: "delete_username_confirmation_desc")), primaryButton: .destructive(Text(String(localized: "delete"))){
                    Task {
                        await self.deleteUsername(username: self.usernameToDelete!)
                    }
                }, secondaryButton: .cancel(){
                    Task {
                        await usernamesViewModel.getUsernames()
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
            
            
            // If there is an usernames (aka, if the list is visible)
            if usernamesViewModel.usernames != nil{
                
                // There is always 1 username.
                
                //                    if usernames.isEmpty {
                //                        ContentUnavailableView {
                //                            Label(String(localized: "no_usernames"), systemImage: "person.2")
                //                        } description: {
                //                            Text(String(localized: "no_usernames_desc"))
                //                        }
                //                    }
                
            } else {
                // If there is NO usernames (aka, if the list is not visible)
                
                
                // No usernames, check if there is an error
                if (usernamesViewModel.networkError != ""){
                    // Error screen
                    ContentUnavailableView {
                        Label(String(localized: "something_went_wrong_retrieving_usernames"), systemImage: "wifi.slash")
                    } description: {
                        Text(usernamesViewModel.networkError)
                    } actions: {
                        Button(String(localized: "try_again")) {
                            Task {
                                await getUserResource()
                                await usernamesViewModel.getUsernames()
                            }
                        }
                    }
                } else {
                    // No usernames and no error. It must still be loading...
                    VStack(alignment: .center, spacing: 0) {
                        Spacer()
                        ContentUnavailableView {
                            Label(String(localized: "obtaining_usernames"), systemImage: "globe")
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
        .navigationTitle(String(localized: "usernames"))
        .navigationBarTitleDisplayMode(horizontalSize == .regular ? .automatic : .inline)
        .toolbar {
            if horizontalSize == .regular {
                ProfilePicture().environmentObject(mainViewState)
                FailedDeliveriesIcon(horizontalSize: $horizontalSize).environmentObject(mainViewState)
            }
        }
        .navigationBarItems(trailing: Button(action: {
            self.isPresentingAddUsernameBottomSheet = true
        } ) {
            
            Image(systemName: "plus")
                .frame(width: 24, height: 24)
            
        }
                            // Disable this image/button when the user has a subscription AND the count is ABOVE or ON limit
                                .disabled(mainViewState.userResource!.subscription != nil &&
                                          username_count >= username_limit /* Cannot be nil since subscription is not nil */ ))
    }
    
    private func getUsernameDescription(username: Usernames) -> String{
        if let description = username.description {
            return String(format: String(localized: "s_s_s"),
                          description,
                          String(format: NSLocalizedString("created_at_s", comment: ""),
                                 DateTimeUtils.turnStringIntoLocalString(username.created_at)),
                          String(format: String(localized: "updated_at_s"),
                                 DateTimeUtils.turnStringIntoLocalString(username.updated_at)))
        } else {
            return String(format: String(localized: "s_s"),
                          String(format: NSLocalizedString("created_at_s", comment: ""),
                                 DateTimeUtils.turnStringIntoLocalString(username.created_at)),
                          String(format: String(localized: "created_at_s"),
                                 DateTimeUtils.turnStringIntoLocalString(username.updated_at)))
        }
        
    }
    
    
    private func deleteUsername(username: Usernames) async {
        let networkHelper = NetworkHelper()
        do {
            let result = try await networkHelper.deleteUsername(usernameId: username.id)
            if result == "204" {
                await getUserResource()
                await usernamesViewModel.getUsernames()
            } else {
                activeAlert = .error
                showAlert = true
                errorAlertTitle = String(localized: "error_deleting_username")
                errorAlertMessage = result
            }
        } catch {
            activeAlert = .error
            showAlert = true
            errorAlertTitle = String(localized: "error_deleting_username")
            errorAlertMessage = error.localizedDescription
        }
    }

    
    
    func deleteUsername(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            if let usernames = usernamesViewModel.usernames?.data {
                let item = usernames[index]
                usernameToDelete = item
                activeAlert = .deleteUsername
                showAlert = true
                
                // Remove from the collection for the smooth animation
                usernamesViewModel.usernames?.data.remove(atOffsets: offsets)
                
            }
        }
    }
    
    private func getUserResource() async {
        let networkHelper = NetworkHelper()
        do {
            let userResource = try await networkHelper.getUserResource()
            if let userResource = userResource {
                // Don't update mainView, this will refresh the entire view hierarchy
                username_limit = userResource.username_limit
                username_count = userResource.username_count
            } else {
                activeAlert = .error
                showAlert = true
            }
        } catch {
            print("Failed to get user resource: \(error)")
        }
    }

    
}

//
//#Preview {
//    UsernamesView()
//}
