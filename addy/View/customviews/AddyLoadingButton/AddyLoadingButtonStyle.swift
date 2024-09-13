//
//  SwiftUIView.swift
//  
//
//  Created by 변경민 on 2020/12/02.
//

import SwiftUI

/// A Fully Configuarable Button Style
struct AddyLoadingButtonStyle {
    init(width: CGFloat? = nil,
                height: CGFloat? = nil,
                cornerRadius: CGFloat? = nil,
                backgroundColor: Color? = nil,
                loadingColor: Color? = nil,
                strokeWidth: CGFloat? = nil,
                strokeColor: Color? = nil) {        
        self.width = width ?? .infinity
        self.height = height ?? 56
        self.cornerRadius = cornerRadius ?? 12
        self.backgroundColor = backgroundColor ?? Color("AccentColor")
        self.strokeWidth = strokeWidth ?? 5
        self.strokeColor = strokeColor ?? Color.gray.opacity(0.6)
        self.loadingBackgroundColor = loadingColor ?? self.backgroundColor.opacity(0.6)

    }
    
    /// Width of button
    var width: CGFloat = 312
    /// Height of button
    var height: CGFloat = 54
    /// Corner radius of button
    var cornerRadius: CGFloat = 0
    /// Background color of button
    var backgroundColor: Color = .blue
    /// Background color of button when loading. 50% opacity of background color gonna be set if blank.
    var loadingBackgroundColor: Color = Color.blue.opacity(0.5)
    /// Width of circle loading bar stroke
    var strokeWidth: CGFloat = 5
    /// Color of circle loading bar stroke
    var strokeColor: Color = Color.gray.opacity(0.6)
}
