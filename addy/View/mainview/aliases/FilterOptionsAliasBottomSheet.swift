//
//  EditAliasDescriptionBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 12/05/2024.
//

import SwiftUI

//
//  AddApiBottomSHeet.swift
//  addy
//
//  Created by Stijn van de Water on 07/05/2024.
//

import SwiftUI
import AVFoundation
import CodeScanner
import addy_shared

struct FilterOptionsAliasBottomSheet: View {
    @State private var filter1Selection: Int = 0
    @State private var filter2Selection: Int = 0
    @State private var aliasSortFilterRequest: AliasSortFilterRequest
    private var mainPadding: CGFloat = 20
    
    @State var selectedOrderChip = "created_at"
    @State var orderChips: [AddyChipModel] = [
        AddyChipModel(chipId: "local_part",label: String(localized: "sort_localpart")),
        AddyChipModel(chipId: "domain",label: String(localized: "sort_domain")),
        AddyChipModel(chipId: "email",label: String(localized: "sort_email")),
        AddyChipModel(chipId: "emails_forwarded",label: String(localized: "sort_email_forwarded")),
        AddyChipModel(chipId: "emails_blocked",label: String(localized: "sort_email_blocked")),
        AddyChipModel(chipId: "emails_replied",label: String(localized: "sort_email_replied")),
        AddyChipModel(chipId: "emails_sent",label: String(localized: "sort_email_sent")),
        AddyChipModel(chipId: "last_forwarded",label: String(localized: "sort_last_forwarded")),
        AddyChipModel(chipId: "last_blocked",label: String(localized: "sort_last_blocked")),
        AddyChipModel(chipId: "last_replied",label: String(localized: "sort_last_replied")),
        AddyChipModel(chipId: "last_sent",label: String(localized: "sort_last_sent")),
        AddyChipModel(chipId: "active",label: String(localized: "sort_active")),
        AddyChipModel(chipId: "created_at",label: String(localized: "sort_created_at")),
        AddyChipModel(chipId: "updated_at",label: String(localized: "sort_updated_at")),
        AddyChipModel(chipId: "deleted_at",label: String(localized: "sort_deleted_at"))
    ]
    

    
    
    
    let setFilterAndSortingSettings: (AliasSortFilterRequest) -> Void
    
    init(aliasSortFilterRequest: AliasSortFilterRequest, setFilterAndSortingSettings: @escaping (AliasSortFilterRequest) -> Void) {
        self.aliasSortFilterRequest = aliasSortFilterRequest
        self.setFilterAndSortingSettings = setFilterAndSortingSettings
            }
    
    
    @State private var descriptionError:String?
    
    @State var IsLoadingSaveButton: Bool = false
    
    var body: some View {
        VStack{
            
            Text(String(localized: "filtering_and_sorting"))
                .font(.system(.title2))
                .fontWeight(.medium)
                .padding(.top, 25)
                .padding(.bottom, 15)
            
            Divider()
            
            ScrollView {
                
                VStack{
                    
                    Text(String(localized: "filtering_and_sorting_desc"))
                        .font(.system(.footnote))
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .opacity(0.5)
                    
                    Spacer(minLength: 25)
                    
                    HStack() {
                        Text(String(localized: "filters"))
                            .font(.title2)
                        Spacer()
                        Button(action: {
                            aliasSortFilterRequest.onlyActiveAliases = false
                            aliasSortFilterRequest.onlyInactiveAliases = false
                            aliasSortFilterRequest.onlyWatchedAliases = false
                            aliasSortFilterRequest.onlyDeletedAliases = false
                            aliasSortFilterRequest.sort = nil
                            aliasSortFilterRequest.sortDesc = false
                            
                            LoadFilter(aliasSortFilterRequest: aliasSortFilterRequest)
                        }) {
                            Text(String(localized: "clear_filter"))
                                .foregroundColor(.accentColor)
                                .font(.system(size: 16))
                            
                            
                        }
                        .contentTransition(.symbolEffect(.replace))
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        .background(Color.accentColor.opacity(0.3))
                        .cornerRadius(12)
                    }.padding(.vertical)
                    
                    
                    
                    
//                    AddySegmentedControl(selection: $filter1Selection, size: CGSize(width: UIScreen.main.bounds.width - (mainPadding * 2), height: 48), segmentLabels:
//                                            [String(localized: "filter_all_aliases"),
//                                             String(localized: "filter_active_aliases"),
//                                             String(localized: "filter_inactive_aliases"),
//                                             String(localized: "filter_deleted_aliases")])
//                    
//                    
//                    AddySegmentedControl(selection: $filter2Selection, size: CGSize(width: UIScreen.main.bounds.width - (mainPadding * 2), height: 48), segmentLabels:
//                                            [String(localized: "all_aliases"),
//                                             String(localized: "filter_watched_only")])
                    
                    
                    Picker(selection: $filter1Selection, label: Text(String(localized:"all_aliases"))) {
                                            Text(String(localized: "filter_all_aliases")).tag(0)
                                            Text(String(localized:"filter_active_aliases")).tag(1)
                                            Text(String(localized:"filter_inactive_aliases")).tag(2)
                                            Text(String(localized:"filter_deleted_aliases")).tag(3)
                                        }
                                        .pickerStyle(SegmentedPickerStyle())
                                        .disabled(filter2Selection == 1) // means if alias is set to Watch Only

                    
                    Picker(selection: $filter2Selection, label: Text(String(localized:"filter_watched_only"))) {
                                            Text(String(localized: "all_aliases")).tag(0)
                                            Text(String(localized:"filter_watched_only")).tag(1)
                                        }
                                        .pickerStyle(SegmentedPickerStyle())
                                        .padding(.vertical)
                    
                    Divider()
                    
                    
                    HStack() {
                        Text(String(localized: "sort_by"))
                            .font(.title2)
                        Spacer()
                        Button(action: {
                            aliasSortFilterRequest.sortDesc = !aliasSortFilterRequest.sortDesc
                        }) {
                            Label(aliasSortFilterRequest.sortDesc ? String(localized: "sort_desc") : String(localized: "sort_asc"),
                                  systemImage: aliasSortFilterRequest.sortDesc ? "arrowtriangle.down.fill" : "arrowtriangle.up.fill")
                                .foregroundColor(.accentColor)
                                .font(.system(size: 16))
                            
                            
                        }
                        .disabled(filter2Selection == 1) // means if alias is set to Watch Only
                        .contentTransition(.symbolEffect(.replace))
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        .background(Color.accentColor.opacity(0.3))
                        .cornerRadius(12)
                    }.padding(.vertical)
                    
                    AddyChipView(chips: $orderChips, selectedChip: $selectedOrderChip, singleLine: false) { onTappedChip in
                        withAnimation {
                            selectedOrderChip = onTappedChip.chipId
                        }
                        
                    }.disabled(filter2Selection == 1) // means if alias is set to Watch Only


                    
                }.padding(.vertical)
                
                
                AddyLoadingButton(action: {
                    self.saveFilterAndSortingSettings()
                }, isLoading: $IsLoadingSaveButton) {
                    Text(String(localized: "save")).foregroundColor(Color.white)
                }.frame(minHeight: 56)
                
                
                
            }
            .padding(.horizontal)
            
        }.presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .onAppear(perform: {
                LoadFilter(aliasSortFilterRequest: aliasSortFilterRequest)
            })
        
        
    }
    
