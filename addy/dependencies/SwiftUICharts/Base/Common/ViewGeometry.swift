import SwiftUI

public struct ViewGeometry<T: PreferenceKey>: View {
    public var body: some View {
        GeometryReader { geometry in
            Color.clear
                .preference(key: T.self, value: [ViewSizeData(size: geometry.size)] as! T.Value)
        }
    }
}
