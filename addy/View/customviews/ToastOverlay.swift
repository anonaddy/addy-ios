//
//  ToastOverlay.swift
//  addy_shared
//
//  Created by Stijn van de Water on 08/07/2024.
//

import SwiftUI

struct ToastOverlay: View {
    @Binding private var showToast: Bool

    private var text: String

    var body: some View {
        if showToast {
            Text(text)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)
                .padding()
                .background(Color.accentColor.cornerRadius(20))
                .padding(.bottom)
                .shadow(radius: 5)
                .transition(.move(edge: .bottom))
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }

    init(showToast: Binding<Bool>, text: String) {
        _showToast = showToast
        self.text = text
    }
}

#Preview {
    ToastOverlay(showToast: .constant(true), text: String(localized: "copied_to_clipboard"))
}
