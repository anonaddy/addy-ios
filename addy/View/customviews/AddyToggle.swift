//
//  AddyToggle.swift
//  addy
//
//  Created by Stijn van de Water on 12/05/2024.
//

import SwiftUI

struct AddyToggle: View {
    
    @Binding var isOn: Bool
    var isLoading: Bool = false
    var title: String
    var description: String? = nil
    
    var body: some View {
                    
            Toggle(isOn: $isOn) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(title)
                            .font(.callout)
                        
                        if let description = description{
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                    }
                    if isLoading {
                        Spacer(minLength: 15)
                        
                        ProgressView() // Loading indicator
                            .progressViewStyle(CircularProgressViewStyle())
                    }

                }
            }
            .tint(.accentColor)
            
    }
}

