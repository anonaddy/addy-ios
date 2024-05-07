//
//  SetupHowView.swift
//  addy
//
//  Created by Stijn van de Water on 06/05/2024.
//

import SwiftUI

struct SetupOnboarding: View {
    @State private var selectedPage = 0
    
    var body: some View {
        
        
        ZStack {
            Rectangle()
                .fill(Color.nightMode)
                .opacity(0.6)
                .edgesIgnoringSafeArea(.all)
            
            VStack{
                HStack {
                    Text(String(localized: "getting_started"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top)
                                            .padding(.horizontal)
                    Spacer()
                }
                .frame(height: 180) // Adjust this to change the height of the toolbar
                .background(Color.white.opacity(0))
                .edgesIgnoringSafeArea(.top) // This makes the toolbar extend
                
                TabView(selection: $selectedPage) {
                    Page1View(selectedPage: $selectedPage)
                        .tag(0)
                    Page2View(selectedPage: $selectedPage)
                        .tag(1)
                    Page3View(selectedPage: $selectedPage)
                        .tag(2)
                    Page4View()
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LinearGradient(gradient: Gradient(colors: [Color("SecondaryColor"), Color("AccentColor")]),
                                       startPoint: .top, endPoint: .bottom))
            .edgesIgnoringSafeArea(.all)
        
    }
    
    struct Page1View: View {
        @Binding var selectedPage: Int
        
        var body: some View {
            
            VStack {
                ScrollView{
                    Image("register").resizable().scaledToFit().frame(maxHeight: 200)
                    Text(String(localized: "setup_how_1"))
                        .font(.title2)
                        .bold()
                        .multilineTextAlignment(.center)
                    
                    Text(String(localized: "setup_how_1_title"))
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .opacity(0.5)
                    
                    Text(String(localized: "setup_how_1_desc"))
                        .padding()
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                    
                }
                
                AddyButton(action: {
                    withAnimation {
                        selectedPage += 1
                    }}
                ) {
                    Text(String(localized: "next")).foregroundColor(Color.white)
                }
                
            }.padding(.horizontal, 32)
            
        }
    }
    
    struct Page2View: View {
        @Binding var selectedPage: Int
        
        var body: some View {
            
            VStack {
                ScrollView{
                    Image("email_aliases").resizable().scaledToFit().frame(maxHeight: 200)
                    Text(String(localized: "setup_how_2"))
                        .font(.title2)
                        .bold()
                        .multilineTextAlignment(.center)
                    
                    Text(String(localized: "setup_how_2_title"))
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .opacity(0.5)
                    
                    Text(String(localized: "setup_how_2_desc"))
                        .padding()
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                    
                }
                
                AddyButton(action: {
                    withAnimation {
                        selectedPage += 1
                    }}
                ) {
                    Text(String(localized: "next")).foregroundColor(Color.white)
                }
                
            }.padding(.horizontal, 32)
            
        }
    }
    
    struct Page3View: View {
        @Binding var selectedPage: Int
        
        var body: some View {
            
            VStack {
                ScrollView{
                    Image("dashboard").resizable().scaledToFit().frame(maxHeight: 200)
                    Text(String(localized: "setup_how_3"))
                        .font(.title2)
                        .bold()
                        .multilineTextAlignment(.center)
                    
                    Text(String(localized: "setup_how_3_title"))
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .opacity(0.5)
                    
                    Text(String(localized: "setup_how_3_desc"))
                        .padding()
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                    
                }
                
                AddyButton(action: {
                    withAnimation {
                        selectedPage += 1
                    }}
                ) {
                    Text(String(localized: "next")).foregroundColor(Color.white)
                }
                
            }.padding(.horizontal, 32)
            
        }
    }
    
    struct Page4View: View {
        @Environment(\.openURL) var openURL
        @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

        var body: some View {
            
            VStack {
                ScrollView{
                    Image("icon-monocolor").resizable().scaledToFit().frame(maxHeight: 100).padding()
                    Text(String(localized: "setup_how_4"))
                        .font(.title2)
                        .bold()
                        .multilineTextAlignment(.center)
                    
                    Text(String(localized: "setup_how_4_title"))
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .opacity(0.5)
                    
                    Text(String(localized: "setup_how_4_desc"))
                        .padding()
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                    
                }
                
                AddyButton(action: {
                    withAnimation {
                        openURL(URL(string: "https://app.addy.io/register")!)
                        self.presentationMode.wrappedValue.dismiss()

               }}
                ) {
                    Text(String(localized: "sign_up")).foregroundColor(Color.white)
                }
                
            }.padding(.horizontal, 32)
            
        }
    }
}

#Preview {
    SetupOnboarding()
}
