//
//  AppBarView.swift
//  addy
//
//  Created by Stijn van de Water on 08/05/2024.
//

import SwiftUI

class AppBarViewState: ObservableObject {
    @Published var title: String = "Title"
    @Published var subtitle: String? = "Subtitle"
}

struct AppBarView: View {
    @EnvironmentObject var appBarViewState: AppBarViewState
    
    
    var body: some View {
        VStack{
            Spacer()
            HStack {
                VStack {
                    VStack(alignment: .leading) {
                        Text(appBarViewState.title)
                            .font(.title)
                            .foregroundStyle(.white)
                            .bold()
                            .offset(y: appBarViewState.subtitle != nil ? 0 : 10)
                        
                        if appBarViewState.subtitle != nil {
                            Text(appBarViewState.subtitle!)
                                .font(.subheadline)
                                .foregroundStyle(.white)
                                .transition(.opacity)
                        }
                    }.padding(.bottom, 34)
                        .id(appBarViewState.title)
                        .id(appBarViewState.subtitle)
                    
                }.frame(height: 60) // Adjust this value as needed
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: {
                        print("Search button tapped")
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.white)
                    }
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
                    
                    Button(action: {
                        print("Mail button tapped")
                    }) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.white)
                        
                    }
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
                    
                    Button(action: {
                        print("User initials tapped")
                    }) {
                        Text("SV")
                            .font(.title)
                            .bold()
                            .minimumScaleFactor(0.2)
                            .padding(7)
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                        
                    }                    .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }.padding(.bottom, 12)
            }
        }
        .padding(.horizontal)
        .frame(height: 120)
        .background(Color.accentColor)
    }
}

struct AppBarView_Previews: PreviewProvider {
    @StateObject static var appBarViewState = AppBarViewState()
    

    static var previews: some View {
        Group {
            AppBarView().environmentObject(appBarViewState)
        }
    }
}
