//
//  PlayGround.swift
//  addy
//
//  Created by Stijn van de Water on 24/07/2024.
//

import SwiftUI

struct PlayGround: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                Color.clear
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        BarChart()
                            .data([142,56,43,23])
                            .chartStyle(ChartStyle(backgroundColor: .white,
                                                   foregroundColor: [ColorGradient(.portalOrange, .portalOrange.opacity(0.7)),
                                                                     ColorGradient(.easternBlue, .easternBlue.opacity(0.7)),
                                                                     ColorGradient(.portalBlue, .portalBlue.opacity(0.7)),
                                                                     ColorGradient(.softRed, .softRed.opacity(0.7))]))
                            .allowsHitTesting(false)
                            .padding(.horizontal).padding(.top)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 13))
                    .frame(maxWidth: 1000)
            }
        }
    }
}

#Preview {
    PlayGround()
}
