//
//  ValidatingTextField.swift
//  addy
//
//  Created by Stijn van de Water on 07/05/2024.
//

import addy_shared
import SwiftUI

struct ValidatingTextField: View {
    @Binding var value: String
    var placeholder: String
    @Binding var error: String?
    var fieldType: FieldType

    var body: some View {
        VStack(alignment: .leading) {
            if fieldType == .bigText {
                VStack(alignment: .leading) {
                    ScrollView {
                        TextEditor(text: $value)
                            .onChange(of: value) {
                                withAnimation {
                                    error = fieldType.validate(value: value)
                                }
                            }
                            .frame(height: 150)
                            .scrollContentBackground(.hidden)
                            .autocorrectionDisabled(true)
                            .keyboardType(fieldType.getKeyboardType())
                    }
                    .scrollContentBackground(.hidden)
                    .frame(height: 150)

                }.overlay {
                    if value.isEmpty {
                        TextEditor(text: .constant(placeholder))
                            .font(.body)
                            .foregroundColor(.gray.opacity(0.5))
                            .disabled(true)
                            .frame(height: 150)
                    }
                }

            } else if fieldType == .password {
                SecureField(placeholder, text: $value)
                    .onChange(of: value) {
                        withAnimation {
                            error = fieldType.validate(value: value)
                        }
                    }

                    .autocorrectionDisabled(true)
                    .keyboardType(fieldType.getKeyboardType())

            } else {
                TextField(placeholder, text: $value)
                    .onChange(of: value) {
                        withAnimation {
                            error = fieldType.validate(value: value)
                        }
                    }

                    .autocorrectionDisabled(true)
                    .keyboardType(fieldType.getKeyboardType())
            }

            if let error = error {
                if !error.isEmpty {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.system(size: 15))
                        .multilineTextAlignment(.leading)
                        .padding([.horizontal], 0)
                        .onAppear {
                            HapticHelper.playHapticFeedback(hapticType: .error)
                        }
                }
            }
        }
    }

    init(value: Binding<String>, placeholder: String, fieldType: FieldType, error: Binding<String?>) {
        _value = value
        self.placeholder = placeholder
        self.fieldType = fieldType
        _error = error
    }

    init(value: Binding<String>, placeholder: Binding<String>, fieldType: FieldType, error: Binding<String?>) {
        _value = value
        self.placeholder = placeholder.wrappedValue
        self.fieldType = fieldType
        _error = error
    }
}

struct ValidatingTextField_Previews: PreviewProvider {
    static var previews: some View {
        @State var addressesValidationError: String?
        @State var addresses = ""

        ValidatingTextField(value: $addresses, placeholder: String(localized: "addresses"), fieldType: .bigText, error: $addressesValidationError)
    }
}
