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
                    domainsViewBody
                }
            } else {
                domainsViewBody
            }
        }.onAppear(perform: {
            // Set stats, update later
            domain_count = mainViewState.userResource!.active_domain_count
            domain_limit = mainViewState.userResource!.active_domain_limit
            
            if let domains = domainsViewModel.domains{
                if (domains.data.isEmpty) {
                    Task {
                        await domainsViewModel.getDomains()
                    }
                    
                }
            }
        })
        .task {
            await getUserResource()
        }
    }
    
    private var domainsViewBody: some View {
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
                                    Task {
                                        await getUserResource()
                                        await domainsViewModel.getDomains()
                                    }
                                    
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
                    Text(String(format: String(localized: "you_ve_used_d_out_of_d_domains"),  String(domain_count), (mainViewState.userResource!.subscription != nil ? String(domain_limit! /* Cannot be nil since subscription is not nil */ ) : String(localized: "unlimited")))).padding(.top)
                    
                }
            }
                
            }
            
        }.refreshable {
            if horizontalSize == .regular {
                // When in regular size (tablet) mode, refreshing aliases also ask the mainView to update general data
                self.onRefreshGeneralData?()
            }
            
            await self.domainsViewModel.getDomains()
            await getUserResource()
        }
        .sheet(isPresented: $isPresentingAddDomainBottomSheet) {
            NavigationStack {
                AddDomainBottomSheet(){
                    Task {
                        await getUserResource()
                        await domainsViewModel.getDomains()
                    }
                    
                    isPresentingAddDomainBottomSheet = false
                }
            }.presentationDetents([.medium, .large])
        }
        .alert(isPresented: $showAlert) {
            switch activeAlert {
            case .deleteDomain:
                return Alert(title: Text(String(localized: "delete_domain")), message: Text(String(localized: "delete_domain_confirmation_desc")), primaryButton: .destructive(Text(String(localized: "delete"))){
                    Task {
                        await self.deleteDomain(domain: self.domainToDelete!)
                    }
                }, secondaryButton: .cancel(){
                    Task {
                        await domainsViewModel.getDomains()
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
                            Task {
                                await getUserResource()
                                await domainsViewModel.getDomains()
                            }
                            
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
        .navigationBarTitleDisplayMode(horizontalSize == .regular ? .automatic : .inline)
        .toolbar {
            if horizontalSize == .regular {
                FailedDeliveriesIcon(horizontalSize: $horizontalSize).environmentObject(mainViewState)
                AccountNotificationsIcon().environmentObject(mainViewState)
                ProfilePicture().environmentObject(mainViewState)
            }
        }
        .navigationBarItems(trailing: Button(action: {
            self.isPresentingAddDomainBottomSheet = true
        } ) {
            
            Image(systemName: "plus")
                .frame(width: 24, height: 24)
          
        }
                            // Disable this image/button when the user has a subscription AND the count is ABOVE or ON limit
                                .disabled(mainViewState.userResource!.subscription != nil &&
                                          domain_count >= domain_limit! /* Cannot be nil since subscription is not nil */ ))
    }
    
    private func deleteDomain(domain: Domains) async {
        let networkHelper = NetworkHelper()
        do {
            let result = try await networkHelper.deleteDomain(domainId: domain.id)
            if result == "204" {
                await getUserResource()
                await domainsViewModel.getDomains()
            } else {
                activeAlert = .error
                showAlert = true
                errorAlertTitle = String(localized: "error_deleting_domain")
                errorAlertMessage = result
            }
        } catch {
            activeAlert = .error
            showAlert = true
            errorAlertTitle = String(localized: "error_deleting_domain")
            errorAlertMessage = error.localizedDescription
        }
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
    
    private func getUserResource() async {
        let networkHelper = NetworkHelper()
        do {
            let userResource = try await networkHelper.getUserResource()
            if let userResource = userResource {
                // Don't update mainView, this will refresh the entire view hierarchy
                domain_limit = userResource.active_domain_limit
                domain_count = userResource.active_domain_count
            } else {
                activeAlert = .error
                showAlert = true
                errorAlertTitle = ""
                errorAlertMessage = String(localized: "something_went_wrong_retrieving_domains")
            }
        } catch {
            activeAlert = .error
            showAlert = true
            errorAlertTitle = String(localized: "something_went_wrong_retrieving_domains")
            errorAlertMessage = error.localizedDescription
        }
    }
    
    
}
