//
//  AddyBugFound.swift
//  addy
//
//  Created by Stijn van de Water on 17/05/2024.
//

import SwiftUI

struct AddyBugFound: View {
    @Environment(\.openURL) var openURL

    var body: some View {
        ContentUnavailableView {
            Label(String(localized: "bug_found"), systemImage: "ladybug")
        } description: {
            Text(String(localized: "bug_found_desc"))
        } actions: {
            Button(String(localized: "report_an_issue")) {
                openURL(URL(string: "https://github.com/anonaddy/addy-ios/issues/new")!)
            }
        }
    }
}

#Preview {
    AddyBugFound()
}
