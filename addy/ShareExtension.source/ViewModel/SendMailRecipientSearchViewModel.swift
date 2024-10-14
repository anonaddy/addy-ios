//
//  SendMailRecipientSearchViewModel.swift
//  addy
//
//  Created by Stijn van de Water on 06/07/2024.
//

import Foundation
import Combine
import addy_shared

class SendMailRecipientSearchViewModel: ObservableObject{
    
    
    var sortFilterRequest = AliasSortFilterRequest(
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
    
    
    @Published var suggestionChips: [AddyChipModel] = []
    @Published var aliases: [Aliases]? = []

    @Published var domainOptions: [String] = []
    @Published var isLoading = false
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
        
        if (searchQuery.count >= 3){
            // search Data
            self.sortFilterRequest.filter = searchQuery
            
            Task {
                await self.getAliases()
            }
        } else {
            self.suggestionChips = []
        }
        // Don't search for searchTerms for < 3 chars
    }
    
    func setDomainOptions(domainOptions: [String]){
        self.domainOptions = domainOptions
    }
    
    func getAliases() async {
        if (!self.isLoading){
            DispatchQueue.main.async {
                self.isLoading = true
                // Always reset on searching for new queries
                self.suggestionChips = []
                
                self.networkError = ""
            }
            
            let networkHelper = NetworkHelper()
            
            do {
                let aliasArray = try await networkHelper.getAliases(aliasSortFilterRequest: self.sortFilterRequest, page: nil, size: 100)
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let aliasArray = aliasArray {
                        self.aliases = aliasArray.data
                        self.suggestionChips = self.createChipModel(aliasList: aliasArray) 
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.networkError = String(localized: "something_went_wrong_retrieving_aliases")
                }
                LoggingHelper().addLog(
                    importance: LogImportance.critical,
                    error: error.localizedDescription,
                    method: "getAliases", extra: nil)
            }
        }
    }
    
    private func createChipModel(aliasList: AliasesArray) -> [AddyChipModel] {
        
        var chipModel: [AddyChipModel] = []
        
        for alias in aliasList.data {
            chipModel.append(AddyChipModel(chipId: alias.id, label: alias.email))
        }
        
        
        if SettingsManager(encrypted: false).getSettingsBool(key: .mailtoActivityShowSuggestions) {
            for domainOption in domainOptions {
                let suggestion = "\(searchQuery.components(separatedBy: "@")[0])@\(domainOption)"
                if !chipModel.contains(where: { $0.label == suggestion }) {
                    chipModel.append(AddyChipModel(chipId: suggestion, label: suggestion))
                }
            }
        }
        
        
        return chipModel
    }
}
