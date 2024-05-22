//
//  HapticHelper.swift
//  addy
//
//  Created by Stijn van de Water on 22/05/2024.
//

import SwiftUI

public struct HapticHelper {
    
    public enum HapticType {
        case tap
        case error
    }
    
    public static func playHapticFeedback(hapticType: HapticType) {
        switch (hapticType){
        case HapticType.tap:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        case HapticType.error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}
