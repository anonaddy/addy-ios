
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
            } footer: {
                VStack (alignment: .leading, spacing: 24){
                    Text(DateTimeUtils.convertStringToLocalTimeZoneString(accountNotification.created_at))
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .italic()
                        .padding(.bottom, 4)
#if APPSTORELESS
                    if accountNotification.link != nil {
                        AddyButton(action: {
                            openURL(URL(string: accountNotification.link!)!)
                            dismiss()
                        }) {
                            Text(accountNotification.link_text ?? String(localized: "open_link")).foregroundColor(Color.white)
                        }
                    }
                    #endif
                }
            }

            
        }.navigationTitle(accountNotification.title).pickerStyle(.navigationLink)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Label(String(localized: "dismiss"), systemImage: "xmark")
                    }
                    
                }
            })
        
        
    }
    
}
