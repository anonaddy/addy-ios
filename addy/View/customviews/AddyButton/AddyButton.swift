import SwiftUI

@available(iOS, deprecated: 26.0, message: "This View is deprecated on iOS 26 and later. Use Button instead.")
struct AddyButton<Content: View>: View{
    
    var style: AddyButtonStyle
    let content: Content
    var action: () -> () = {}
    
    init(action: @escaping () -> Void, style: AddyButtonStyle? = nil, @ViewBuilder builder: () -> Content) {
        
        let defaultStyle = AddyButtonStyle(width: .infinity,
                                           height: 56,
                                           cornerRadius: 12,
                                           buttonStyle: .primary,
                                           strokeWidth: 5,
                                           strokeColor: .gray)
        
        self.style = style ?? defaultStyle
        content = builder()
        self.action = action
    }
    
    public var body: some View {
        Button(action: {
            action()
        }) {
            VStack { content }.frame(maxWidth: style.width, minHeight: style.height, maxHeight: style.height)
        }
        .apply({ View in
            if #available(iOS 26.0, *) {
                switch style.buttonStyle {
                    case .primary:
                        View.buttonStyle(.glassProminent)
                    case .secondary:
                        View.buttonStyle(.glass)
                    case .destruction:
                        View.buttonStyle(.glassProminent)
                    }
            } else {
                switch style.buttonStyle {
                    case .primary:
                        View.buttonStyle(.borderedProminent).clipShape(.capsule)
                    case .secondary:
                        View.buttonStyle(.bordered).clipShape(.capsule)
                    case .destruction:
                        View.buttonStyle(.borderedProminent).clipShape(.capsule)
                    }
            }
        })
        .frame(maxWidth: style.width, maxHeight: style.height)
        .padding()
    }
}

