//
//  CacheHelper.swift
//  addy_shared
//
//  Created by Stijn van de Water on 19/07/2024.
//

import Foundation

public struct CacheHelper {
    public static func getBackgroundServiceCacheMostActiveAliasesData() -> [Aliases]? {
        let aliasesJson = SettingsManager(encrypted: true).getSettingsString(key: .backgroundServiceCacheMostActiveAliasesData)
        return aliasesJson != nil ? GsonTools.jsonToAliasObject(json: aliasesJson!) : nil
    }

    func getBackgroundServiceCacheLastUpdatedAliasesData() -> [Aliases]? {
        let aliasesJson = SettingsManager(encrypted: true).getSettingsString(key: .backgroundServiceCacheLastUpdatedAliasesData)
        return aliasesJson != nil ? GsonTools.jsonToAliasObject(json: aliasesJson!) : nil
    }

    func getBackgroundServiceCacheFavoriteAliasesData() -> [Aliases]? {
        let aliasesJson = SettingsManager(encrypted: true).getSettingsString(key: .backgroundServiceCacheFavoriteAliasesData)
        return aliasesJson != nil ? GsonTools.jsonToAliasObject(json: aliasesJson!) : nil
    }

    public static func getBackgroundServiceCacheUserResource() -> UserResource? {
        let userResourceJson = SettingsManager(encrypted: true).getSettingsString(key: .userResource)
        return userResourceJson != nil ? GsonTools.jsonToUserResourceObject(json: userResourceJson!) : nil
    }
}

