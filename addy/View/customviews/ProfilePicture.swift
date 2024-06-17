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
        Button {
            mainViewState.isPresentingProfileBottomSheet = true
        } label: {
            ZStack(alignment: .center) {
                Circle()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.secondary.opacity(0.6), Color.secondary]), startPoint: .top, endPoint: .bottom))
                    .frame(width: 24, height: 24)
                Text(MainViewState.shared.userResource!.username.prefix(2).uppercased())
                    .font(.system(size: 12))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
    }
}
