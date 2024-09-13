//
//  Version.swift
//  addy_shared
//
//  Created by Stijn van de Water on 07/05/2024.
//

import Foundation

public struct Version: Decodable {
    public let major: Int
    public let minor: Int
    public let patch: Int
    public let version: String?
}
