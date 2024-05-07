//
//  ContentView.swift
//  addy
//
//  Created by Stijn van de Water on 06/05/2024.
//

import SwiftUI
import SwiftData
import Lottie
import addy_shared

struct SplashView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        
        Color.accentColor
            .ignoresSafeArea(.container) // Ignore just for the color
            .overlay(
                VStack(spacing: 20) {
                    LottieView(animation: .named("ic_loading_logo.shapeshifter"))
                        .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                        .animationSpeed(Double(2))
                        .frame(maxHeight: 128)
                        .opacity(0.5)
                    
                })
        
        VStack{
            
            AddyButton(action: {
                let settingsManager = SettingsManager(encrypted: true)
                settingsManager.clearAllData()
                exit(0)
                
                
            }, style: AddyButtonStyle(buttonStyle: .primary)) {
                Text("DELETE ALL KEYCHAIN DATA").foregroundColor(Color.white)
            }
            
        }
    }
}



#Preview {
    SplashView()
}
