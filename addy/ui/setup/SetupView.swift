//
//  SetupView.swift
//  addy
//
//  Created by Stijn van de Water on 06/05/2024.
//

import SwiftUI

struct SetupView: View {
    
    let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
    @State private var text = String(localized: "setup_api_key")
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var isLoadingGetStarted: Bool = false
    @State var isLoadingExistingUser: Bool = false
    
    @State private var showOnboarding = false
    
    
    var existingUserLoadingButtonStyle = AddyButtonStyle(width: .infinity,
                                                         height: 56,
                                                         cornerRadius: 12,
                                                         backgroundColor: Color("AccentColor").opacity(0.4),
                                                         strokeWidth: 5,
                                                         strokeColor: .gray)
    
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
                            // Your Action here
                        }, isLoading: $isLoadingGetStarted) {
                            Text(String(localized: "got_the_api_key")).foregroundColor(Color.white)
                        }
                        
                        AddyButton(action: {
                            self.showOnboarding = true
                        }, style: existingUserLoadingButtonStyle) {
                            Text(String(localized: "new_user")).foregroundColor(Color.white)
                        }
                        
                        
                    }
                    .padding(32)
                    .navigationDestination(isPresented: $showOnboarding) {
                        SetupOnboarding()
                            }
                }
                
                
            }  .preferredColorScheme(.dark) // white tint on status bar

        }
    }
    
    
    func getDummyAPIKey() -> String {
        var dummyApi = Array(text)
        dummyApi[Int.random(in: 0..<dummyApi.count)] = Array(chars)[Int.random(in: 0..<chars.count)]
        return String(dummyApi)
    }
}

#Preview {
    SetupView()
}
