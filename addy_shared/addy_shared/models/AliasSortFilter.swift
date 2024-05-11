//
//  AliasSortFilter.swift
//  addy_shared
//
//  Created by Stijn van de Water on 09/05/2024.
//

public struct AliasSortFilter {
    var onlyActiveAliases: Bool
    var onlyDeletedAliases: Bool
    var onlyInactiveAliases: Bool
    var onlyWatchedAliases: Bool
    var sort: String?
    var sortDesc: Bool
    public var filter: String?
    
    public init(
            onlyActiveAliases: Bool,
            onlyDeletedAliases: Bool,
            onlyInactiveAliases: Bool,
            onlyWatchedAliases: Bool,
            sort: String?,
            sortDesc: Bool,
            filter: String?
        ) {
            self.onlyActiveAliases = onlyActiveAliases
            self.onlyDeletedAliases = onlyDeletedAliases
            self.onlyInactiveAliases = onlyInactiveAliases
            self.onlyWatchedAliases = onlyWatchedAliases
            self.sort = sort
            self.sortDesc = sortDesc
            self.filter = filter
        }
    
}
