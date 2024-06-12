//
//  BackgroundServiceIntervalBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 12/06/2024.
//

import SwiftUI
import addy_shared

struct BackgroundServiceIntervalBottomSheet: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var backgroundServiceInterval: Int = 30
    
    var body: some View {
        List {
            Section {
                
                Picker(selection: $backgroundServiceInterval, label: Text(String(localized:"background_service_interval"))) {
                    Text(String(localized: "15m")).tag(15)
                    Text(String(localized: "30m")).tag(30)
                    Text(String(localized: "1h")).tag(60)
                    Text(String(localized: "2h")).tag(120)
                }
                .pickerStyle(SegmentedPickerStyle())
                .onAppear {
                    let test = SettingsManager(encrypted: false).getSettingsInt(key: .backgroundServiceInterval, default: 30)
                    backgroundServiceInterval = SettingsManager(encrypted: false).getSettingsInt(key: .backgroundServiceInterval, default: 30)
                }
                .onChange(of: backgroundServiceInterval) { SettingsManager(encrypted: false).putSettingsInt(key: .backgroundServiceInterval, int: backgroundServiceInterval) }
                
                
            } header: {
                VStack(){
                    Text(String(localized: "background_service_desc"))
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                    
                }.textCase(nil).frame(maxWidth: .infinity, alignment: .center)
            }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())
        }.navigationTitle(String(localized: "background_service_interval")).pickerStyle(.navigationLink)
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
    BackgroundServiceIntervalBottomSheet()
}
