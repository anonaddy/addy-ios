import SwiftUI

public extension ChartGrid {
    func setNumberOfHorizontalLines(_ numberOfLines: Int) -> ChartGrid {
        gridOptions.numberOfHorizontalLines = numberOfLines
        return self
    }

    func setNumberOfVerticalLines(_ numberOfLines: Int) -> ChartGrid {
        gridOptions.numberOfVerticalLines = numberOfLines
        return self
    }

    func setStoreStyle(_ strokeStyle: StrokeStyle) -> ChartGrid {
        gridOptions.strokeStyle = strokeStyle
        return self
    }

    func setColor(_ color: Color) -> ChartGrid {
        gridOptions.color = color
        return self
    }

    func showBaseLine(_ show: Bool, with style: StrokeStyle? = nil) -> ChartGrid {
        gridOptions.showBaseLine = show
        if let style = style {
            gridOptions.baseStrokeStyle = style
        }
        return self
    }
}
