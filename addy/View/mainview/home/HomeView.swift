//
//  HomeView.swift
//  addy
//
//  Created by Stijn van de Water on 08/05/2024.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var mainViewState: MainViewState

    var body: some View {
        
        Group {
            ScrollView(.vertical) {
                VStack{
                    ForEach(1..<666) { i in
                        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
                    }
                }.frame(maxWidth: .infinity)
            }
        }


    }
}

#Preview {
    HomeView()
}
