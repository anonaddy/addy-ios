import SwiftUI

struct AddyLoadingButton<Content: View>: View {
    @Binding var isLoading: Bool

    var style: AddyLoadingButtonStyle
    let content: Content
    var action: () -> () = {}
    
    init(action: @escaping () -> Void, isLoading: Binding<Bool>, style: AddyLoadingButtonStyle? = nil, @ViewBuilder builder: () -> Content) {
        
        let defaultStyle = AddyLoadingButtonStyle(width: .infinity,
                                      height: 56,
                                      cornerRadius: 12,
                                      strokeWidth: 5,
                                      strokeColor: .gray)
        
        self._isLoading = isLoading
        self.style = style ?? defaultStyle
        content = builder()
        self.action = action
    }
    
    public var body: some View {

        Button(action: {
            if !isLoading {
                action()
            }
            isLoading = true
        }) {
            ZStack {
                Capsule()
                    .fill(.opacity(0))
                    .frame(maxWidth: isLoading ? style.height : style.width, minHeight: style.height, maxHeight: style.height)
                if isLoading {
                    ProgressView()
                }
                else {
                    VStack { content }
                }
            }
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
        .disabled(isLoading)
        .animation(.easeInOut, value: isLoading)
    }
}

