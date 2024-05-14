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
    
    @Published var aliasSortFilter = AliasSortFilter(
        onlyActiveAliases: false,
        onlyDeletedAliases: false,
        onlyInactiveAliases: false,
        onlyWatchedAliases: false,
        sort: nil,
        sortDesc: false,
        filter: nil
    )

    @Published var searchQuery = ""
        
    var searchCancellable: AnyCancellable? = nil
    var filterCancellable: AnyCancellable? = nil
    
    
    @Published var aliasList: AliasesArray? = nil

    @Published var isLoading = false
    @Published var hasArrivedAtTheLastPage = false
    @Published var networkError:String = ""
    
    init(){
        // since SwiftUI uses @published so its a publisher.
        // so we dont need to explicitly define publisher..
        searchCancellable = $searchQuery
            .removeDuplicates()
            .debounce(for: 0.6, scheduler: RunLoop.main)
            .sink(receiveValue: {str in
                // When something is being searched cancel the loading to make sure that the networkCall will succeed
                self.isLoading = false
                if str == ""{
                    // Reset Data....
                    self.aliasSortFilter.filter = nil
                    self.getAliases(forceReload:true)
                }
                else {
                    // search Data
                    self.aliasSortFilter.filter = str
                    self.getAliases(forceReload:true)
                }
                
            })
    }
    
    public func getAliases(forceReload: Bool){
        if (!self.isLoading){
            self.isLoading = true
            self.networkError = ""
            if (forceReload){
                // This will make sure that the meta resets and jumps back to 0
                // To prevent that the app continues loading from page X when performing a search after scrolling for a while
                self.aliasList?.meta = nil
            }
            
            let networkHelper = NetworkHelper()
            networkHelper.getAliases (completion: { aliasArray, error in
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
                            
                            self.hasArrivedAtTheLastPage = aliasArray.meta?.current_page == aliasArray.meta?.last_page
                            
                        } else {
                            self.networkError = String(format: String(localized: "details_about_error_s"),"\(error)")
                            print("Error: \(error)")
                        }
                    }
            },aliasSortFilter: self.aliasSortFilter, page : (aliasList?.meta?.current_page ?? 0) + 1,size: 25)
        }
        
        }
    
    
    func loadMoreContent(){
        if (!self.hasArrivedAtTheLastPage){
            getAliases(forceReload: false)
        }
    }
    
}