    func saveFilterAndSortingSettings(){
                
        switch filter1Selection {
            case 1:
                    aliasSortFilterRequest.onlyActiveAliases = true
                    aliasSortFilterRequest.onlyInactiveAliases = false
                    aliasSortFilterRequest.onlyDeletedAliases = false
            case 2:
                    aliasSortFilterRequest.onlyActiveAliases = false
                    aliasSortFilterRequest.onlyInactiveAliases = true
                    aliasSortFilterRequest.onlyDeletedAliases = false
            case 3:
                    aliasSortFilterRequest.onlyActiveAliases = false
                    aliasSortFilterRequest.onlyInactiveAliases = false
                    aliasSortFilterRequest.onlyDeletedAliases = true
            default:
                    aliasSortFilterRequest.onlyActiveAliases = false
                    aliasSortFilterRequest.onlyInactiveAliases = false
                    aliasSortFilterRequest.onlyDeletedAliases = false
        }
        
        switch filter2Selection {
            case 1:
                    aliasSortFilterRequest.onlyWatchedAliases = true
            default:
                    aliasSortFilterRequest.onlyWatchedAliases = false
        }
        
        aliasSortFilterRequest.sort = selectedOrderChip
        
        self.setFilterAndSortingSettings(self.aliasSortFilterRequest)
    }
    
    func LoadFilter(aliasSortFilterRequest: AliasSortFilterRequest){
        
        // Load the first selectionbar
        if (aliasSortFilterRequest.onlyActiveAliases){
            filter1Selection = 1
        }
        else if (aliasSortFilterRequest.onlyInactiveAliases){
            filter1Selection = 2
        }
        else if (aliasSortFilterRequest.onlyDeletedAliases){
            filter1Selection = 3
        }
        else {
            filter1Selection = 0
        }
        
        // Load the second selectionbar
        if (aliasSortFilterRequest.onlyWatchedAliases){
            filter2Selection = 1
        }
        else {
            filter2Selection = 0
        }
        
        // If sort is set, set the chip
        if let sort = aliasSortFilterRequest.sort {
            selectedOrderChip = sort
        } else {
            selectedOrderChip = "created_at"
        }
    }
}



struct FilterOptionsAliasBottomSheet_Previews: PreviewProvider {
    static var defaultSortFilterRequest = AliasSortFilterRequest(
        onlyActiveAliases: false,
        onlyDeletedAliases: true,
        onlyInactiveAliases: false,
        onlyWatchedAliases: false,
        sort: nil,
        sortDesc: false,
        filter: nil
    )
    
    
    static var previews: some View {
        FilterOptionsAliasBottomSheet(aliasSortFilterRequest: defaultSortFilterRequest, setFilterAndSortingSettings: { alias in
            // Dummy function for preview
        })
    }
}
