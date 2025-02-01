//
//  UIUXInterfaceBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 10/06/2024.
//

import SwiftUI
import WrappingHStack
import addy_shared

struct UIUXInterfaceBottomSheet: View {
    
    @Environment(\.dismiss) var dismiss
    @State private var startupPage: String = "home"
    @Binding var horizontalSize: UserInterfaceSizeClass
    

    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
        List {
            Section {
                let destinations = horizontalSize == .regular ? Destination.otherCases : Destination.iPhoneCases

                Picker(selection: $startupPage, label: Text(String(localized: "select_startup_page"))) {
                    ForEach(destinations, id: \.self) { destination in
                        Text(destination.title).tag(destination.value)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: startupPage) { _, _ in
                    SettingsManager(encrypted: false).putSettingsString(key: .startupPage, string: startupPage)
                }
                .onAppear {
                    let startupPage = SettingsManager(encrypted: false).getSettingsString(key: .startupPage) ?? "home"

                    // Check if the value exists in the array, reset to home if not (this could occur if eg. a tablet backup (which has more options) gets restored on mobile)
                    if destinations.contains(where: { $0.value == startupPage }){
                        self.startupPage = startupPage
                    } else {
                        SettingsManager(encrypted: false).putSettingsString(key: .startupPage, string: "home")
                        self.startupPage = "home"
                    }
                }
            } header: {
                Text(String(localized: "startup_page"))
            }
            
            Section {
                WrappingHStack(alignment: .leading) {
                    
                                    Button(action: {
                                        UIApplication.shared.setAlternateIconName(nil)
                                    }) {
                                        Image("AppIconPreview")
                                            .resizable()
                                            .frame(width: 75, height: 75)
                                            .clipShape(RoundedRectangle(cornerRadius: 15.0))
                                    }.buttonStyle(PlainButtonStyle())
                                Button(action: {
                                    UIApplication.shared.setAlternateIconName("AppIconClassic")
                                }) {
                                    Image("AppIconClassicPreview")
                                        .resizable()
                                        .frame(width: 75, height: 75)
                                        .clipShape(RoundedRectangle(cornerRadius: 15.0))

                                }.buttonStyle(PlainButtonStyle())
                                Button(action: {
                                    UIApplication.shared.setAlternateIconName("AppIconGradient")
                                }) {
                                    Image("AppIconGradientPreview")
                                        .resizable()
                                        .frame(width: 75, height: 75)
                                        .clipShape(RoundedRectangle(cornerRadius: 15.0))

                                }.buttonStyle(PlainButtonStyle())
                                Button(action: {
                                    UIApplication.shared.setAlternateIconName("AppIconInverseGradient")
                                }) {
                                    Image("AppIconInverseGradientPreview")
                                        .resizable()
                                        .frame(width: 75, height: 75)
                                        .clipShape(RoundedRectangle(cornerRadius: 15.0))

                                }.buttonStyle(PlainButtonStyle())
                            }
            } header: {
                Text(String(localized: "app_icon"))
            }
        }.navigationTitle(String(localized: "interface")).pickerStyle(.navigationLink)
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

struct UIUXInterfaceBottomSheet_Previews: PreviewProvider {
    
    static var previews: some View {
        @State var userInterfaceSizeClass: UserInterfaceSizeClass =  UserInterfaceSizeClass.regular
        UIUXInterfaceBottomSheet(horizontalSize: $userInterfaceSizeClass)
            .environmentObject(MainViewState.shared)
        
    }
}
