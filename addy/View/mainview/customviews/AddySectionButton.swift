//
//  AddySection.swift
//  addy
//
//  Created by Stijn van de Water on 12/05/2024.
//

import SwiftUI

struct AddySectionButton: View {
    
    var title: String
    var description: String? = nil
    var leadingSystemimage: String? = nil
    var fontWeight: Font.Weight = .medium
    var colorAccent: Color? = .black
    var isLoading: Bool = false
    let onTap: () -> Void

    
    var body: some View {
        
        Button(action: {
            self.onTap()
               }) {
                   HStack {
                       
                       if let leadingSystemimage = leadingSystemimage {
                           Image(systemName: leadingSystemimage)
                               .fontWeight(fontWeight)
                               .foregroundColor(colorAccent)
                       }
                       
                       VStack(alignment: .leading) {
                           Text(title)
                               .font(.callout)
                               .foregroundColor(colorAccent)
                               .lineLimit(/*@START_MENU_TOKEN@*/2/*@END_MENU_TOKEN@*/)
                           
                           if let description = description {
                               Text(description)
                                   .font(.subheadline)
                                   .foregroundColor(.secondary)
                                   .multilineTextAlignment(.leading
                                   )
                           }
                         
                       }
                       
                       if isLoading {
                           Spacer(minLength: 15)
                           
                           ProgressView() // Loading indicator
                               .progressViewStyle(CircularProgressViewStyle())
                       }
                   }
               }
               .buttonStyle(BorderlessButtonStyle()) // Ensure the button looks plain without default styles
    }
}

#Preview {
//    AddySection(title: "Section title", description: "This is a nice long description to show off the functionalities of the AddySection inside this beautiful SwiftUI application", leadingSystemimage: "eyes", trailingSystemimage: "pencil")
//
    
    AddySectionButton(title: "Section title", description: nil, leadingSystemimage: "eyes", isLoading: true){
        print("TAPPP")
    }
}
