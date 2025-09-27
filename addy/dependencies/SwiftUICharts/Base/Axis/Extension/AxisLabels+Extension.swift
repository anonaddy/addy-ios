import SwiftUI

public extension AxisLabels {
    func setAxisYLabels(_ labels: [String],
                        position: AxisLabelsYPosition = .leading) -> AxisLabels
    {
        axisLabelsData.axisYLabels = labels
        axisLabelsStyle.axisLabelsYPosition = position
        return self
    }

    func setAxisXLabels(_ labels: [String]) -> AxisLabels {
        axisLabelsData.axisXLabels = labels
        return self
    }

    func setAxisYLabels(_ labels: [(Double, String)],
                        range: ClosedRange<Int>,
                        position: AxisLabelsYPosition = .leading) -> AxisLabels
    {
        let overreach = range.overreach + 1
        var labelArray = [String](repeating: "", count: overreach)
        for label in labels {
            let index = Int(label.0) - range.lowerBound
            if labelArray[safe: index] != nil {
                labelArray[index] = label.1
            }
        }

        axisLabelsData.axisYLabels = labelArray
        axisLabelsStyle.axisLabelsYPosition = position

        return self
    }

    func setAxisXLabels(_ labels: [(Double, String)], range: ClosedRange<Int>) -> AxisLabels {
        let overreach = range.overreach + 1
        var labelArray = [String](repeating: "", count: overreach)
        for label in labels {
            let index = Int(label.0) - range.lowerBound
            if labelArray[safe: index] != nil {
                labelArray[index] = label.1
            }
        }

        axisLabelsData.axisXLabels = labelArray
        return self
    }

    func setColor(_ color: Color) -> AxisLabels {
        axisLabelsStyle.axisFontColor = color
        return self
    }

    func setFont(_ font: Font) -> AxisLabels {
        axisLabelsStyle.axisFont = font
        return self
    }
}
