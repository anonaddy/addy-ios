//
//  ChipView.swift
//  addy
//
//  Created by Stijn van de Water on 24/06/2026.
//

import SwiftUI

struct ChipView: View {
    let label: String
    let isSelected: Bool
    let color: Color

    var body: some View {
        Text(label)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color : color.opacity(0.2))
            .foregroundColor(isSelected ? .white : color)
            .cornerRadius(16)
    }
}
