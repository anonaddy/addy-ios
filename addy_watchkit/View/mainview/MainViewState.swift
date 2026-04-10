//
//  MainViewState.swift
//  addy
//
//  Created by Stijn van de Water on 01/02/2026.
//

import addy_shared
import Combine
import SwiftUI

class MainViewState: ObservableObject {
    static let shared = MainViewState() // Shared instance

    @Published var encryptedSettingsManager = SettingsManager(encrypted: true)

    let userResourceChanged = PassthroughSubject<Void, Never>()

    @Published var userResourceData: String? {
        didSet {
            userResourceData.map { encryptedSettingsManager.putSettingsString(key: .userResource, string: $0) }
            userResourceChanged.send()
        }
    }

    var userResource: UserResource? {
        get {
            if let jsonString = userResourceData,
               let jsonData = jsonString.data(using: .utf8)
            {
                let decoder = JSONDecoder()
                return try? decoder.decode(UserResource.self, from: jsonData)
            }
            return nil
        }
        set {
            if let newValue = newValue {
                let encoder = JSONEncoder()
                if let jsonData = try? encoder.encode(newValue),
                   let jsonString = String(data: jsonData, encoding: .utf8)
                {
                    userResourceData = jsonString
                }
                userResourceChanged.send()
            }
        }
    }
}
