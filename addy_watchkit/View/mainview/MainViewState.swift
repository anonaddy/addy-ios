//
//  MainViewState.swift
//  addy
//
//  Created by Stijn van de Water on 01/02/2026.
//

import addy_shared
import Combine
import SwiftUI

@MainActor
class MainViewState: ObservableObject {
    static let shared = MainViewState() // Shared instance

    @Published var encryptedSettingsManager = SettingsManager(encrypted: true)

    let userResourceChanged = PassthroughSubject<Void, Never>()

    private var cachedUserResource: UserResource? = nil

    @Published var userResourceData: String? {
        didSet {
            if userResourceData == nil {
                cachedUserResource = nil
            } else if cachedUserResource == nil, let jsonString = userResourceData, let jsonData = jsonString.data(using: .utf8) {
                cachedUserResource = try? JSONDecoder().decode(UserResource.self, from: jsonData)
            }
            userResourceData.map { encryptedSettingsManager.putSettingsString(key: .userResource, string: $0) }
            userResourceChanged.send()
        }
    }

    var userResource: UserResource? {
        get {
            if cachedUserResource == nil,
               let jsonString = userResourceData,
               let jsonData = jsonString.data(using: .utf8)
            {
                cachedUserResource = try? JSONDecoder().decode(UserResource.self, from: jsonData)
            }
            return cachedUserResource
        }
        set {
            cachedUserResource = newValue
            if let newValue = newValue {
                let encoder = JSONEncoder()
                if let jsonData = try? encoder.encode(newValue),
                   let jsonString = String(data: jsonData, encoding: .utf8)
                {
                    userResourceData = jsonString
                }
            } else {
                userResourceData = nil
            }
        }
    }
}
