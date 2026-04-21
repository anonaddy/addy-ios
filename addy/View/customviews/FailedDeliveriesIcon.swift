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
            withAnimation {
                mainViewState.newFailedDeliveries = 0
            }
            if horizontalSize == .compact {
                mainViewState.isPresentingFailedDeliveriesSheet = true
            } else {
                mainViewState.selectedTab = .failedDeliveries
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "exclamationmark.triangle.fill")

                if let count = mainViewState.newFailedDeliveries, count > 0 {
                    Text("\(count)")
                        .font(.caption2).bold()
                        .foregroundColor(.white)
                        .frame(width: 15, height: 15)
                        .background(Circle().fill(Color.red))
                        .offset(x: 4, y: -4)
                }
            }
        }
    }
}
