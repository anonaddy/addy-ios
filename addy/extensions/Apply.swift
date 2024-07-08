//
//  Apply.swift
//  addy
//
//  Created by Stijn van de Water on 17/06/2024.
//
import SwiftUI
    
extension View {
    func apply<V: View>(@ViewBuilder _ block: (Self) -> V) -> V { block(self) }
}
