//
//  TEMP_TEST.swift
//  addy
//
//  Created by Stijn van de Water on 10/05/2024.
//

import SwiftUI

struct TEMP_TEST: View {
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Spacer()
            ContentUnavailableView {
                Label(String(localized: "obtaining_aliases"), systemImage: "globe")
            } description: {
                Text(String(localized: "obtaining_aliases_desc"))
            }
            
            ProgressView()
                .foregroundColor(.black)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity, maxHeight:50)
            Spacer()
        }
    }
}

#Preview {
    TEMP_TEST()
}
