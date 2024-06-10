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
    
    var body: some View {
                    
            Toggle(isOn: $isOn) {
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
                        
                    }
                    if isLoading {
                        Spacer(minLength: 15)
                        
                        ProgressView() // Loading indicator
                            .progressViewStyle(CircularProgressViewStyle())
                    }

                }
            }//.simultaneousGesture(
//                LongPressGesture(minimumDuration: 1.0)
//                    .onEnded { _ in
//                        //TODO: Fix scrolling issue and implement this in the other sections as well
//                        HapticHelper.playHapticFeedback(hapticType: .tap)
//
//                        if (self.lineLimit == nil){
//                            self.lineLimit = 3
//
//                        } else {
//                            self.lineLimit = nil
//                        }
//                    }
//            )
            .tint(.accentColor)
            
    }
}

