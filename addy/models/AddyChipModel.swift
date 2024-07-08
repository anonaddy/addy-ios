//
//  AddyChipModel.swift
//  addy_shared
//
//  Created by Stijn van de Water on 06/07/2024.
//

import Foundation

public class AddyChipModel:Identifiable{
    public let id = UUID()
    public let chipId: String
    public let label:String
    
    public init(chipId:String, label: String) {
        self.chipId = chipId
        self.label = label
    }
}
