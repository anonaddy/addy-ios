import SwiftUI

struct AddyButton<Content: View>: View {
    var style: AddyButtonStyle
    let content: Content
    var action: () -> Void = {}

    init(action: @escaping () -> Void, style: AddyButtonStyle? = nil, @ViewBuilder builder: () -> Content) {
        let defaultStyle = AddyButtonStyle(width: .infinity,
                                           height: 56,
                                           buttonStyle: .primary)

        self.style = style ?? defaultStyle
        content = builder()
        self.action = action
    }

    var body: some View {
        Button(action: {
            action()
        }) {
            VStack { content }.frame(maxWidth: style.width, minHeight: style.height, maxHeight: style.height)
        }
        .apply { View in
            if #available(iOS 26.0, *) {
                switch style.buttonStyle {
                case .primary:
                    View.buttonStyle(.glassProminent)
                case .secondary:
                    View.buttonStyle(.glass(.clear))
                case .destructive:
                    View.buttonStyle(.glassProminent).tint(.red)
                }
            } else {
                switch style.buttonStyle {
                case .primary:
                    View.buttonStyle(.borderedProminent).clipShape(.capsule)
                case .secondary:
                    View.buttonStyle(.bordered).clipShape(.capsule)
                case .destructive:
                    View.buttonStyle(.borderedProminent).clipShape(.capsule).tint(.red)
                }
            }
        }
        .frame(maxWidth: style.width, maxHeight: style.height)
        .padding()
    }
}
