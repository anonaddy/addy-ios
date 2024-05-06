//
//  Item.swift
//  addy
//
//  Created by Stijn van de Water on 06/05/2024.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
