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
    @EnvironmentObject var mainViewState: MainViewState
    @State private var showError = false
    
    var body: some View {
        
        Group {
            if showError {
                Color.accentColor
                    .ignoresSafeArea(.container) // Ignore just for the color
                    .overlay(
                        VStack(spacing: 20) {
                            LottieView(animation: .named("ic_loading_logo_error.shapeshifter"))
                                .playbackMode(.playing(.toProgress(1, loopMode: .playOnce)))
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
                        Text("Error DELETE ALL KEYCHAIN DATA").foregroundColor(Color.white)
                    }
                }
            } else {
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
        }.task {
            getUserData()
        }
    }
    
    private func getUserData() {
        let networkHelper = NetworkHelper()
        networkHelper.getUserResource { userResource, error in
                DispatchQueue.main.async {
                    if let userResource = userResource {
                        mainViewState.userResource = userResource
                        
                        // Fetch UserResourceExtended data
                        networkHelper.getSpecificRecipient(completion: { recipient, error in
                            DispatchQueue.main.async {
                                if let recipient = recipient {
                                    mainViewState.userResourceExtended = UserResourceExtended(default_recipient_email: recipient.email)
                                } else if let error = error {
                                    print("Error: \(error)")
                                    self.showError = true
                                }
                            }
                        }, recipientId: userResource.default_recipient_id)
                        
                    } else if let error = error {
                        print("Error: \(error)")
                        self.showError = true
                    }
                }
            }
        }
}



#Preview {
    SplashView()
}
