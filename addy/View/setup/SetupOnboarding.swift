//
//  SetupHowView.swift
//  addy
//
//  Created by Stijn van de Water on 06/05/2024.
//

import SwiftUI
import addy_shared

struct SetupOnboarding: View {
    @State private var selectedPage = 0
    @State private var openRegistrationFormBottomSheet = false
    @Binding var showOnboarding: Bool

    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
        
        NavigationStack(){
            
            ZStack {
                Rectangle()
                    .fill(.nightMode)
                    .opacity(0.6)
                    .edgesIgnoringSafeArea(.all)
                
                VStack{
                    TabView(selection: $selectedPage) {
                        Page1View(selectedPage: $selectedPage)
                            .tag(0)
                        Page2View(selectedPage: $selectedPage)
                            .tag(1)
                        Page3View(selectedPage: $selectedPage)
                            .tag(2)
                        Page4View(openRegistrationFormBottomSheet: $openRegistrationFormBottomSheet)
                            .tag(3)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
                
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(LinearGradient(gradient: Gradient(colors: [Color("AddySecondaryColor"), Color("AccentColor")]),
                                           startPoint: .top, endPoint: .bottom))
                .edgesIgnoringSafeArea(.all)
                .navigationTitle(String(localized: "getting_started"))
        }.sheet(isPresented: $openRegistrationFormBottomSheet) {
            RegistrationFormBottomSheet(showOnboarding: $showOnboarding)
        }
        
    }
    
    struct Page1View: View {
        @Binding var selectedPage: Int
        
        var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
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
                    
                    let setupHow1DescFormattedString = String.localizedStringWithFormat(NSLocalizedString("setup_how_1_desc", comment: ""))
                    Text(LocalizedStringKey(setupHow1DescFormattedString))
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
                }.padding(.bottom)
                
            }.padding(.horizontal, 32)
            
        }
    }
    
    struct Page2View: View {
        @Binding var selectedPage: Int
        
        var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
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
                    
                    let setupHow2DescFormattedString = String.localizedStringWithFormat(NSLocalizedString("setup_how_2_desc", comment: ""))
                    Text(LocalizedStringKey(setupHow2DescFormattedString))
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
                }.padding(.bottom)
                
            }.padding(.horizontal, 32)
            
        }
    }
    
    struct Page3View: View {
        @Binding var selectedPage: Int
        
        var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
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
                    
                    let setupHow3DescFormattedString = String.localizedStringWithFormat(NSLocalizedString("setup_how_3_desc", comment: ""))
                    Text(LocalizedStringKey(setupHow3DescFormattedString))
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
                }.padding(.bottom)
                
            }.padding(.horizontal, 32)
            
        }
    }
    
    struct Page4View: View {
        @Binding var openRegistrationFormBottomSheet: Bool

        var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
            VStack {
                ScrollView{
                    Image("logo-horizontal").resizable().scaledToFit().frame(maxHeight: 100).padding()

                    Text(String(localized: "setup_how_4"))
                        .font(.title2)
                        .bold()
                        .multilineTextAlignment(.center)
                    
                    Text(String(localized: "setup_how_4_title"))
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .opacity(0.5)
                    
                }
                
                AddyButton(action: {
                    openRegistrationFormBottomSheet = true
                }
                ) {
                    Text(String(localized: "get_started")).foregroundColor(Color.white)
                }.padding(.bottom)
                
            }.padding(.horizontal, 32)
            
        }
    }
}

#Preview {
    SetupOnboarding(showOnboarding: .constant(false))
}
