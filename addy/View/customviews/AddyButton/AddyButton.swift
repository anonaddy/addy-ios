import SwiftUI

struct AddyButton<Content: View>: View{
    
    var style: AddyButtonStyle
    let content: Content
    var action: () -> () = {}
    
    init(action: @escaping () -> Void, style: AddyButtonStyle? = nil, @ViewBuilder builder: () -> Content) {
        
        let defaultStyle = AddyButtonStyle(width: .infinity,
                                           height: 56,
                                           cornerRadius: 12,
                                           buttonStyle: .primary,
                                           backgroundColor: Color("AccentColor"),
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
            ZStack {
                Rectangle()
                    .fill(style.buttonStyle == .primary ? style.backgroundColor : style.backgroundColor.opacity(0.4))
                    .frame(maxWidth: style.width, maxHeight: style.height)
                    .cornerRadius(style.cornerRadius)
                VStack { content }
                
            }
        }
        .frame(maxWidth: style.width, maxHeight: style.height)
        //.disabled(isLoading)
        //.animation(.easeInOut, value: isLoading)
    }
}

