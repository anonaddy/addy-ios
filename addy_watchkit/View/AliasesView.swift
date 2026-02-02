//
//  ContentView.swift
//  Addy Watchkit Watch App
//
//  Created by Stijn van de Water on 31/01/2026.
//

import SwiftUI

struct AliasesView: View {
    @EnvironmentObject var mainViewState: MainViewState
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    AliasesView()
}
