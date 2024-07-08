//
//  CopiedToClipboardOverlay.swift
//  addy_shared
//
//  Created by Stijn van de Water on 08/07/2024.
//

import SwiftUI

public struct CopiedToClipboardOverlay: View {
    @Binding private var copiedToClipboard: Bool
    
    public init(copiedToClipboard: Binding<Bool>) {
            self._copiedToClipboard = copiedToClipboard
        }
    
    public var body: some View {
        if copiedToClipboard {
            Text(String(localized: "copied_to_clipboard"))
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
    
}

#Preview {
    CopiedToClipboardOverlay(copiedToClipboard: .constant(true))
}
