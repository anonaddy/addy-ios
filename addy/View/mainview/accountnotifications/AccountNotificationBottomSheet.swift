
//
//  AccountNotificationBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 23/08/2024.
//

import SwiftUI
import AVFoundation
import addy_shared

struct AccountNotificationBottomSheet: View {
    @State var accountNotification: AccountNotifications

    init(accountNotification: AccountNotifications) {
        self.accountNotification = accountNotification
    }

    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL

    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
        Form{

            Section {

                let formattedString = String.localizedStringWithFormat(accountNotification.textAsMarkdown())
                Text(LocalizedStringKey(formattedString))
                    .multilineTextAlignment(.leading)
            }
            
            Section {
                AddyButton(action: {
                    openURL(URL(string: accountNotification.link)!)
                    dismiss()
                }) {
                    Text(accountNotification.link_text).foregroundColor(Color.white)
                }.frame(minHeight: 56)
            }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())
            
        }.navigationTitle(accountNotification.title).pickerStyle(.navigationLink)
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
