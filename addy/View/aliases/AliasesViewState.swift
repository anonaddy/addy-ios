//
//  SetupViewState.swift
//  addy
//
//  Created by Stijn van de Water on 28/10/2024.
//

import Foundation


class AliasesViewState: ObservableObject {
    static let shared = AliasesViewState() // Shared instance
    
    @Published var applyFilterChip:String? = nil // When not nil, switching to aliasesView will apply this filterId and set it back to nil
}
