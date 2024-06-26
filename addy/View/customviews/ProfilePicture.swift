//
//  ProfilePicture.swift
//  addy
//
//  Created by Stijn van de Water on 17/06/2024.
//

import SwiftUI

struct ProfilePicture: View {
    @EnvironmentObject var mainViewState: MainViewState
        
    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
        Button {
            mainViewState.isPresentingProfileBottomSheet = true
        } label: {
            ZStack(alignment: .center) {
                if mainViewState.permissionsRequired {
                    Circle()
                        .fill(LinearGradient(gradient: Gradient(colors: [Color.red.opacity(0.6), Color.red]), startPoint: .top, endPoint: .bottom))
                        .frame(width: 24, height: 24)
                } else if mainViewState.updateAvailable {
                    Circle()
                        .fill(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.blue]), startPoint: .top, endPoint: .bottom))
                        .frame(width: 24, height: 24)
                } else {
                    Circle()
                        .fill(LinearGradient(gradient: Gradient(colors: [Color.secondary.opacity(0.6), Color.secondary]), startPoint: .top, endPoint: .bottom))
                        .frame(width: 24, height: 24)
                }
                Text(MainViewState.shared.userResource!.username.prefix(2).uppercased())
                    .font(.system(size: 12))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
    }
}
