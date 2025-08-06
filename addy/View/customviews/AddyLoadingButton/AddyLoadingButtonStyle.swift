//
//  SwiftUIView.swift
//  
//
//  Created by 변경민 on 2020/12/02.
//

import SwiftUI

/// A Fully Configuarable Button Style
struct AddyLoadingButtonStyle {
    
    enum ButtonStyle {
        case primary
        case secondary
    }
    
    init(width: CGFloat? = nil,
                height: CGFloat? = nil,
                buttonStyle: ButtonStyle? = nil,) {
        self.width = width ?? .infinity
        self.height = height ?? 56
        self.buttonStyle = buttonStyle ?? ButtonStyle.primary

    }
    
    /// Width of button
    var width: CGFloat = 312
    /// Height of button
    var height: CGFloat = 54
    /// Button Style
    var buttonStyle: ButtonStyle = .primary
}
