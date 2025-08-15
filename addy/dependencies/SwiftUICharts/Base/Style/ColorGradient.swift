import SwiftUI

public struct ColorGradient: Equatable {
    public let startColor: Color
    public let endColor: Color

    public init(_ color: Color) {
        startColor = color
        endColor = color
    }

    public init(_ startColor: Color, _ endColor: Color) {
        self.startColor = startColor
        self.endColor = endColor
    }

    public var gradient: Gradient {
        return Gradient(colors: [startColor, endColor])
    }
}

public extension ColorGradient {
    func linearGradient(from startPoint: UnitPoint, to endPoint: UnitPoint) -> LinearGradient {
        return LinearGradient(gradient: gradient, startPoint: startPoint, endPoint: endPoint)
    }
}

public extension ColorGradient {
    static let orangeBright = ColorGradient(ChartColors.orangeBright)
    static let redBlack = ColorGradient(.red, .black)
    static let greenRed = ColorGradient(.green, .red)
    static let whiteBlack = ColorGradient(.white, .black)
}
