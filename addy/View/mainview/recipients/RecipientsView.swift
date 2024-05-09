//
//  RecipientView.swift
//  addy
//
//  Created by Stijn van de Water on 08/05/2024.
//

import SwiftUI

struct RecipientsView: View {
    @EnvironmentObject var mainViewState: MainViewState

    var body: some View {
        Text("Hello, \(mainViewState.userResource!.username)")
    }
}


#Preview {
    RecipientsView()
}
