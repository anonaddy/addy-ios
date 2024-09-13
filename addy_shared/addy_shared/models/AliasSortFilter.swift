//
//  AliasSortFilter.swift
//  addy_shared
//
//  Created by Stijn van de Water on 09/05/2024.
//

public struct AliasSortFilter:Codable, Equatable {
    public var aliasSortFilterRequest: AliasSortFilterRequest
    public var filterId: String? //MARK: iOS only
    
    public init(
        aliasSortFilterRequest: AliasSortFilterRequest,
        filterId: String?
        ) {
            self.aliasSortFilterRequest = aliasSortFilterRequest
            self.filterId = filterId
        }
    
}

public struct AliasSortFilterRequest:Codable, Equatable {
    public var onlyActiveAliases: Bool
    public var onlyDeletedAliases: Bool
    public var onlyInactiveAliases: Bool
    public var onlyWatchedAliases: Bool
    public var sort: String?
    public var sortDesc: Bool
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

