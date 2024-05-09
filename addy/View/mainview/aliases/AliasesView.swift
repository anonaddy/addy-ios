//
//  AliasesView.swift
//  addy
//
//  Created by Stijn van de Water on 08/05/2024.
//

import SwiftUI
import addy_shared

struct AliasesView: View {
    @EnvironmentObject var mainViewState: MainViewState
    @State private var showError = false
    @EnvironmentObject var aliasesViewModel: AliasesViewModel
    
    

    
    private var aliasList: AliasesArray? = nil

    
    var body: some View {
        NavigationStack(){
            List {
                // Displaying results
                if let aliasList = aliasesViewModel.aliasList{
                    ForEach (aliasList.data) { alias in
                        ZStack {
                            AliasRowCardView(alias: alias)
                            NavigationLink(destination: AliasDetailView(aliasId: alias.id)){
                                EmptyView()
                            }.opacity(0)
                        }
                    }
                    .listRowSeparator(.hidden)
                    
                    if !aliasesViewModel.hasArrivedAtTheLastPage {
                             ProgressView()
                               .frame(maxWidth: .infinity, maxHeight: .infinity)
                               .foregroundColor(.black)
                               .foregroundColor(.red)
                               .onAppear {
                                   aliasesViewModel.loadMoreContent()
                               }
                           }
                    
                }
                    
            }.overlay(Group {
                
                if aliasesViewModel.isLoading{
                    ProgressView()
                      .frame(maxWidth: .infinity, maxHeight: .infinity)
                      .foregroundColor(.black)
                      .foregroundColor(.red)
                }
                
                if let aliasList = aliasesViewModel.aliasList{
                    if aliasList.data.isEmpty, !aliasesViewModel.searchQuery.isEmpty {
                        ContentUnavailableView.search(text: aliasesViewModel.searchQuery)
                    } else if aliasList.data.isEmpty, aliasesViewModel.searchQuery.isEmpty {
                        ContentUnavailableView {
                            Label(String(localized: "no_aliases"), systemImage: "at.badge.plus")
                        } description: {
                            Text(String(localized: "no_aliases_desc"))
                        }
                    }
                } else {
                    ContentUnavailableView {
                        Label(String(localized: "no_aliases"), systemImage: "at.badge.plus")
                    } description: {
                        Text(String(localized: "no_aliases_desc"))
                    }

                }
            })
            .navigationTitle(String(localized: "aliases"))
        }.searchable(text: $aliasesViewModel.searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: String(localized: "aliases_search")).autocorrectionDisabled(true).textInputAutocapitalization(.never)
    }
    
}


#Preview {
    AliasesView()
}
