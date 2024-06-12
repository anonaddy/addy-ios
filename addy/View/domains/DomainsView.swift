//
//  DomainsView.swift
//  addy
//
//  Created by Stijn van de Water on 03/06/2024.
//

import SwiftUI
import addy_shared

struct DomainsView: View {
    @EnvironmentObject var mainViewState: MainViewState
    @StateObject var domainsViewModel = DomainsViewModel()
    @Binding var isShowingDomainsView: Bool
    
    enum ActiveAlert {
        case error, deleteDomain
    }
    @State private var activeAlert: ActiveAlert = .error
    @State private var showAlert: Bool = false
    
    @State private var domainToDelete: Domains? = nil
    
    
    // Instead of mainStateView we have seperate states. To prevent the entire mainview from refreshing when updating
    @State private var domain_count: Int = 0
    @State private var domain_limit: Int? = 0
    
    @State private var isPresentingAddDomainBottomSheet = false
    
    @State private var shouldReloadDataInParent = false
    
    @State private var errorAlertTitle = ""
    @State private var errorAlertMessage = ""
    
    
    var body: some View {
        NavigationStack(){
            List {
                if let domains = domainsViewModel.domains{
                    if !domains.data.isEmpty {
                    
                        Section {
                            
                            ForEach (domains.data) { domain in
                                NavigationLink(destination: DomainsDetailView(domainId: domain.id, domainDomain: domain.domain ,shouldReloadDataInParent: $shouldReloadDataInParent)
                                    .environmentObject(mainViewState)){
                                        
                                        VStack(alignment: .leading) {
                                            Text(domain.domain)
                                                .font(.headline)
                                                .truncationMode(.tail)
                                                .frame(minWidth: 20)
                                            
                                            
                                            if domain.domain_sending_verified_at == nil {
                                                Text(String(localized: "configuration_error"))
                                                    .font(.caption)
                                                    .opacity(0.625)
                                                    .truncationMode(.middle)
                                                    .foregroundStyle(.red)
                                                
                                            } else {
                                                Text(String(format: String(format: String(localized: "domains_list_description"), String(domain.aliases_count ?? 0))))
                                                    .font(.caption)
                                                    .opacity(0.625)
                                                    .truncationMode(.middle)
                                                
                                            }
  
                                            
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    .onChange(of: shouldReloadDataInParent) {
                                        if shouldReloadDataInParent {
                                            domainsViewModel.getDomains()
                                            getUserResource()
                                            self.shouldReloadDataInParent = false
                                        }
                                    }
                                
                                
                                
                            }.onDelete(perform: deleteDomain)
                        }header: {
                            HStack(spacing: 6){
                                Text(String(localized: "all_domains"))
                                
                                
                                if (domainsViewModel.isLoading){
                                    ProgressView()
                                        .frame(maxHeight: 4)
                                    
                                }
                            }
                            
                        } footer: {
                            Label {
                                Text(String(format: String(localized: "you_ve_used_d_out_of_d_domains"),  String(domain_count), (mainViewState.userResource!.subscription != nil ? String(domain_limit! /* Cannot be nil since subscription is not nil */ ) : String(localized: "unlimited"))))
                            } icon: {
                                Image(systemName: "info.circle")
                            }.padding(.top)
                            
                        }
                }
                }
                
            }.refreshable {
                self.domainsViewModel.getDomains()
                getUserResource()
            }
            .sheet(isPresented: $isPresentingAddDomainBottomSheet) {
                NavigationStack {
                    AddDomainBottomSheet(){
                        domainsViewModel.getDomains()
                        getUserResource()
                        isPresentingAddDomainBottomSheet = false
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                switch activeAlert {
                case .deleteDomain:
                    return Alert(title: Text(String(localized: "delete_domain")), message: Text(String(localized: "delete_domain_confirmation_desc")), primaryButton: .destructive(Text(String(localized: "delete"))){
                        DispatchQueue.global(qos: .background).async {
                            self.deleteDomain(domain: self.domainToDelete!)
                        }
                    }, secondaryButton: .cancel(){
                        domainsViewModel.getDomains()
                    })
                case .error:
                    return Alert(
                        title: Text(errorAlertTitle),
                        message: Text(errorAlertMessage)
                    )
                }
            }
            .overlay(Group {
                
                
                // If there is an domains (aka, if the list is visible)
                if let domains = domainsViewModel.domains{
                    if domains.data.isEmpty {
                        ContentUnavailableView {
                            Label(String(localized: "no_domains"), systemImage: "globe")
                        } description: {
                            Text(String(localized: "no_domains_desc"))
                        }
                    }
                } else {
                    // If there is NO domains (aka, if the list is not visible)
                    
                    
                    // No domains, check if there is an error
                    if (domainsViewModel.networkError != ""){
                        // Error screen
                        ContentUnavailableView {
                            Label(String(localized: "something_went_wrong_retrieving_domains"), systemImage: "wifi.slash")
                        } description: {
                            Text(domainsViewModel.networkError)
                        } actions: {
                            Button(String(localized: "try_again")) {
                                domainsViewModel.getDomains()
                                getUserResource()
                            }
                        }
                    } else {
                        // No domains and no error. It must still be loading...
                        VStack(alignment: .center, spacing: 0) {
                            Spacer()
                            ContentUnavailableView {
                                Label(String(localized: "obtaining_domains"), systemImage: "globe")
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
            .navigationTitle(String(localized: "domains"))
            .navigationBarItems(leading: Button(action: {
                self.isShowingDomainsView = false
            }) {
                if UIDevice.current.userInterfaceIdiom != .pad {
                    Text(String(localized: "close"))
                }
            }, trailing: Button(action: {
                self.isPresentingAddDomainBottomSheet = true
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
                              domain_count >= domain_limit! /* Cannot be nil since subscription is not nil */ )
            })
        }.onAppear(perform: {
            // Set stats, update later
            domain_count = mainViewState.userResource!.active_domain_count
            domain_limit = mainViewState.userResource!.active_domain_limit
            
            if let domains = domainsViewModel.domains{
                if (domains.data.isEmpty) {
                    domainsViewModel.getDomains()
                    
                }
            }
            getUserResource()
        })
        
    }
    
    
    private func deleteDomain(domain:Domains) {
        let networkHelper = NetworkHelper()
        networkHelper.deleteDomain(completion: { result in
            DispatchQueue.main.async {
                if result == "204" {
                    domainsViewModel.getDomains()
                    getUserResource()
                } else {
                    activeAlert = .error
                    showAlert = true
                    errorAlertTitle = String(localized: "error_deleting_domain")
                    errorAlertMessage = result ?? String(localized: "error_unknown_refer_to_logs")
                }
            }
        },domainId: domain.id)
    }
    
    
    func deleteDomain(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            if let domains = domainsViewModel.domains?.data {
                let item = domains[index]
                domainToDelete = item
                activeAlert = .deleteDomain
                showAlert = true
                
                // Remove from the collection for the smooth animation
                domainsViewModel.domains?.data.remove(atOffsets: offsets)
                
            }
        }
    }
    
    private func getUserResource() {
        let networkHelper = NetworkHelper()
        networkHelper.getUserResource { userResource, error in
            DispatchQueue.main.async {
                if let userResource = userResource {
                    // Don't update mainView, this will refresh the entire view hiearchy
                    domain_limit = userResource.active_domain_limit
                    domain_count = userResource.active_domain_count
                } else {
                    activeAlert = .error
                    showAlert = true
                }
            }
        }
    }
    
}
