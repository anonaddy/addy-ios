import SwiftUI

/// A Fully Configuarable Button Style
struct AddyButtonStyle {
    
    enum ButtonStyle {
        case primary
        case secondary
        case destructive
    }
    
    init(width: CGFloat? = nil,
                height: CGFloat? = nil,
                buttonStyle: ButtonStyle? = nil) {
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
