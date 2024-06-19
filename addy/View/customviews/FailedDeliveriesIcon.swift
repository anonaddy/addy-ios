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
        Button {
            if horizontalSize == .compact {
                mainViewState.isPresentingFailedDeliveriesSheet = true
            } else {
                mainViewState.selectedTab = .failedDeliveries
            }
        } label: {
            Image(systemName: "exclamationmark.triangle.fill")
        }
    }
}
