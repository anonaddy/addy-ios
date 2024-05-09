//
//  AliasDetailView.swift
//  addy
//
//  Created by Stijn van de Water on 08/05/2024.
//

import SwiftUI
import addy_shared

struct AliasDetailView: View {
    
    var aliasId: String
    
    @Environment(\.dismiss) private var dismiss
        
    var body: some View {

            VStack {
                
                
                ScrollView {
                    
                    HStack {
                        VStack(alignment: .leading) {
                            
                            Text(aliasId)
                                .font(.title)
                                .padding()
                            
                            Text(aliasId)
                                .padding()
                            
                            Spacer()
                        }
                        
                        Spacer()
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.backward.circle.fill")
                            .tint(.black)
                    }
                    .font(.title)
                }
        }
    }
}

#Preview {
    // TODO: preview remove this demo
    AliasDetailView(aliasId: "fc2e09ef-9e3a-41a6-876b-6ed7c8e987c6")
}
