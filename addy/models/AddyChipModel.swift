//
//  AddyChipModel.swift
//  addy_shared
//
//  Created by Stijn van de Water on 06/07/2024.
//

import Foundation

class AddyChipModel:Identifiable{
    let id = UUID()
    let chipId: String
    let label:String
    
    init(chipId:String, label: String) {
        self.chipId = chipId
        self.label = label
    }
}
