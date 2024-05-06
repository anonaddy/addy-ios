//
//  ContentView.swift
//  addy
//
//  Created by Stijn van de Water on 06/05/2024.
//

import SwiftUI
import SwiftData
import Lottie

struct SplashView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    var body: some View {
        Color.accentColor
            .ignoresSafeArea(.container) // Ignore just for the color
                .overlay(
                    VStack(spacing: 20) {
                        LottieView(animation: .named("ic_loading_logo.shapeshifter"))
                            .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                            .animationSpeed(Double(2))
                            .frame(maxHeight: 128)
                            .opacity(0.5)

                })

        
    }
    
    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}



#Preview {
    SplashView()
        .modelContainer(for: Item.self, inMemory: true)
}
