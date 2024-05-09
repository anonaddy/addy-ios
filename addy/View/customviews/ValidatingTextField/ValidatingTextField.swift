//
//  CommonTextField.swift
//  addy
//
//  Created by Stijn van de Water on 07/05/2024.
//

import SwiftUI

struct ValidatingTextField: View {
    @Binding var value: String
    var placeholder: String?
    var fieldType: FieldType
    @Binding var error: String?
    
    
    var body: some View {
        VStack(alignment: .leading){
            if (fieldType == .bigText){
                TextEditor(text: $value)
                    .onChange(of: value) {
                       error = fieldType.validate(value: value)
                    }
                
                    .frame(height: 150)
                    .scrollContentBackground(.hidden)
                    .padding(.all)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.1), lineWidth: 2))
                    .disableAutocorrection(true)
            } else {
                TextField(placeholder ?? "", text: $value)
                    .onChange(of: value) {
                        error = fieldType.validate(value: value)
                    }
                
                    .scrollContentBackground(.hidden)
                    .padding(.all)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.1), lineWidth: 2))
                    .disableAutocorrection(true)
            }
            
            if let error = error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.system(size: 15))
                    .multilineTextAlignment(.leading)
                    .padding([.horizontal], 0)
            }
        }
    }
}
