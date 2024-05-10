//
//  AliasesView.swift
//  addy
//
//  Created by Stijn van de Water on 08/05/2024.
//

import SwiftUI
import addy_shared
import UniformTypeIdentifiers

struct AliasesView: View {
    @EnvironmentObject var mainViewState: MainViewState
    @State private var showError = false
    @EnvironmentObject var aliasesViewModel: AliasesViewModel
    
    private var aliasList: AliasesArray? = nil
    
    
    var body: some View {
        NavigationStack(){
            List {
                if let aliasList = aliasesViewModel.aliasList{
                    
                    
                    Text("PLACEHOLDER")
                    

                        if (aliasesViewModel.searchQuery == ""){
                            Section {
                                VStack{
                                    CardView(){
                                        Text("PLACEHOLDER")
                                    }
                                    CardView(){
                                        Text("PLACEHOLDER")
                                    }
                                }.frame(height: 150)
                            }header: {
                                Text(String(localized: "statistics"))
                            }
                        }
                    
                    
                    Section {
                        
                        ForEach (aliasList.data) { alias in
                            ZStack {
                                AliasRowView(alias: alias,isPreview: false)
                                    .listRowBackground(Color.clear)
                                    .contextMenu {
                                            Button {
                                                UIPasteboard.general.setValue(alias.email,forPasteboardType: UTType.plainText.identifier)
                                            } label: {
                                                Label(String(localized: "copy_to_clipboard"), systemImage: "clipboard")
                                            }
                                            Button {
                                                UIPasteboard.general.setValue(alias.email,forPasteboardType: UTType.plainText.identifier)
                                            } label: {
                                                Label(String(localized: "send_mail"), systemImage: "paperplane")
                                            }
                                        
                                        Section(String(localized: "general")){
                                            if (alias.active){
                                                Button {
                                                    UIPasteboard.general.setValue(alias.email,forPasteboardType: UTType.plainText.identifier)
                                                } label: {
                                                    Label(String(localized: "disable_alias"), systemImage: "hand.raised")
                                                }
                                            } else {
                                                Button {
                                                    UIPasteboard.general.setValue(alias.email,forPasteboardType: UTType.plainText.identifier)
                                                } label: {
                                                    Label(String(localized: "enable_alias"), systemImage: "checkmark.circle")
                                                }
                                            }
                                            
                                            if (alias.deleted_at != nil){
                                                Button() {
                                                    UIPasteboard.general.setValue(alias.email,forPasteboardType: UTType.plainText.identifier)
                                                } label: {
                                                    Label(String(localized: "restore_alias"), systemImage: "arrow.up.trash")
                                                }
                                                Button(role: .destructive) {
                                                    UIPasteboard.general.setValue(alias.email,forPasteboardType: UTType.plainText.identifier)
                                                } label: {
                                                    Label(String(localized: "forget_alias"), systemImage: "eraser")
                                                }
                                            } else {
                                                Button(role: .destructive) {
                                                    UIPasteboard.general.setValue(alias.email,forPasteboardType: UTType.plainText.identifier)
                                                } label: {
                                                    Label(String(localized: "delete_alias"), systemImage: "arrow.up.trash")
                                                }
                                                Button() {
                                                    UIPasteboard.general.setValue(alias.email,forPasteboardType: UTType.plainText.identifier)
                                                } label: {
                                                    Label(String(localized: "forget_alias"), systemImage: "eraser")
                                                }
                                            }
                                        }
                                    } preview:
                                {
                                    AliasRowView(alias: alias, isPreview: true)
                                }
                                NavigationLink(destination: AliasDetailView(aliasId: alias.id)){
                                    EmptyView()
                                }.opacity(0)
                                
                            }
                            
                        }
                    }header: {
                        Text(String(localized: "aliases"))
                    }
                    
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
                
            }
            .overlay(Group {
                

                if let aliasList = aliasesViewModel.aliasList{
                    if aliasList.data.isEmpty, !aliasesViewModel.searchQuery.isEmpty {
                        ContentUnavailableView.search(text: aliasesViewModel.searchQuery)
                    } else if aliasList.data.isEmpty, aliasesViewModel.searchQuery.isEmpty {
                        if (aliasesViewModel.isLoading){
                            VStack(alignment: .center, spacing: 0) {
                                Spacer()
                                ContentUnavailableView {
                                    Label(String(localized: "obtaining_aliases"), systemImage: "globe")
                                } description: {
                                    Text(String(localized: "obtaining_aliases_desc"))
                                }
                                
                                ProgressView()
                                    .foregroundColor(.black)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, maxHeight:50)
                                Spacer()
                            }
                            
                        } else {
                            ContentUnavailableView {
                                Label(String(localized: "no_aliases"), systemImage: "at.badge.plus")
                            } description: {
                                Text(String(localized: "no_aliases_desc"))
                            }
                        }
                        
                    }
                } else {
                    if (aliasesViewModel.networkError != ""){
                        ContentUnavailableView {
                            Label(String(localized: "something_went_wrong_retrieving_aliases"), systemImage: "wifi.slash")
                        } description: {
                            Text(aliasesViewModel.networkError)
                        } actions: {
                            Button(String(localized: "try_again")) {
                                aliasesViewModel.getAliases(forceReload: true)
                            }
                        }
                    } else {
                        ContentUnavailableView {
                            Label(String(localized: "bug_found"), systemImage: "ladybug")
                        } description: {
                            Text(String(localized: "bug_found_desc"))
                        }
                    }
                    
                }
            })
            .navigationTitle(String(localized: "aliases"))
        }.searchable(text: $aliasesViewModel.searchQuery, prompt: String(localized: "aliases_search"))
            .autocorrectionDisabled(true)
            .textInputAutocapitalization(.never)
    }
    
}


#Preview {
    AliasesView()
}
