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
        #if DEBUG
            let _ = Self._printChanges()
        #endif
        VStack(spacing: 0) {
            // Custom header mimicking section
            VStack(alignment: .leading, spacing: 12) {
                let formattedString = String.localizedStringWithFormat(NSLocalizedString("app_changelog", comment: ""))
                Text(LocalizedStringKey(formattedString))
                    .multilineTextAlignment(.leading)
                    .padding(.top, 20)  // Safe top spacing
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .background(Color.clear)
            
            Spacer()
        }
        .ignoresSafeArea(.container, edges: .bottom)  // Extend to bottom if needed
        .navigationTitle(String(localized: "changelog"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { /* unchanged */ }
    }

}

#Preview {
    ChangelogBottomSheet()
}
