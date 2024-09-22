//
//  FeaturesView.swift
//  addy
//
//  Created by Stijn van de Water on 19/09/2024.
//

import SwiftUI


struct FeaturesView: View {
    let items: [String]
    
    init(plan: String) {
        if plan == "pro" {
            self.items = [String(localized: "why_subscribe_reason_1_pro"),
                          String(localized: "why_subscribe_reason_8_pro"),
                          String(localized: "why_subscribe_reason_2_pro"),
                          String(localized: "why_subscribe_reason_3_pro"),
                          String(localized: "why_subscribe_reason_4_pro"),
                          String(localized: "why_subscribe_reason_5_pro"),
                          String(localized: "why_subscribe_reason_6_pro"),
                          String(localized: "why_subscribe_reason_13"),
                          String(localized: "why_subscribe_reason_12"),
                          String(localized: "why_subscribe_reason_9"),
                          String(localized: "why_subscribe_reason_10"),
                          String(localized: "why_subscribe_reason_11"),
                          String(localized: "why_subscribe_reason_7_pro"),
                          String(localized: "why_subscribe_reason_14")]
        } else if plan == "lite" {
            self.items = [String(localized: "why_subscribe_reason_1_lite"),
                          String(localized: "why_subscribe_reason_8_lite"),
                          String(localized: "why_subscribe_reason_2_lite"),
                          String(localized: "why_subscribe_reason_3_lite"),
                          String(localized: "why_subscribe_reason_4_lite"),
                          String(localized: "why_subscribe_reason_5_lite"),
                          String(localized: "why_subscribe_reason_6_lite"),
                          String(localized: "why_subscribe_reason_13"),
                          String(localized: "why_subscribe_reason_12"),
                          String(localized: "why_subscribe_reason_9"),
                          String(localized: "why_subscribe_reason_10"),
                          String(localized: "why_subscribe_reason_11"),
                          String(localized: "why_subscribe_reason_7_lite"),
                          String(localized: "why_subscribe_reason_14")]
        } else {
            self.items = [String(localized: "why_subscribe_reason_9"),
                          String(localized: "why_subscribe_reason_10"),
                          String(localized: "why_subscribe_reason_11"),
                          String(localized: "why_subscribe_reason_12"),
                          String(localized: "why_subscribe_reason_13"),
                          String(localized: "why_subscribe_reason_14")]
        }
        
    }
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "why_subscribe_title"))
                .font(.headline)
            ForEach(items, id: \.self) { item in
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accent)
                    Text(item)
                        .font(.subheadline)
                }
            }
            
            
            
        }.frame(
            minWidth: 0,
            maxWidth: .infinity,
            minHeight: 0,
            alignment: .topLeading
          )
        
    }
}

#Preview {
    FeaturesView(plan: "pro")
}
