//
//  CommonTextField.swift
//  addy
//
//  Created by Stijn van de Water on 07/05/2024.
//

import SwiftUI
import addy_shared

struct ValidatingTextField: View {
    @Binding var value: String
    @Binding var placeholder: String
    var fieldType: FieldType
    @Binding var error: String?
    var formStyling: Bool = false
    
    
    var body: some View {
        VStack(alignment: .leading){
            if (formStyling){
                if (fieldType == .bigText){
                    
                    ZStack {
                        if value.isEmpty {
                            TextEditor(text: self.$placeholder)
                                .font(.body)
                                .foregroundColor(.gray.opacity(0.5))
                                .disabled(true)
                                .frame(height: 150)
                        }
                        
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
            } else {
                if (fieldType == .bigText){
                    
                    if (fieldType == .bigText){
                        
                        ZStack {
                            if value.isEmpty {
                                TextEditor(text: self.$placeholder)
                                    .font(.body)
                                    .foregroundColor(.gray.opacity(0.5))
                                    .disabled(true)
                                    .frame(height: 150)

                            }
                            
                            TextEditor(text: $value)
                                .onChange(of: value) {
                                    withAnimation {
                                        error = fieldType.validate(value: value)
                                    }
                                }
                                .frame(height: 150)
                                .scrollContentBackground(.hidden)
                                .padding(.all)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.1), lineWidth: 2))
                                .disableAutocorrection(true)
                                .keyboardType(fieldType.getKeyboardType())
                        }
                        
                    } else {
                        TextField(placeholder, text: $value)
                            .onChange(of: value) {
                                withAnimation {
                                    error = fieldType.validate(value: value)
                                }
                            }
                        
                            .scrollContentBackground(.hidden)
                            .padding(.all)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.1), lineWidth: 2))
                            .disableAutocorrection(true)
                            .keyboardType(fieldType.getKeyboardType())
                    }
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
}
