//
//  AddyToggle.swift
//  addy
//
//  Created by Stijn van de Water on 12/05/2024.
//

import addy_shared
import SwiftUI

struct AddyToggle: View {
    @Environment(\.isEnabled) private var isEnabled
    @Binding var isOn: Bool
    @State var lineLimit: Int? = 3

    var isLoading: Bool = false
    var title: String
    var description: String? = nil
    var leadingSystemimage: String? = nil
    var leadingSystemimageColor: Color = .blue
    var fontWeight: Font.Weight = .medium
    var onTap: (() -> Void)? = nil

    var body: some View {
        HStack {
            if let leadingSystemimage = leadingSystemimage {
                RoundedRectangle(cornerRadius: 6)
                    .fill(leadingSystemimageColor)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: leadingSystemimage)
                            .fontWeight(fontWeight)
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    )
                    .padding(.trailing)
            }

            VStack(alignment: .leading) {
                Text(title)
                    .foregroundColor(Color.primary)

                if let description = description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(lineLimit)
                }

            }.frame(maxWidth: .infinity, alignment: .leading)

            if isLoading {
                Spacer(minLength: 15)

                ProgressView() // Loading indicator
                    .progressViewStyle(CircularProgressViewStyle())
            }

            Toggle(isOn: $isOn) {}.frame(width: 60) // This will give the Toggle an explicit width
        }
        .opacity(isEnabled ? 1.0 : 0.5)
        .allowsHitTesting(isEnabled)
        .onTapGesture {
            guard isEnabled else { return }
            if self.onTap != nil {
                self.onTap?()
            } else {
                HapticHelper.playHapticFeedback(hapticType: .tap)
                isOn = !isOn
            }
        }
        .onLongPressGesture(perform: {
            guard isEnabled else { return }
            HapticHelper.playHapticFeedback(hapticType: .tap)

            withAnimation {
                if self.lineLimit == nil {
                    self.lineLimit = 3

                } else {
                    self.lineLimit = nil
                }
            }

        })

        .tint(.accentColor)
    }
}

#Preview {
    @Previewable @State var biometricEnabled = false

    VStack {
        AddyToggle(isOn: $biometricEnabled, title: String(localized: "security"), description: "Preview description", leadingSystemimage: "faceid", leadingSystemimageColor: .green) {
            print("on tap section")
        }

        AddyToggle(isOn: $biometricEnabled, title: String(localized: "security"), description: String(localized: "security_desc"), leadingSystemimage: "faceid", leadingSystemimageColor: .green)
    }
}
