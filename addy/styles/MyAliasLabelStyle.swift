//
//  MyAliasLabelStyle.swift
//  addy
//
//  Created by Stijn van de Water on 11/05/2024.
//

import SwiftUI

struct MyAliasLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.title
            configuration.icon
                // fix your width here
                // width could also be passed as a initialiser parameter
                .frame(width: 20, height: 10)
        }
    }
}
