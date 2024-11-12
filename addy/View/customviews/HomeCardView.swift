//
//  CardView.swift
//  addy
//
//  Created by Stijn van de Water on 15/07/2024.
//

import SwiftUI


struct HomeCardView: View {
    
    var title: String
    var value: Int
    var backgroundColor: Color
    var systemImage: String
    var systemImageOpacity: Double
    var onTap: (() -> Void)? = nil

    
    var body: some View {
        ZStack() {
            VStack(alignment: .leading) {
                Text(title)
                    .fontWeight(.medium)
                    .lineSpacing(24)
                    .foregroundColor(.white)
                Spacer()

                HStack {
                    Image(systemName: systemImage)
                        .fontWeight(.semibold)
                        .font(.system(size: 24))
                        .lineSpacing(24)
                        .foregroundColor(.white)
                        .padding(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
                        .cornerRadius(1024)
                        .opacity(systemImageOpacity)
                    Spacer()

                    Text(value, format: .number)
                        .fontWeight(.semibold)
                        .font(.system(size: 32))
                        .lineSpacing(24)
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.01)
                        .contentTransition(.numericText())
                            .animation(.spring(duration: 0.2), value: value)
                }
                
                
                
            }
            .padding()
        }
        .background(backgroundColor)
        .frame(height: 92)
        .cornerRadius(16)
        .shadow(
            color: Color(red: 0, green: 0, blue: 0, opacity: 0.08), radius: 12
        ).apply {
            if onTap != nil {
                $0.onTapGesture {
                    onTap!()
                }
            } else {
                $0
            }
        }
    }
}

#Preview {
    HomeCardView(title: "Emails forwarded", value: 151, backgroundColor: .softRed, systemImage: "tray", systemImageOpacity: 1){
        print("ONTAP")
    }        .frame(width: 178.50)

    
    HomeCardView(title: "Emails forwarded", value: 3, backgroundColor: .accent, systemImage: "at.circle.fill", systemImageOpacity: 0.5){
        print("ONTAP")
    }        .frame(maxWidth: .infinity)
    
    HomeCardView(title: "Emails forwarded", value: 122, backgroundColor: .teal, systemImage: "tray", systemImageOpacity: 0.2){
        print("ONTAP")
    }        .frame(maxWidth: .infinity)

}
