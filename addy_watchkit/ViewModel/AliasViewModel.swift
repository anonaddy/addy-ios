//
//  AliasViewModel.swift
//  addy
//
//  Created by Stijn van de Water on 03/02/2026.
//

import Foundation
import Combine
import addy_shared


class AliasViewModel: ObservableObject {
    @Published var aliases: [Aliases] = []
    @Published var favoriteAliases: Set<String> = [] // Using Set for fast lookup
    @Published var isLoading = false
    
    func fetchAliases() {
        isLoading = true
        // Simulate Network Call
//            self.aliases = [
//                Aliases(from: Aliases.self as! Decoder, id: "1", email: "test@anonaddy.com", description: nil, createdAt: Date()),
//                Aliases(id: "2", email: "shop@anonaddy.com", description: "Shopping", createdAt: Date().addingTimeInterval(-86400))
//            ]
            self.favoriteAliases = ["1"]
            self.isLoading = false
        
    }
    
    func toggleFavorite(id: String) {
        if favoriteAliases.contains(id) {
            favoriteAliases.remove(id)
        } else {
            favoriteAliases.insert(id)
        }
        // Sync with cache/backend here
    }
}
