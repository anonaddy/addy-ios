//
//  ChipView.swift
//  addy
//
//  Created by Stijn van de Water on 24/06/2026.
//

import addy_shared
import SwiftUI

struct ChipView: View {
    let label: String
    let isSelected: Bool
    let color: Color
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: {
            HapticHelper.playHapticFeedback(hapticType: .tap)
            action?()
        }, label: {
            HStack(spacing: 4) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .transition(.opacity.combined(with: .scale))
                }
                
                Text(label)
                    .font(.body)
                    .lineLimit(1)
            }
            .fixedSize()
        })
        .apply { View in
            if #available(iOS 26.0, *) {
                if isSelected {
                    View.buttonStyle(.glassProminent).tint(color)
                } else {
                    View.buttonStyle(.glass)
                }
            } else {
                if isSelected {
                    View.buttonStyle(.borderedProminent).tint(color)
                } else {
                    View.buttonStyle(.bordered)
                }
            }
        }
        .animation(.spring(), value: isSelected)
    }

    init(label: String, isSelected: Bool, color: Color = .accentColor, action: (() -> Void)? = nil) {
        self.label = label
        self.isSelected = isSelected
        self.color = color
        self.action = action
    }
}

#Preview {
    @Previewable @State var isSelected = true
    @Previewable @State var isSelected2 = false

    HStack {
        ChipView(label: "Selected Label", isSelected: isSelected, color: .purple) {
            isSelected.toggle()
        }
        ChipView(label: "Unselected Label", isSelected: isSelected2, color: .blue) {
            isSelected2.toggle()
        }
    }
    .padding()
}

