//
//  Version.swift
//  addy_shared
//
//  Created by Stijn van de Water on 07/05/2024.
//

import Foundation

struct Version: Decodable {
    let major: Int
    let minor: Int
    let patch: Int
    let version: String?
}
