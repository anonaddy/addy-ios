//
//  RecipientRowView.swift
//  addy
//
//  Created by Stijn van de Water on 09/05/2024.
//

import SwiftUI
import addy_shared

struct RecipientRowView: View {
    
    let recipient: Recipients
    let isPreview: Bool
    
    init(recipient: Recipients, isPreview: Bool) {
        self.recipient = recipient
        self.isPreview = isPreview
    }
    
    var body: some View {
        
        if isPreview {
            // Preview (long press) view
            VStack(alignment: .leading){
                Text(verbatim: recipient.email)
                    .font(.title3)
                    .bold()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 16, trailing: 0))
                
            }.padding()
            
        } else {
            // Preview (long press) view
            VStack(alignment: .leading){
                Text(verbatim: recipient.email)
                    .font(.title3)
                    .bold()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 16, trailing: 0))
                
            }.padding()
        }
    }
    
}

//#Preview {
//    AliasRowCardView()
//}

