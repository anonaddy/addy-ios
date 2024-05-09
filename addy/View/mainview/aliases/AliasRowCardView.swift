//
//  AliasRowCardView.swift
//  addy
//
//  Created by Stijn van de Water on 09/05/2024.
//

import SwiftUI
import addy_shared

struct AliasRowCardView: View {
    
    let alias: Aliases

    var body: some View {
        
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    
                    Text(alias.email)
                        .font(.title)
                        .padding(.vertical, 5)
                    
                    Text(alias.id)
                        .lineLimit(5)
                }
            }
            .padding()
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(red: 150/255, green: 150/255, blue: 150/255, opacity: 0.2), lineWidth: 1)
                .shadow(radius: 1)
        )
        .padding([.top, .horizontal])
    }
}
