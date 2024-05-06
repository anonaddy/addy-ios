import SwiftUI

public struct AddyButton<Content: View>: View{

    var style: AddyButtonStyle
    let content: Content
    var action: () -> () = {}
    
    public init(action: @escaping () -> Void, style: AddyButtonStyle? = nil, @ViewBuilder builder: () -> Content) {
        
        let defaultStyle = AddyButtonStyle(width: .infinity,
                                      height: 56,
                                      cornerRadius: 12,
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
                    .fill(style.backgroundColor)
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

