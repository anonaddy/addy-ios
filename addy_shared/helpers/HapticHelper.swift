//
//  HapticHelper.swift
//  addy
//
//  Created by Stijn van de Water on 22/05/2024.
//

import SwiftUI
#if os(iOS)
    import UIKit
#elseif os(watchOS)
    import WatchKit
#endif

public enum HapticHelper {
    public enum HapticType {
        case tap
        case error
    }

    public static func playHapticFeedback(hapticType: HapticType) {
        #if os(iOS)
            // iOS - UIKit haptics
            switch hapticType {
            case .tap:
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            case .error:
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        #elseif os(watchOS)
            // watchOS - WKInterfaceDevice haptics
            switch hapticType {
            case .tap:
                WKInterfaceDevice.current().play(.click)
            case .error:
                WKInterfaceDevice.current().play(.notification)
            }
        #endif
    }
}
