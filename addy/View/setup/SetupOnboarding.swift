//
//  SetupOnboarding.swift
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
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color("AddySecondaryColor"), Color("AccentColor")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Night mode overlay
                Rectangle()
                    .fill(.nightMode)
                    .opacity(0.6)
                    .ignoresSafeArea()
                
                // Main content
                VStack {
                    // Custom toolbar content
                    HStack {
                        Spacer()
                        Text(String(localized: "getting_started"))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    
                    TabView(selection: $selectedPage) {
                        PageView(
                            imageName: "register",
                            title: "setup_how_1",
                            subtitle: "setup_how_1_title",
                            description: "setup_how_1_desc",
                            buttonText: "next",
                            action: { selectedPage += 1 },
                            imageHeight: 200
                        ).tag(0)
                        
                        PageView(
                            imageName: "email_aliases",
                            title: "setup_how_2",
                            subtitle: "setup_how_2_title",
                            description: "setup_how_2_desc",
                            buttonText: "next",
                            action: { selectedPage += 1 },
                            imageHeight: 200
                        ).tag(1)
                        
                        PageView(
                            imageName: "dashboard",
                            title: "setup_how_3",
                            subtitle: "setup_how_3_title",
                            description: "setup_how_3_desc",
                            buttonText: "next",
                            action: { selectedPage += 1 },
                            imageHeight: 200
                        ).tag(2)
                        
                        PageView(
                            imageName: "logo-horizontal",
                            title: "setup_how_4",
                            subtitle: "setup_how_4_title",
                            description: nil,
                            buttonText: "get_started",
                            action: { openRegistrationFormBottomSheet = true },
                            imageHeight: 100
                        ).tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
                .frame(maxWidth: .infinity)
            }

        }
        .sheet(isPresented: $openRegistrationFormBottomSheet) {
            RegistrationFormBottomSheet(showOnboarding: $showOnboarding)
        }
    }
}

struct PageView: View {
    let imageName: String
    let title: String.LocalizationValue
    let subtitle: String.LocalizationValue
    let description: String.LocalizationValue?
    let buttonText: String.LocalizationValue
    let action: () -> Void
    let imageHeight: CGFloat?

    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
        VStack {
            ScrollView {
                VStack(spacing: 16) {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: imageHeight ?? 200)
                        .padding(.top, 16)
                        .padding(imageHeight != nil ? .all : .bottom)
                    
                    Text(String(localized: title))
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(String(localized: subtitle))
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .opacity(0.5)
                    
                    if let description = description {
                        Text(LocalizedStringKey(String(localized: description)))
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
            }
            
            Button(action: {
                withAnimation {
                    action()
                }
            }) {
                Text(String(localized: buttonText))
            }
            .padding(.vertical, 36) // Add vertical padding to ensure shadow has space
            .controlSize(.extraLarge)
            .apply({ View in
                if #available(iOS 26.0, *) {
                    View.buttonStyle(.glassProminent)
                } else {
                    View.buttonStyle(.borderedProminent)
                }
            })
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    SetupOnboarding(showOnboarding: .constant(false))
}
