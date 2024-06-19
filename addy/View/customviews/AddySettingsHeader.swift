//
//  AddySettingsHeader.swift
//  addy
//
//  Created by Stijn van de Water on 12/06/2024.
//

import SwiftUI

struct AddySettingsHeader: View {
    
    var title: String
    var description: String
    var systemimage: String
    var systemimageColor: Color = .blue
    
    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
        Section {
           
            VStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(systemimageColor)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: systemimage)
                            .fontWeight(.medium)
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    )
                
                Text(title).fontWeight(.bold).padding(.bottom,2).multilineTextAlignment(.center).font(.title2)
                Text(description).multilineTextAlignment(.center).font(.subheadline)
            }.frame(maxWidth: .infinity, alignment: .center).padding()
           
            
        }
    }
}

#Preview {
    AddySettingsHeader(title: String(localized: "addyio_updater"), description: String(localized: "addyio_updater_header_desc"), systemimage: "arrow.down.circle.dotted", systemimageColor: .blue)
}
