//
//  SwiftUIView.swift
//  
//
//  Created by 변경민 on 2020/12/02.
//

import SwiftUI

/// A Fully Configuarable Button Style
public struct AddyButtonStyle {
    public init(width: CGFloat? = nil,
                height: CGFloat? = nil,
                cornerRadius: CGFloat? = nil,
                backgroundColor: Color? = nil,
                strokeWidth: CGFloat? = nil,
                strokeColor: Color? = nil) {
        self.width = width ?? 312
        self.height = height ?? 54
        self.cornerRadius = cornerRadius ?? 0
        self.backgroundColor = backgroundColor ?? Color.blue
        self.strokeWidth = strokeWidth ?? 5
        self.strokeColor = strokeColor ?? Color.gray.opacity(0.6)
    }
    
    /// Width of button
    public var width: CGFloat = 312
    /// Height of button
    public var height: CGFloat = 54
    /// Corner radius of button
    public var cornerRadius: CGFloat = 0
    /// Background color of button
    public var backgroundColor: Color = .blue
    /// Width of circle loading bar stroke
    public var strokeWidth: CGFloat = 5
    /// Color of circle loading bar stroke
    public var strokeColor: Color = Color.gray.opacity(0.6)
}
