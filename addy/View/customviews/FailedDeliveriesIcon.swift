//
//  FailedDeliveriesIcon.swift
//  addy
//
//  Created by Stijn van de Water on 19/06/2024.
//

import SwiftUI

struct FailedDeliveriesIcon: View {
    @EnvironmentObject var mainViewState: MainViewState
    @Binding var horizontalSize: UserInterfaceSizeClass
    
    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
        if horizontalSize == .compact {
        Button {
            withAnimation {
                mainViewState.newFailedDeliveries = 0
            }
            
            if horizontalSize == .compact {
                mainViewState.isPresentingFailedDeliveriesSheet = true
            } else {
                mainViewState.selectedTab = .failedDeliveries
            }
        } label: {
            Image(systemName: "exclamationmark.triangle.fill")
        }.overlay(HStack(alignment: .top) {
            if mainViewState.newFailedDeliveries ?? 0 > 0 {
                Image(systemName: String(mainViewState.newFailedDeliveries ?? 0)).foregroundColor(.red)
                    .frame(maxWidth: .infinity)
            }
        }
            .frame(maxHeight: .infinity)
            .symbolVariant(.fill)
            .symbolVariant(.circle)
            .allowsHitTesting(false)
            .offset(x: 10, y: -10)
        )
    }
    }
}
