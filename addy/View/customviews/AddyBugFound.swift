//
//  AddyBugFound.swift
//  addy
//
//  Created by Stijn van de Water on 17/05/2024.
//

import SwiftUI

struct AddyBugFound: View {
    var body: some View {
        ContentUnavailableView {
            Label(String(localized: "bug_found"), systemImage: "ladybug")
        } description: {
            Text(String(localized: "bug_found_desc"))
        }
        
        //TODO: Add button to the github issues page
    }
}

#Preview {
    AddyBugFound()
}
