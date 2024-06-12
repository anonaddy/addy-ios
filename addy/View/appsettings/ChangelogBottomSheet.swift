//
//  ChangelogBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 12/06/2024.
//

import SwiftUI

struct ChangelogBottomSheet: View {
    
    @Environment(\.dismiss) var dismiss

    var body: some View {
        List{
            Section{
                let formattedString = String.localizedStringWithFormat(NSLocalizedString("app_changelog", comment: ""))
                Text(LocalizedStringKey(formattedString))
                    .multilineTextAlignment(.leading)
                    .padding(.bottom)
            }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())
           
        }.navigationTitle(String(localized: "changelog")).pickerStyle(.navigationLink)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem() {
                    Button {
                        dismiss()
                    } label: {
                        Label(String(localized: "dismiss"), systemImage: "xmark.circle.fill")
                    }
                    
                }
            })
    }
}

#Preview {
    ChangelogBottomSheet()
}
