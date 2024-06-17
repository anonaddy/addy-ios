//
//  HomeView.swift
//  addy
//
//  Created by Stijn van de Water on 08/05/2024.
//

import SwiftUI



struct HomeView: View {

    @EnvironmentObject var mainViewState: MainViewState
    @State private var lastHostingView: UIView!

    var body: some View {
        
        NavigationStack(){
            List {
                VStack{
                    ForEach(1..<666) { i in
                        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
                    }
                }.frame(maxWidth: .infinity)
            }        
            .navigationTitle(String(localized: "home"))
            .toolbar {
                ProfilePicture().environmentObject(mainViewState)
            }
        }
        
           


    }
}

//#Preview {
//    HomeView()
//}
