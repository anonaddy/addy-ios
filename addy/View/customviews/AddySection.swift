//
//  AddySection.swift
//  addy
//
//  Created by Stijn van de Water on 12/05/2024.
//

import SwiftUI

struct AddySection: View {
    
    var title: String
    var description: String? = nil
    var leadingSystemimage: String? = nil
    var trailingSystemimage: String? = nil
    var fontWeight: Font.Weight = .medium
    
    
    var body: some View {
        HStack {
            if let leadingSystemimage = leadingSystemimage {
                
                Image(systemName: leadingSystemimage)
                    .fontWeight(fontWeight)
            }
            VStack(alignment: .leading) {
                Text(title)
                    .font(.callout)
                
                if let description = description{
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(/*@START_MENU_TOKEN@*/2/*@END_MENU_TOKEN@*/)
                }
                
            }
            Spacer()
            if let trailingSystemimage = trailingSystemimage {
                
                Image(systemName: trailingSystemimage)
                    .fontWeight(fontWeight)
            }

        }
    }
}

#Preview {
//    AddySection(title: "Section title", description: "This is a nice long description to show off the functionalities of the AddySection inside this beautiful SwiftUI application", leadingSystemimage: "eyes", trailingSystemimage: "pencil")
//    
    AddySection(title: "Section title", description: nil, leadingSystemimage: "eyes", trailingSystemimage: "pencil")
}
