//
//  PlayGround.swift
//  addy
//
//  Created by Stijn van de Water on 24/07/2024.
//

import SwiftUI

struct PlayGround: View {
    @State var isPlayingAnimation = false
    var body: some View {
        
        if isPlayingAnimation{
            animationViewFlavor1
        }
        
        if !isPlayingAnimation{
            Button("start animation", role: .none, action: {
                isPlayingAnimation = true
            })
        }
        
    }
    
    
    
    
    
    @State private var animationTitleText1 = ""
    @State private var animationTitleTextArray1 = [
        "TH.E0.ADDY",
        "IO.AP.P0FO",
        "R0.IO.S0IS",
        "0F.IN.ALLY",
        "0H.ER.E0AN",
        "D0.IT.0IS0",
        "AW.ES.OME0",
        "CO.MI.NG0T",
        "O0.YO.UR0I",
        "PH.ON.E0NE",
        "XT.0W.EEK0",
        "05.10.2024"]
    
    @State private var animationTitleTextArray2 = [
        "TH.E0.ADDY",
        "TH.E0.ADDY",
        "IO.AP.P0FO",
        "R0.IO.S0IS",
        "0F.IN.ALLY",
        "0H.ER.E0AN",
        "D0.IT.0IS0",
        "AW.ES.OME0",
        "CO.MI.NG0T",
        "O0.YO.UR0I",
        "PH.ON.E0NE",
        "XT.0M.ONTH",
        "05.10.2024"]
    
    @State private var animationTitleTextArray3 = [
        "TH.E0.ADDY",
        "TH.E0.ADDY",
        "TH.E0.ADDY",
        "IO.AP.P0FO",
        "R0.IO.S0IS",
        "0F.IN.ALLY",
        "0H.ER.E0AN",
        "D0.IT.0IS0",
        "AW.ES.OME0",
        "CO.MI.NG0T",
        "O0.YO.UR0I",
        "PH.ON.E0NE",
        "XT.0M.ONTH",
        "05.10.2024"]
    @State private var animationTitleText1Bold = false
    @State private var animationTitleText1Size = 36
    @State private var isBlurred = false
    @State private var isFaded = false
    @State private var isMonoSpaced = false
    var animationViewFlavor1: some View {
        
        Group {
            
            Text(animationTitleText1)
                .font(.system(size: CGFloat(animationTitleText1Size)))
                .monospaced(isMonoSpaced)
                .fontDesign(.rounded)
                .bold(animationTitleText1Bold)
                .contentTransition(.numericText(countsDown: false))
                .animation(.default, value: 5)
                .blur(radius: isBlurred ? 10 : 0)
                .opacity(isFaded ? 0 : 1)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation {
                            animationTitleText1 = "It's almost time"
                        }
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation {
                            isBlurred.toggle()
                            isFaded.toggle()
                        }
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation {
                            animationTitleText1Bold = true
                            animationTitleText1Size = 96
                            animationTitleText1 = animationTitleTextArray1.first!
                        }
                    }
                    
                    
                    var textArrayDelayTime = 3.3

                    for text in animationTitleTextArray1 {
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + textArrayDelayTime) {
                            withAnimation(.default.speed(0.65)) {
                                
                                isBlurred = false
                                isFaded = false
                                
                                animationTitleText1 = text
                                
                            }
                        }
                        

                        textArrayDelayTime += 0.35
                    }
                    
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 9.0) {
                        withAnimation(.default.speed(0.65)) {
                            isMonoSpaced = false
                            animationTitleText1 = "ready?"
                        }
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 11.0) {
                        withAnimation(.default.speed(0.65)) {
                            animationTitleText1 = "05.10.2024"
                        }
                    }
                }
            
 

            
            
        }
        
        
    }
    
    
    @State private var animationTitleText2 = ""
    @State private var animationTitleText3 = ""
    @State private var animationTitleText4 = ""
    @State private var blurRadius = 0
    var animationViewFlavor2: some View {
        
        Group {
            
            ZStack {
                
                Text(animationTitleText1)
                    .font(.system(size: CGFloat(animationTitleText1Size)))
                    .fontDesign(.rounded)
                    .bold(animationTitleText1Bold)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.default, value: 5)
                
                Group {
                    Text(animationTitleText2)
                        .font(.system(size: CGFloat(animationTitleText1Size)))
                        .fontDesign(.rounded)
                        .bold(animationTitleText1Bold)
                        .contentTransition(.numericText(countsDown: false))
                        .animation(.default, value: 5)
                    
                    Text(animationTitleText3)
                        .font(.system(size: CGFloat(animationTitleText1Size)))
                        .fontDesign(.rounded)
                        .bold(animationTitleText1Bold)
                        .contentTransition(.numericText(countsDown: false))
                        .animation(.default, value: 5)
                    
                    Text(animationTitleText4)
                        .font(.system(size: CGFloat(animationTitleText1Size)))
                        .fontDesign(.rounded)
                        .bold(animationTitleText1Bold)
                        .contentTransition(.numericText(countsDown: false))
                        .animation(.default, value: 5)
                }.blur(radius: CGFloat(blurRadius))
            }.onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation {
                        animationTitleText1 = "It's almost time"
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                    withAnimation {
                        blurRadius = 10
                        animationTitleText1Bold = true
                        animationTitleText1Size = 96
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    animationTitleText1 = ""
                    
                    let group = DispatchGroup()
                    
                    var textArrayDelayTime1: Double = 0
                    var textArrayDelayTime2: Double = 0
                    var textArrayDelayTime3: Double = 0
                    
                    for text in animationTitleTextArray1 {
                        group.enter()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 + textArrayDelayTime1) {
                            withAnimation(.default.speed(1.0)) {
                                animationTitleText2 = text
                            }
                            group.leave()
                        }
                        textArrayDelayTime1 += 0.3
                    }
                    
                    for text in animationTitleTextArray2 {
                        group.enter()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 + textArrayDelayTime2) {
                            withAnimation(.default.speed(1.0)) {
                                animationTitleText3 = text
                            }
                            group.leave()
                        }
                        textArrayDelayTime2 += 0.3
                    }
                    
                    for text in animationTitleTextArray3 {
                        group.enter()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + textArrayDelayTime3) {
                            withAnimation(.default.speed(1.0)) {
                                animationTitleText4 = text
                            }
                            group.leave()
                        }
                        textArrayDelayTime3 += 0.3
                    }
                    
                    group.notify(queue: .main) {
                        withAnimation {
                            blurRadius = 0
                        }
                        print("All animations are done!")
                    }
                }
            }
            
        }
        
        
    }
}

#Preview {
    PlayGround()
}
