import Foundation

extension Array where Element == ColorGradient {
    /// <#Description#>
    /// - Parameter index: offset in data table
    /// - Returns: <#description#>
    func rotate(for index: Int) -> ColorGradient {
        if isEmpty {
            return ColorGradient.orangeBright
        }

        if count <= index {
            return self[index % count]
        }

        return self[index]
    }
}

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
