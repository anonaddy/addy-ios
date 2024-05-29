//
//  AddRecipientBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 12/05/2024.
//

import SwiftUI


import SwiftUI
import AVFoundation
import CodeScanner
import addy_shared

struct ProfileBottomSheet: View {
    //@EnvironmentObject var mainViewState: MainViewState

    let onNavigate: () -> Void

    init(onNavigate: @escaping () -> Void) {
        self.onNavigate = onNavigate
    }

    @Environment(\.dismiss) var dismiss

    var body: some View {
        
        let buttonStyle = AddyButtonStyle(width: .infinity,
                                           height: 56,
                                           cornerRadius: 12,
                                           buttonStyle: .primary,
                                           backgroundColor: Color("AccentColor"),
                                           strokeWidth: 5,
                                           strokeColor: .gray)

            
            List {
                
                Section{
                    VStack{
                        ZStack(alignment: .center) {
                            Circle()
                                .fill(LinearGradient(gradient: Gradient(colors: [Color.secondary.opacity(0.6), Color.secondary]), startPoint: .top, endPoint: .bottom))
                                .frame(width: 100, height: 100)
                            //Text(mainViewState.userResource!.username.prefix(2).uppercased())
                            Text("SV")
                                .font(.system(size: 40))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }.frame(maxWidth: .infinity).padding(.bottom,10)
                        
                        Text("USERNAME")
                            .font(.headline)
                        
                        Text("Pro user")
                            .font(.subheadline)
                            .opacity(0.6)
                        
                        Text("SUBSC expire")
                            .font(.subheadline)
                            .fontWeight(.light)
                            .opacity(0.6)
                        
                        AddyButton(action: {
                            // Action
                            },
                                   style: buttonStyle
                        ) {
                            Text(String(localized: "addyio_settings")).foregroundColor(Color.white)
                        }.padding(.top)
                    }
                }.listRowBackground(Color.clear)
                
                Section{
                    
                    AddySection(title: String(localized: "manage_domains"), description: String(localized: "manage_domains_desc"), trailingSystemimage: "chevron.right") {
                        self.onNavigate()
                    }

                    AddySection(title: String(localized: "manage_rules"), description: String(localized: "manage_rules_desc"), trailingSystemimage: "chevron.right") {
                        self.onNavigate()
                    }

                    AddySection(title: String(localized: "manage_usernames"), description: String(localized: "manage_usernames_desc"), trailingSystemimage: "chevron.right") {
                        self.onNavigate()
                    }
                    
                    AddySection(title: String(localized: "app_settings"), description: String(localized: "manage_domains_desc"), trailingSystemimage: "chevron.right") {
                        self.onNavigate()
                    }

                    
                } footer: {
                    VStack {
                        
                        
                        Spacer()
                        Text("$ADDYIO_Version")
                            .multilineTextAlignment(.center)
                            .font(.system(size: 16))
                            .frame(maxWidth: .infinity)
                            .padding(.bottom,10).padding(.top)
                        Text(String(localized: "addyio_android_stjin"))
                            .multilineTextAlignment(.center)
                            .font(.system(size: 16))
                            .frame(maxWidth: .infinity)
                            .padding(.bottom,1)
                        Text(String(localized: "crafted_with_love_and_privacy"))
                            .multilineTextAlignment(.center)
                            .font(.system(size: 14))
                            .frame(maxWidth: .infinity)
                    }
                }
                
                
            }.navigationTitle(String(localized: "addyio_account")).listSectionSpacing(.compact)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(content: {
                    ToolbarItem() {
                        Button {
                            dismiss()
                        } label: {
                            Label(String(localized: "dismiss"), systemImage: "xmark.circle.fill")
                        }
                        
                    }
                })
        }
    
}

#Preview {
    ProfileBottomSheet() {
        // Dummy function for preview
    }
}
