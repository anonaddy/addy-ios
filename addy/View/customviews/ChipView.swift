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
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isSelected ? color : Color(.systemGray5))
        .foregroundColor(isSelected ? .white : .primary)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isSelected ? Color(.systemGray5) : Color(.systemGray4), lineWidth: 1)
        )
        .animation(.spring(), value: isSelected)
    }
}
