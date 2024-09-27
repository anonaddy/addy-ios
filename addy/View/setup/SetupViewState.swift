//
//  SetupViewState.swift
//  addy
//
//  Created by Stijn van de Water on 26/09/2024.
//

import Foundation


class SetupViewState: ObservableObject {
    
    
    static let shared = SetupViewState() // Shared instance
    
    @Published var verifyQuery: String? = nil
}
