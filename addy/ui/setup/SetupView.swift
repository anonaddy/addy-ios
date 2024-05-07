//
//  SetupView.swift
//  addy
//
//  Created by Stijn van de Water on 06/05/2024.
//

import SwiftUI
import addy_shared

struct SetupView: View {
    @EnvironmentObject var appState: AppState
    
    let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
    @State private var text = String(localized: "setup_api_key")
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var isLoadingGetStarted: Bool = false
    
    @State private var showOnboarding = false
    @State private var isPresentingAddApiBottomSheet = false

    

    
    var body: some View {
        
        NavigationStack{
            
            
            ZStack {
                
                Color("SetupViewBackgroundColor")
                    .edgesIgnoringSafeArea(.all)
                Rectangle() .fill(.ultraThinMaterial)
                    .fill(LinearGradient(gradient: Gradient(colors: [Color("SecondaryColor"), Color("AccentColor")]),
                                         startPoint: .top, endPoint: .bottom))
                    .opacity(1)
                    .edgesIgnoringSafeArea(.all)
                
                Rectangle()
                    .fill(Color.black)
                    .opacity(0.35)
                    .edgesIgnoringSafeArea(.all)
                
                /*
                 SwiftUI’s Text view automatically adds an ellipsis (…) when the text is too long to fit in its container, even when the line limit is set to nil.
                 
                 To work around this, you can use a ScrollView to allow the text to scroll when it’s too long to fit in the available space.
                 */
                ScrollView {
                    Text(text)
                        .font(.system(size: 88))
                        .lineLimit(nil) // Allow the text to wrap onto multiple lines
                        .opacity(0.05)
                        .foregroundColor(Color.white)
                        .multilineTextAlignment(.center)
                        .blur(radius: 4)
                }
                .edgesIgnoringSafeArea(.all)
                .onReceive(timer) { _ in
                    text = getDummyAPIKey()
                }
                .allowsHitTesting(/*@START_MENU_TOKEN@*/false/*@END_MENU_TOKEN@*/)
                
                VStack {
                    
                    Spacer(minLength: 80)
                    Image("logo-horizontal").resizable().scaledToFit().frame(maxHeight: 100)
                    Text(String(localized: "anonymous_email_forwarding"))
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(Color.white)
                        .opacity(0.5)
                    Spacer(minLength: 30)
                    Text(String(localized: "setup_view_subtitle"))
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(Color.white)
                        .frame(width: 260)
                        .opacity(/*@START_MENU_TOKEN@*/0.8/*@END_MENU_TOKEN@*/)
                        .multilineTextAlignment(.center)
                    
                    VStack {
                        
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    VStack {
                        
                                               
                        AddyLoadingButton(action: {
                            let pasteboardString: String? = UIPasteboard.general.string
                            if let key = pasteboardString, key.count == 56 {
                                // A 56 length string found. This is most likely the API key

                                isLoadingGetStarted = true
                                debugPrint("API key copied from clipboard")
                                //TODO let the user know
                                
                                DispatchQueue.global(qos: .background).async {
                                    // AddyIo.API_BASE_URL is defaulted to the addy.io instance. If the API key is valid there it was meant to use that instance.
                                    // If the baseURL/API do not work or match it opens the API screen
                                    self.verifyApiKey(apiKey: key)
                                }
                                
                                
                            } else {
                                //FIXME This is a workaround to get the animation to run
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    isLoadingGetStarted = false
                                }
                                isPresentingAddApiBottomSheet = true
                            }
                            
                            
                        }, isLoading: $isLoadingGetStarted) {
                            Text(String(localized: "got_the_api_key")).foregroundColor(Color.white)
                        }
                        
                        
                        AddyButton(action: {
                            self.showOnboarding = true
                        }, style: AddyButtonStyle(buttonStyle: .secondary)) {
                            Text(String(localized: "new_user")).foregroundColor(Color.white)
                        }
                        
                        
                    }
                    .padding(32)
                    .navigationDestination(isPresented: $showOnboarding) {
                        SetupOnboarding()
                    }
                }
                
                
            }
            
        }.sheet(isPresented: $isPresentingAddApiBottomSheet) {
            AddApiBottomSheet(apiBaseUrl: nil, addKey: addKey(apiKey:baseUrl:))
        }
        
        
        
    }
    
    
    
    func getDummyAPIKey() -> String {
        var dummyApi = Array(text)
        dummyApi[Int.random(in: 0..<dummyApi.count)] = Array(chars)[Int.random(in: 0..<chars.count)]
        return String(dummyApi)
    }
    
    
    private func verifyApiKey(apiKey: String, baseUrl: String = AddyIo.API_BASE_URL) {
        let networkHelper = NetworkHelper()
        networkHelper.verifyApiKey(baseUrl: baseUrl, apiKey: apiKey) { result in
            DispatchQueue.main.async {
                if result == "200" {
                    self.addKey(apiKey: apiKey, baseUrl: baseUrl)
                } else {
                    isLoadingGetStarted = false
                    isPresentingAddApiBottomSheet = true
                }
            }
        }
    }
    
    private func addKey(apiKey: String, baseUrl: String) {
        let encryptedSettingsManager = SettingsManager(encrypted: true)
        encryptedSettingsManager.putSettingsString(key: SettingsManager.Prefs.apiKey, string: apiKey)
        encryptedSettingsManager.putSettingsString(key: SettingsManager.Prefs.baseUrl, string: baseUrl)
        isPresentingAddApiBottomSheet = false
        appState.apiKey = apiKey
    }
    
    
    
}
#Preview {
    SetupView()
}
