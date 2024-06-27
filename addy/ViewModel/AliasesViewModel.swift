//
//  AliasesViewModel.swift
//  addy
//
//  Created by Stijn van de Water on 09/05/2024.
//

import SwiftUI
import Combine
import addy_shared

class AliasesViewModel: ObservableObject{
    
    @Published var aliasSortFilterRequest = AliasSortFilterRequest(
        onlyActiveAliases: false,
        onlyDeletedAliases: false,
        onlyInactiveAliases: false,
        onlyWatchedAliases: false,
        sort: "created_at",
        sortDesc: false,
        filter: ""
    )
    
    var defaultSortFilterRequest = AliasSortFilterRequest(
        onlyActiveAliases: false,
        onlyDeletedAliases: false,
        onlyInactiveAliases: false,
        onlyWatchedAliases: false,
        sort: "created_at",
        sortDesc: false,
        filter: ""
    )

    @Published var searchQuery = ""
        
    var searchCancellable: AnyCancellable? = nil
    
    
    @Published var aliasList: AliasesArray? = nil

    @Published var isLoading = false
    @Published var hasArrivedAtTheLastPage = true
    @Published var networkError:String = ""
    
    init(){
        // since SwiftUI uses @published so its a publisher.
        // so we dont need to explicitly define publisher..
        searchCancellable = $searchQuery
            .dropFirst()
            .removeDuplicates()
            .debounce(for: 1.0, scheduler: RunLoop.main)
            .sink(receiveValue: {str in
                self.searchAliases(searchQuery: str)
            })
    }
    
    func searchAliases(searchQuery: String){
        // When something is being searched cancel the loading to make sure that the networkCall will succeed
        self.isLoading = false
    
        
        if searchQuery == ""{
            // Reset Data....
            self.aliasSortFilterRequest.filter = ""
            
            // When changing the search query, always reset the self.aliasList object to prevent pagenumbers from staying
            self.aliasList = nil
            
            Task {
                await self.getAliases(forceReload:true)
            }
        }
        else {
            if (searchQuery.count >= 3){
                // search Data
                self.aliasSortFilterRequest.filter = searchQuery
                
                // When changing the search query, always reset the self.aliasList object to prevent pagenumbers from staying
                self.aliasList = nil
                
                Task {
                    await self.getAliases(forceReload:true)
                }
            }
            // Don't search for searchTerms for < 3 chars
        }
    }
    
    func getAliases(forceReload: Bool) async {
        if (!self.isLoading){
            DispatchQueue.main.async {
                self.isLoading = true
                self.networkError = ""
            }
            if (forceReload){
                // This will make sure that the meta resets and jumps back to 0
                // To prevent that the app continues loading from page X when performing a search after scrolling for a while
                DispatchQueue.main.async {
                    self.aliasList?.meta = nil
                }
            }
            
            let networkHelper = NetworkHelper()
            
            /**
             * CHECK IF WATCHED ONLY IS TRUE
             * If true simply bulk-obtain all the watched aliases
             */
            if aliasSortFilterRequest.onlyWatchedAliases {
                
                let aliasWatcher = AliasWatcher()
                let aliasesToWatch: [String] = Array(aliasWatcher.getAliasesToWatch())
                
                if !aliasesToWatch.isEmpty {
                    do {
                        let BulkAliasesArray = try await networkHelper.bulkGetAlias(aliases: aliasesToWatch)
                        
                        DispatchQueue.main.async {
                            self.isLoading = false
                            
                            if let BulkAliasesArray = BulkAliasesArray {
                                let aliasArray = AliasesArray(data: BulkAliasesArray.data)
                                self.aliasList = aliasArray
                                
                                // Since the bulkGetAlias func always returns everything we are always at the last page
                                self.hasArrivedAtTheLastPage = true
                            } else {
                                self.networkError = String(format: String(localized: "details_about_error_s"),"\(String(localized: "error_unknown_refer_to_logs"))")
                            }
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self.isLoading = false
                            self.networkError = error.localizedDescription
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.hasArrivedAtTheLastPage = true
                        self.isLoading = false
                        // This could be triggered if you remove the last watched alias and then refresh
                        let aliasArray = AliasesArray(data: [])
                        self.aliasList = aliasArray
                    }
                    
                }

            } else {
                do {
                    let aliasArray = try await networkHelper.getAliases(aliasSortFilterRequest: self.aliasSortFilterRequest, page : (aliasList?.meta?.current_page ?? 0) + 1,size: 25)
                    DispatchQueue.main.async {
                        self.isLoading = false
                    
                    
                    if let aliasArray = aliasArray {
                        
                        if (self.aliasList == nil || forceReload){
                            // If aliasList is empty, assign it
                            self.aliasList = aliasArray
                            
                        } else {
                            // If aliasList is not empty, set the meta and links and append the retrieved aliases to the list (as pagination is being used)
                            self.aliasList?.meta = aliasArray.meta
                            self.aliasList?.links = aliasArray.links
                            self.aliasList?.data.append(contentsOf: aliasArray.data)
                        }
                        
                        self.hasArrivedAtTheLastPage = aliasArray.meta?.current_page == aliasArray.meta?.last_page || self.aliasList?.data.isEmpty == true
                        
                    } else {
                        self.hasArrivedAtTheLastPage = true
                        self.networkError = String(format: String(localized: "details_about_error_s"),"\(String(localized: "error_unknown_refer_to_logs"))")
                    }
                }
                } catch {
                    self.isLoading = false
                    self.networkError = error.localizedDescription
                }
            }
        }
    }


    
    
    func loadMoreContent(){
        if (!self.hasArrivedAtTheLastPage){
            Task {
                await getAliases(forceReload: false)
            }
        }
    }
    
}
