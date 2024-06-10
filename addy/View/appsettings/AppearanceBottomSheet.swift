//
//  AppearanceBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 10/06/2024.
//

import SwiftUI
import WrappingHStack

struct AppearanceBottomSheet: View {
    
    
    @Environment(\.dismiss) var dismiss

    var body: some View {
        List {
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
        }.navigationTitle(String(localized: "appearance")).pickerStyle(.navigationLink)
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
    AppearanceBottomSheet()
}
