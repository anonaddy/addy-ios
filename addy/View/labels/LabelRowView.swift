//
//  LabelRowView.swift
//  addy
//
//  Created by Stijn van de Water on 24/06/2026.
//

import addy_shared
import SwiftUI

struct LabelRowView: View {
    let label: Labels

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Circle()
                .fill(Color(hex: label.colour))
                .frame(width: 30, height: 30)
            VStack(alignment: .leading, spacing: 4) {
                Text(label.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text("\(label.aliases_count ?? 0) aliases")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
