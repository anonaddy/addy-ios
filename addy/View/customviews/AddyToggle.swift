//
//  AddyToggle.swift
//  addy
//
//  Created by Stijn van de Water on 12/05/2024.
//

import SwiftUI
import addy_shared

struct AddyToggle: View {
    
    @Binding var isOn: Bool
    var isLoading: Bool = false
    var title: String
    var description: String? = nil
    var leadingSystemimage: String? = nil
    var leadingSystemimageColor: Color = .blue
    var fontWeight: Font.Weight = .medium
    @State var lineLimit: Int? = 3
    var onTap: (() -> Void)? = nil

    
    
        
    
    var body: some View {
                    HStack {
                        if let leadingSystemimage = leadingSystemimage {
                            
                            RoundedRectangle(cornerRadius: 6)
                                .fill(leadingSystemimageColor)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: leadingSystemimage)
                                        .fontWeight(fontWeight)
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                )
                                .padding(.trailing)
                            
                        }
                        
                        VStack(alignment: .leading) {
                            Text(title)
                                .foregroundColor(Color.revertedNightMode)
                            
                            if let description = description{
                                Text(description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(lineLimit)
                            }
                            
                        }.frame(maxWidth: .infinity, alignment: .leading)
                        
                        
                        if isLoading {
                            Spacer(minLength: 15)
                            
                            ProgressView() // Loading indicator
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                        
                        Toggle(isOn: $isOn) {}.frame(width: 60) // This will give the Toggle an explicit width
                    }.onTapGesture {
                        if self.onTap != nil {
                            self.onTap?()
                        } else {
                            HapticHelper.playHapticFeedback(hapticType: .tap)
                            isOn = !isOn
                        }
                    }
                    .onLongPressGesture(perform: {
                        HapticHelper.playHapticFeedback(hapticType: .tap)

                        withAnimation {
                            if (self.lineLimit == nil){
                                self.lineLimit = 3

                            } else {
                                self.lineLimit = nil
                            }
                        }
                        
                    })
                    

                
            
            .tint(.accentColor)
            
    }
}


struct AddyToggle_Previews: PreviewProvider {

    static var previews: some View {
        @State var biometricEnabled: Bool = false

        
        AddyToggle(isOn: $biometricEnabled, title: String(localized: "security"),description: String("TESTTESTTESTTEST\nTESTTESTTETTESTTETTESTTETTESTTETTESTTESTTEST\nTEST\nTESTTESTTESTTESTTEST\nTEST"), leadingSystemimage: "faceid", leadingSystemimageColor: .green) {
            print("on tap section")
        }
        
        AddyToggle(isOn: $biometricEnabled, title: String(localized: "security"),description: String(localized: "security_desc"), leadingSystemimage: "faceid", leadingSystemimageColor: .green)
        
    }
}
