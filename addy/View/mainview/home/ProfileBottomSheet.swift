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
    @Binding var isPresentingProfileBottomSheet: Bool
    @EnvironmentObject var mainViewState: MainViewState
    
    let onNavigate: (Destination) -> Void

    init(onNavigate: @escaping (Destination) -> Void, isPresentingProfileBottomSheet: Binding<Bool>) {
        self.onNavigate = onNavigate
        self._isPresentingProfileBottomSheet = isPresentingProfileBottomSheet
    }

    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL

    var body: some View {

            List {
                
                Section{
                    VStack{
                        ZStack(alignment: .center) {
                            Circle()
                                .fill(LinearGradient(gradient: Gradient(colors: [Color.secondary.opacity(0.6), Color.secondary]), startPoint: .top, endPoint: .bottom))
                                .frame(width: 100, height: 100)
                            Text(mainViewState.userResource!.username.prefix(2).uppercased())
                                .font(.system(size: 40))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }.frame(maxWidth: .infinity).padding(.bottom,10)
                        
                        Text(mainViewState.userResource!.username)
                            .font(.headline)
                        
                        if (mainViewState.userResource!.subscription != nil){
                            Text(String(format: String(localized: "subscription_user"), mainViewState.userResource!.subscription!))
                                .font(.subheadline)
                                .opacity(0.6)
                            
                            if (mainViewState.userResource!.subscription_ends_at != nil) {
                                Text(getSubscriptionUntilText())
                                    .font(.subheadline)
                                    .fontWeight(.thin)
                                    .opacity(0.6)
                            }
                        }

                        
                        AddyButton(action: {
                            openURL(URL(string: "\(AddyIo.API_BASE_URL)/settings")!)

                        }, style: AddyButtonStyle(backgroundColor: Color(.accent).opacity(0.5))) {
                            Text(String(localized: "addyio_settings")).foregroundColor(Color.white)
                        }.padding(.top)
                    }
                }.listRowBackground(Color.clear)
                
                Section{
                    
                    AddySection(title: String(localized: "manage_domains"), description: String(localized: "manage_domains_desc"), trailingSystemimage: "chevron.right") {
                        self.onNavigate(Destination.domains)
                    }

                    AddySection(title: String(localized: "manage_rules"), description: String(localized: "manage_rules_desc"), trailingSystemimage: "chevron.right") {
                        self.onNavigate(Destination.usernames)
                    }

                    AddySection(title: String(localized: "manage_usernames"), description: String(localized: "manage_usernames_desc"), trailingSystemimage: "chevron.right") {
                        self.onNavigate(Destination.usernames)
                    }
                    
                    AddySection(title: String(localized: "app_settings"), description: String(localized: "manage_domains_desc"), trailingSystemimage: "chevron.right") {
                        self.onNavigate(Destination.usernames)
                    }

                    
                } footer: {
                    VStack {
                        
                        
                        Spacer()
                        Text(getAddyIoVersion())
                            .multilineTextAlignment(.center)
                            .font(.system(size: 16))
                            .frame(maxWidth: .infinity)
                            .padding(.bottom,5).padding(.top,5)
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
    
    private func getAddyIoVersion() ->String {
        if (AddyIo.VERSIONMAJOR == 9999) {
            return String(localized: "hosted_instance")
        } else {
            return String(format: String(localized: "self_hosted_instance_s"), AddyIo.VERSIONSTRING)
        }
    }
    
    
    private func getSubscriptionUntilText() ->String {
            return String(format: String(localized: "subscription_user_until"), DateTimeUtils.turnStringIntoLocalString(
                mainViewState.userResource!.subscription_ends_at,
                dateTimeFormat: DateTimeUtils.DateTimeFormat.date)
                          )
    
    }
}

//#Preview {
//    ProfileBottomSheet() {
//        // Dummy function for preview
//    }
//}
