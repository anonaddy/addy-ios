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
    @State private var isPresentUnsupportedVersionBottomDialog = false
    @State private var networkHelper: NetworkHelper? = nil
    
    @Environment(\.openURL) var openURL

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
            loadDataAndStartApp()
        }
        .sheet(isPresented: $isPresentUnsupportedVersionBottomDialog, onDismiss: {
                isPresentUnsupportedVersionBottomDialog = false
            DispatchQueue.global(qos: .background).async {
                getUserResource()
            }
        }, content: {
            NavigationStack {
                UnsupportedBottomSheet {
                    openURL(URL(string: "https://github.com/anonaddy/anonaddy/blob/master/SELF-HOSTING.md#updating")!)
                } onClickIgnore: {
                    isPresentUnsupportedVersionBottomDialog = false
                    DispatchQueue.global(qos: .background).async {
                        getUserResource()
                    }
                }
            }
            .presentationDetents([.fraction(0.45), .large])
            // No cancel button so a drag indicator is a nice to have
            .presentationDragIndicator(.visible)
        })
    }
    
    private func loadDataAndStartApp(){
        // This helper inits the BASE_URL var
        self.networkHelper = NetworkHelper()
        
        if (AddyIo.API_BASE_URL == String(localized: "default_base_url")){
            
            AddyIo.VERSIONMAJOR = 9999
            AddyIo.VERSIONSTRING = String(localized: "latest")
            
            DispatchQueue.global(qos: .background).async {
                getUserResource()
            }
        } else {
            getAddyIoInstanceVersion()
        }
        
    }
    
    private func getAddyIoInstanceVersion() {
        networkHelper!.getAddyIoInstanceVersion { version, error in
                DispatchQueue.main.async {
                    if let version = version {
                        AddyIo.VERSIONMAJOR = version.major
                                            AddyIo.VERSIONMINOR = version.minor
                                            AddyIo.VERSIONPATCH = version.patch
                                            AddyIo.VERSIONSTRING = version.version ?? String(localized: "unknown")
                        
                        if (instanceHasTheMinimumRequiredVersion()){
                            DispatchQueue.global(qos: .background).async {
                                getUserResource()
                            }
                        } else {
                            self.isPresentUnsupportedVersionBottomDialog = true
                        }
                    } else {
                        self.showError = true
                    }
                }
            }
        }
    
    private func instanceHasTheMinimumRequiredVersion() -> Bool {
        if (AddyIo.VERSIONMAJOR > AddyIo.MINIMUMVERSIONCODEMAJOR) {
            return true
        } else if (AddyIo.VERSIONMAJOR >= AddyIo.MINIMUMVERSIONCODEMAJOR) {
            if (AddyIo.VERSIONMINOR > AddyIo.MINIMUMVERSIONCODEMINOR) {
                return true
            } else if (AddyIo.VERSIONMINOR >= AddyIo.MINIMUMVERSIONCODEMINOR) {
                if (AddyIo.VERSIONPATCH >= AddyIo.MINIMUMVERSIONCODEPATCH) {
                    return true
                }
            }
        }
        return false
    }
    
    
    private func getUserResource() {
        networkHelper!.getUserResource { userResource, error in
                DispatchQueue.main.async {
                    if let userResource = userResource {
                        mainViewState.userResource = userResource
                        
                        // Fetch UserResourceExtended data
                        networkHelper!.getSpecificRecipient(completion: { recipient, error in
                            DispatchQueue.main.async {
                                if let recipient = recipient {
                                    mainViewState.userResourceExtended = UserResourceExtended(default_recipient_email: recipient.email)
                                } else if error != nil {
                                    self.showError = true
                                }
                            }
                        }, recipientId: userResource.default_recipient_id)
                        
                    } else {
                        self.showError = true
                    }
                }
            }
        }
}



#Preview {
    SplashView()
}
