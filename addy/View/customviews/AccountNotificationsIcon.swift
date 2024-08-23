//
//  AccountNotificationsIcon.swift
//  addy
//
//  Created by Stijn van de Water on 23/08/2024.
//


import SwiftUI
import addy_shared

struct AccountNotificationsIcon: View {
    @EnvironmentObject var mainViewState: MainViewState
    
    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
        if AddyIo.isUsingHostedInstance() {
            Button {
                withAnimation {
                    mainViewState.newAccountNotifications = 0
                }
                
                mainViewState.isPresentingAccountNotificationsSheet = true
            } label: {
                Image(systemName: mainViewState.newAccountNotifications > 0 ? "bell.badge.fill" : "bell.fill")
                    .contentTransition(.symbolEffect(.replace))
                    .apply {
                    if mainViewState.newAccountNotifications > 0 {
                        $0.foregroundColor(.red)
                    } else {
                        $0
                    }
                }
            }
        }
    }
}
