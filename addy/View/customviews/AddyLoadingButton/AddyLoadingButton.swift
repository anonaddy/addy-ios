import SwiftUI

struct AddyLoadingButton<Content: View>: View{
    @Binding var isLoading: Bool

    var style: AddyLoadingButtonStyle
    let content: Content
    var action: () -> () = {}
    
    init(action: @escaping () -> Void, isLoading: Binding<Bool>, style: AddyLoadingButtonStyle? = nil, @ViewBuilder builder: () -> Content) {
        
        let defaultStyle = AddyLoadingButtonStyle(width: .infinity,
                                      height: 56,
                                      cornerRadius: 12,
                                      backgroundColor: Color.accentColor,
                                      loadingColor: Color.accentColor.opacity(0.4),
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
                Rectangle()
                    .fill(isLoading ? style.loadingBackgroundColor : style.backgroundColor)
                    .frame(maxWidth: isLoading ? style.height : style.width, maxHeight: style.height)
                    .cornerRadius(isLoading ? style.height/2 : style.cornerRadius)

                if isLoading {
                    ProgressView()
                }
                else {
                    VStack { content }
                }
            }
        }
        .frame(maxWidth: style.width, maxHeight: style.height)
        .disabled(isLoading)
        .animation(.easeInOut, value: isLoading)
    }
}

