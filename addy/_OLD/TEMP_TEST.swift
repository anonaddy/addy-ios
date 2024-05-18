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
                       // Add your delete action here
                       print("Delete button tapped")
                   }) {
                       HStack {
                           Image(systemName: "trash")
                               .foregroundColor(.softRed)
                           
                           VStack(alignment: .leading) {
                               Text("delete_alias")
                                   .font(.callout)
                                   .foregroundColor(.softRed)
                               Text("delete_alias_desc")
                                   .font(.subheadline)
                                   .foregroundColor(.secondary)
                                   .multilineTextAlignment(/*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/)
                           }
                       }
                   }
                   .buttonStyle(BorderlessButtonStyle()) // Ensure the button looks plain without default styles
        }.padding(.top, 8)
    }
    

    
}

#Preview {
    TEMP_TEST()
}
