//
//  TEMP_TEST.swift
//  addy
//
//  Created by Stijn van de Water on 10/05/2024.
//

import SwiftUI

struct TEMP_TEST: View {
    @State private var isAliasBeingWatched: Bool = false

    var body: some View {
        Toggle(isOn: $isAliasBeingWatched) {
            HStack{
                Image(systemName: "eyes.inverse")
                                        .padding()
                                        .frame(width: 32, height: 32)
                                        .background(Color.gray.opacity(0.9))
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                        .foregroundColor(.white)
                                        .padding()
                                        
                
                VStack(alignment: .leading) {
                    Text(String(localized: "watch_alias"))
                        .font(.callout)
                    Text(String(localized: "watch_alias_desc"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
        }.tint(.accentColor)
    }
    

    
}

#Preview {
    TEMP_TEST()
}
