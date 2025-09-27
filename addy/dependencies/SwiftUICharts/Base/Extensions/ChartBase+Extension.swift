import SwiftUI

public extension ChartBase {
    func data(_ data: [Double]) -> some ChartBase {
        chartData.data = data.enumerated().map { index, value in (Double(index), value) }
        return self
    }

    func data(_ data: [(Double, Double)]) -> some ChartBase {
        chartData.data = data
        return self
    }

    func rangeY(_ range: ClosedRange<FloatLiteralType>) -> some ChartBase {
        chartData.rangeY = range
        return self
    }

    func rangeX(_ range: ClosedRange<FloatLiteralType>) -> some ChartBase {
        chartData.rangeX = range
        return self
    }
}
