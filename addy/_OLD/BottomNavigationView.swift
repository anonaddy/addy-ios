//
//  BottomNavigationView.swift
//  addy
//
//  Created by Stijn van de Water on 08/05/2024.
//

import SwiftUI
import Combine

struct BottomNavigationView: View {
    @EnvironmentObject var mainViewState: MainViewState
    @EnvironmentObject var appBarViewState: AppBarViewState
    
    
    var body: some View {
        TabView() {
            HomeView().environmentObject(mainViewState)
                .tabItem {
                    Label(String(localized: "home"), systemImage: "house")
                }
            AliasesView().environmentObject(mainViewState)
                .tabItem {
                    Label(String(localized: "aliases"), systemImage: "at.circle")
                }
            RecipientsView().environmentObject(mainViewState)
                .tabItem {
                    Label(String(localized: "recipients"), systemImage: "person.2")
                }
        }
    }
}
    

struct BottomNavigationView_Previews: PreviewProvider {
    @StateObject static var mainViewState = MainViewState()

    static var previews: some View {
        
            if (mainViewState.userResourceData == nil){
                SplashView().environmentObject(mainViewState)
            } else {
                BottomNavigationView().environmentObject(mainViewState)
            }
            
    }
}
