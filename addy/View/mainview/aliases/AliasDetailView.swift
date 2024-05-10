//
//  AliasDetailView.swift
//  addy
//
//  Created by Stijn van de Water on 08/05/2024.
//

import SwiftUI
import addy_shared

struct AliasDetailView: View {
    
    var aliasId: String
    
    @State private var g1HappyMoods: Double = 3
    @State private var g1NeutralMoods: Double = 2
    @State private var g1SickMoods: Double = 2
    @State private var g1OverateMoods: Double = 2
    @State private var g1TotalDataPoints: Int = 9
    var demoData: [Double] = [8, 2, 4, 6, 12, 9, 2]

    
    var body: some View {
        BarChart()
            .data(demoData)
            .chartStyle(ChartStyle(backgroundColor: .white,
                                   foregroundColor: ColorGradient(.blue, .purple)))
        
    }
}


#Preview {
    // TODO: preview remove this demo
    AliasDetailView(aliasId: "fc2e09ef-9e3a-41a6-876b-6ed7c8e987c6")
}
