//
//  IdentifiableURL.swift
//  addy
//
//  Created by Stijn van de Water on 20/07/2024.
//

import Foundation


struct IdentifiableURL: Identifiable {
        let id = UUID()
        let url: URL
    }
