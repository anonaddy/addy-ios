//
//  HomeView.swift
//  addy
//
//  Created by Stijn van de Water on 08/05/2024.
//

import SwiftUI



struct HomeView: View {

    @EnvironmentObject var mainViewState: MainViewState
    @Binding var horizontalSize: UserInterfaceSizeClass
    var onRefreshGeneralData: (() -> Void)? = nil

    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
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
                FailedDeliveriesIcon(horizontalSize: $horizontalSize).environmentObject(mainViewState)
            }
        }.refreshable {
            // When refreshing aliases also ask the mainView to update general data
            self.onRefreshGeneralData?()
        }
        
           


    }
}

//#Preview {
//    HomeView()
//}
