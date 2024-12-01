//
//  GradientProgressBar.swift
//  addy
//
//  Created by Stijn van de Water on 15/07/2024.
//

import SwiftUI

struct GradientProgressBar: View {
    @Binding var value: Float // between 0 and 1

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle().frame(width: geometry.size.width, height: geometry.size.height)
                    .opacity(0.3)
                    .foregroundColor(Color(UIColor.white))

                Rectangle().frame(width: CGFloat(self.value) * geometry.size.width, height: geometry.size.height)
                    .foregroundColor(Color.clear)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [.accent.opacity(0.50), .primaryColorStatic]), startPoint: .leading, endPoint: .trailing)
                    )
                    .animation(.easeInOut(duration: 0.5), value: self.value) // Animate the width change
            }
        }.cornerRadius(10.0)
    }
}
struct ContentView: View {
    @State private var progress: Float = 0.5

    var body: some View {
        VStack {
            GradientProgressBar(value: $progress)
                .frame(height: 20)
                .padding(24)
            Slider(value: $progress)
                .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
