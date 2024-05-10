import SwiftUI

/// View containing data and some kind of chart content
public struct CardView<Content: View>: View, ChartBase {
    public var chartData = ChartData()
    let content: () -> Content

    private var showShadow: Bool
    private var cornerRadius: CGFloat

    @EnvironmentObject var style: ChartStyle

	/// Initialize with view options and a nested `ViewBuilder`
	/// - Parameters:
	///   - showShadow: should card have a rounded-rectangle shadow around it
    ///   - cornerRadius:  Cornerradius for the cards
	///   - content: content description
    public init(showShadow: Bool = true, cornerRadius: CGFloat = 16, @ViewBuilder content: @escaping () -> Content) {
        self.showShadow = showShadow
        self.cornerRadius = cornerRadius
        self.content = content
    }

	/// The content and behavior of the `CardView`.
	///
	///
    public var body: some View {
        ZStack{
            if showShadow {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.cardViewLightModeDarkMode)
                    .shadow(color: Color.black.opacity(0.2), radius: 4)
            }
            VStack (alignment: .leading) {
                self.content()
            }
            .clipShape(RoundedRectangle(cornerRadius: showShadow ? cornerRadius : 0))
        }
    }
}
