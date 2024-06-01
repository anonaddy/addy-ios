//
//  HomeView.swift
//  addy
//
//  Created by Stijn van de Water on 08/05/2024.
//

import SwiftUI

struct HomeView: View {
    @Binding var isPresentingProfileBottomSheet: Bool

    @EnvironmentObject var mainViewState: MainViewState

    var body: some View {
        
        NavigationStack(){
            ScrollView(.vertical) {
                VStack{
                    ForEach(1..<666) { i in
                        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
                    }
                }.frame(maxWidth: .infinity)
            }
        }.toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    self.isPresentingProfileBottomSheet = true

                }) {
                    Image(systemName: "person.crop.circle.fill")
                        .foregroundStyle(.primary)
                }
            }
        }
        .navigationTitle(String(localized: "home"))
           


    }
}

//#Preview {
//    HomeView()
//}
