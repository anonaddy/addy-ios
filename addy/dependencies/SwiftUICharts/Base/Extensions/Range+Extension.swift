import Foundation

public extension ClosedRange where Bound: AdditiveArithmetic {
    var overreach: Bound {
        upperBound - lowerBound
    }
}
