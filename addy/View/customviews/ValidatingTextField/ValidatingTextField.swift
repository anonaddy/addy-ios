//
//  ValidatingTextField.swift
//  addy
//
//  Created by Stijn van de Water on 07/05/2024.
//

import SwiftUI
import addy_shared

public struct ValidatingTextField: View {
    @Binding var value: String
    @Binding var placeholder: String
    public var fieldType: FieldType
    @Binding var error: String?
    
    // Add a public initializer
    public init(value: Binding<String>, placeholder: Binding<String>, fieldType: FieldType, error: Binding<String?>) {
        self._value = value
        self._placeholder = placeholder
        self.fieldType = fieldType
        self._error = error
    }
    
    
    public var body: some View {

        VStack(alignment: .leading){
            if (fieldType == .bigText){
                
                VStack(alignment: .leading){
                    // Your existing code...
                    ScrollView {
                        TextEditor(text: $value)
                            .onChange(of: value) {
                                withAnimation {
                                    error = fieldType.validate(value: value)
                                }
                            }
                            .frame(height: 150)
                            .disableAutocorrection(true)
                            .keyboardType(fieldType.getKeyboardType())
                    }
                    .scrollContentBackground(.hidden)
                    .frame(height: 150)
                    
                    
                }.overlay {
                    if value.isEmpty {
                        TextEditor(text: self.$placeholder)
                            .font(.body)
                            .foregroundColor(.gray.opacity(0.5))
                            .disabled(true)
                            .frame(height: 150)
                    }
                }
                
                
            } else {
                TextField(placeholder, text: $value)
                    .onChange(of: value) {
                        withAnimation {
                            error = fieldType.validate(value: value)
                        }
                    }
                
                    .disableAutocorrection(true)
                    .keyboardType(fieldType.getKeyboardType())
            }
            
            
            if let error = error {
                if !error.isEmpty {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.system(size: 15))
                        .multilineTextAlignment(.leading)
                        .padding([.horizontal], 0)
                        .onAppear{
                            HapticHelper.playHapticFeedback(hapticType: .error)
                        }
                }
                
            }
            
        }
    }
}
