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
    
    @State private var isShowingDetailedErrorAlert = false
    @State private var detailedError: String? = ""
    
    
    
    @Environment(\.openURL) var openURL

    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
        Group {
            if showError {
                Color.accentColor
                    .ignoresSafeArea(.container) // Ignore just for the color
                    .overlay(
                        VStack() {
                                VStack{
                                    Text(String(localized: "whoops"))
                                        .foregroundStyle(.white)
                                        .font(.title)
                                        .fontWeight(.heavy)
                                        .padding(.bottom)
                                    Text(String(localized: "addyio_load_error"))
                                        .foregroundStyle(.white)
                                        .font(.subheadline)
                                        .multilineTextAlignment(.center)
                                        .padding(.bottom)
                                    Text(String(localized: "tap_here_to_see_the_error"))
                                        .foregroundStyle(.red)
                                        .font(.subheadline)
                                        .multilineTextAlignment(.center)
                                        .onTapGesture {
                                            isShowingDetailedErrorAlert = true
                                        }
                                }.padding()
                                Spacer()
                                LottieView(animation: .named("ic_loading_logo_error.shapeshifter"))
                                    .playbackMode(.playing(.toProgress(1, loopMode: .playOnce)))
                                    .animationSpeed(Double(2))
                                    .frame(maxHeight: 128)
                                    .opacity(0.5)
                                Spacer()
                                Spacer()
                                HStack{
                                    AddyButton(action: {
                                        loadDataAndStartApp()
                   
                                    }, style: AddyButtonStyle(backgroundColor: .easternBlue)) {
                                        Text(String(localized: "try_again")).foregroundColor(Color.white)
                                    }
                                    
                                    AddyButton(action: {
                                        let settingsManager = SettingsManager(encrypted: true)
                                        settingsManager.clearSettingsAndCloseApp()
                   
                                    }, style: AddyButtonStyle(backgroundColor: .easternBlue)) {
                                        Text(String(localized: "reset_app")).foregroundColor(Color.white)
                                    }
                                }.padding()
                            
                        })
                
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
            }
        }.task {
            loadDataAndStartApp()
        }
        .alert(isPresented: $isShowingDetailedErrorAlert, content: {
            Alert(
                title: Text(String(localized: "error")), message: Text(detailedError ?? String(localized: "unknown"))
            )
        })
        .sheet(isPresented: $isPresentUnsupportedVersionBottomDialog, onDismiss: {
                isPresentUnsupportedVersionBottomDialog = false
            Task {
                await getUserResource()
            }
        }, content: {
            NavigationStack {
                UnsupportedBottomSheet {
                    openURL(URL(string: "https://github.com/anonaddy/anonaddy/blob/master/SELF-HOSTING.md#updating")!)
                } onClickIgnore: {
                    isPresentUnsupportedVersionBottomDialog = false
                    Task {
                        await getUserResource()
                    }
                }
            }
            .presentationDetents([.fraction(0.45), .large])
            // No cancel button so a drag indicator is a nice to have
            .presentationDragIndicator(.visible)
        })
    }
    
    private func loadDataAndStartApp(){
        self.showError = false
        // This helper inits the BASE_URL var
        self.networkHelper = NetworkHelper()
        
        if (AddyIo.API_BASE_URL == String(localized: "default_base_url")){
            
            AddyIo.VERSIONMAJOR = 9999
            AddyIo.VERSIONSTRING = String(localized: "latest")
            
            Task {
                await getUserResource()
            }
        } else {
            Task {
                await getAddyIoInstanceVersion()
            }
        }
        
    }
    
    private func getAddyIoInstanceVersion() async {
        do {
            let version = try await networkHelper!.getAddyIoInstanceVersion()
            if let version = version {
                AddyIo.VERSIONMAJOR = version.major
                AddyIo.VERSIONMINOR = version.minor
                AddyIo.VERSIONPATCH = version.patch
                AddyIo.VERSIONSTRING = version.version ?? String(localized: "unknown")
                
                if instanceHasTheMinimumRequiredVersion() {
                    await getUserResource()
                } else {
                    self.isPresentUnsupportedVersionBottomDialog = true
                }
            }
        } catch {
            self.detailedError = error.localizedDescription
            self.showError = true
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
    
    
    private func getUserResource() async {
        let networkHelper = NetworkHelper()
        do {
            let userResource = try await networkHelper.getUserResource()
            if let userResource = userResource {
                mainViewState.userResource = userResource
                
                // Fetch UserResourceExtended data
                let recipient = try await networkHelper.getSpecificRecipient(recipientId: userResource.default_recipient_id)
                if let recipient = recipient {
                    mainViewState.userResourceExtended = UserResourceExtended(default_recipient_email: recipient.email)
                } else {
                    self.showError = true
                }
            } else {
                self.showError = true
            }
        } catch {
            self.detailedError = error.localizedDescription
            self.showError = true
        }
    }

}



#Preview {
    SplashView()
}
