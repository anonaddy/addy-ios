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
        HStack {
            
            Button(action: {
            }) {
                Label(String(localized: "copied"), systemImage: "clipboard")
                    .foregroundColor(.white)
                    .frame(maxWidth:.infinity, maxHeight: 12)
                    .font(.system(size: 16))
                
                
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
            .contentTransition(.symbolEffect(.replace))
            .padding(.horizontal)
            Spacer()
            Button(action: {
                //self.copyToClipboard(alias: alias)
            }) {
                Label(String(localized: "send_mail"), systemImage: "paperplane")
                    .foregroundColor(.white)
                    .frame(maxWidth:.infinity, maxHeight: 16)
                    .font(.system(size: 16))
                
                
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
            .contentTransition(.symbolEffect(.replace))
            .padding(.horizontal)
        }.padding(.top, 8)
        
    }
    
    

    
}

#Preview {
    TEMP_TEST()
}
