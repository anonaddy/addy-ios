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
    @Binding var isShowingUsernamesView: Bool
    
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
    
    
    var body: some View {
        NavigationStack(){
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
                                        usernamesViewModel.getUsernames()
                                        getUserResource()
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
                self.usernamesViewModel.getUsernames()
                getUserResource()
            }
            .sheet(isPresented: $isPresentingAddUsernameBottomSheet) {
                NavigationStack {
                    AddUsernameBottomSheet(usernameLimit: mainViewState.userResource!.username_limit){
                        usernamesViewModel.getUsernames()
                        getUserResource()
                        isPresentingAddUsernameBottomSheet = false
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                switch activeAlert {
                case .deleteUsername:
                    return Alert(title: Text(String(localized: "delete_username")), message: Text(String(localized: "delete_username_confirmation_desc")), primaryButton: .destructive(Text(String(localized: "delete"))){
                        DispatchQueue.global(qos: .background).async {
                            self.deleteUsername(username: self.usernameToDelete!)
                        }
                    }, secondaryButton: .cancel(){
                        usernamesViewModel.getUsernames()
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
                                usernamesViewModel.getUsernames()
                                getUserResource()
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
            .navigationBarItems(leading: Button(action: {
                    self.isShowingUsernamesView = false
            }) {
                if UIDevice.current.userInterfaceIdiom != .pad {
                    Text(String(localized: "close"))
                }
            }, trailing: Button(action: {
                self.isPresentingAddUsernameBottomSheet = true
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
                              username_count >= username_limit /* Cannot be nil since subscription is not nil */ )
            })
        }.onAppear(perform: {   
            // Set stats, update later
            username_count = mainViewState.userResource!.username_count
            username_limit = mainViewState.userResource!.username_limit
            
            if let usernames = usernamesViewModel.usernames{
                if (usernames.data.isEmpty) {
                    usernamesViewModel.getUsernames()
                    
                }
            }
            getUserResource()
        })
        
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
    
    
    private func deleteUsername(username:Usernames) {
        let networkHelper = NetworkHelper()
        networkHelper.deleteUsername(completion: { result in
            DispatchQueue.main.async {
                if result == "204" {
                    usernamesViewModel.getUsernames()
                    getUserResource()
                } else {
                    activeAlert = .error
                    showAlert = true
                    errorAlertTitle = String(localized: "error_deleting_username")
                    errorAlertMessage = result ?? String(localized: "error_unknown_refer_to_logs")
                }
            }
        },usernameId: username.id)
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
    
    private func getUserResource() {
        let networkHelper = NetworkHelper()
        networkHelper.getUserResource { userResource, error in
                DispatchQueue.main.async {
                    if let userResource = userResource {
                        // Don't update mainView, this will refresh the entire view hiearchy
                        username_limit = userResource.username_limit
                        username_count = userResource.username_count
                    } else {
                        activeAlert = .error
                        showAlert = true
                    }
                }
            }
        }
    
}

//
//#Preview {
//    UsernamesView()
//}
