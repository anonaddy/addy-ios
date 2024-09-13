import SwiftUI

/// A Fully Configuarable Button Style
struct AddyButtonStyle {
    
    enum ButtonStyle {
        case primary
        case secondary
    }
    
    init(width: CGFloat? = nil,
                height: CGFloat? = nil,
                cornerRadius: CGFloat? = nil,
                buttonStyle: ButtonStyle? = nil,
                backgroundColor: Color? = nil,
                strokeWidth: CGFloat? = nil,
                strokeColor: Color? = nil) {
        self.width = width ?? .infinity
        self.height = height ?? 56
        self.cornerRadius = cornerRadius ?? 12
        self.buttonStyle = buttonStyle ?? ButtonStyle.primary
        self.backgroundColor = backgroundColor ?? Color("AccentColor")
        self.strokeWidth = strokeWidth ?? 5
        self.strokeColor = strokeColor ?? Color.gray.opacity(0.6)
    }
    
    
    /// Width of button
    var width: CGFloat = 312
    /// Height of button
    var height: CGFloat = 54
    /// Corner radius of button
    var cornerRadius: CGFloat = 0
    /// Button Style
    var buttonStyle: ButtonStyle = .primary
    /// Background color of button
    var backgroundColor: Color = .blue
    /// Width of circle loading bar stroke
    var strokeWidth: CGFloat = 5
    /// Color of circle loading bar stroke
    var strokeColor: Color = Color.gray.opacity(0.6)
}
