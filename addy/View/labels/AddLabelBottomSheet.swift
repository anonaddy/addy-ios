//
//  AddLabelBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 24/06/2026.
//

import addy_shared
import SwiftUI

struct AddLabelBottomSheet: View {
    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""
    @State private var colour: String = "#78909C"
    @State private var nameValidationError: String?
    @State private var requestError: String?
    @State private var isLoadingAddButton: Bool = false

    let onAdded: () -> Void

    private let colors = ["#06b6d4, #22c55e, #eab308, #f97316, #ef4444, #8b5cf6, #64748b, #ec4899, #14b8a6, #3b82f6"]

    var body: some View {
        Form {
            Section {
                ValidatingTextField(value: $name, placeholder: .constant("Label name"), fieldType: .text, error: $nameValidationError)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.accentColor, lineWidth: self.colour == color ? 2 : 0)
                                )
                                .scaleEffect(self.colour == color ? 1.2 : 1.0)
                                .onTapGesture {
                                    withAnimation {
                                        self.colour = color
                                    }
                                }
                        }
                    }
                }
                .frame(height: 50)
            } header: {
                VStack {
                    Text(String(localized: "label_add_desc"))
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                }.frame(maxWidth: .infinity, alignment: .center)
            } footer: {
                if let error = requestError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.system(size: 15))
                        .multilineTextAlignment(.leading)
                        .padding([.horizontal], 0)
                        .onAppear {
                            HapticHelper.playHapticFeedback(hapticType: .error)
                        }
                }
            }.textCase(nil)
        }
        .navigationTitle(String(localized: "label_add"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                saveButton()
            }
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Label(String(localized: "cancel", bundle: Bundle(for: SharedData.self)), systemImage: "xmark")
                }
            }
        }
    }

    private func saveButton() -> some View {
        Group {
            if isLoadingAddButton {
                ProgressView().progressViewStyle(.circular)
            } else {
                Button {
                    if nameValidationError == nil && !name.isEmpty {
                        isLoadingAddButton = true
                        Task {
                            await self.addLabelToAccount()
                        }
                    } else {
                        HapticHelper.playHapticFeedback(hapticType: .error)
                        isLoadingAddButton = false
                    }
                } label: {
                    Text(String(localized: "add"))
                }
            }
        }
    }

    private func addLabelToAccount() async {
        requestError = nil
        let networkHelper = NetworkHelper()
        do {
            _ = try await networkHelper.createLabel(name: name, colour: colour)
            onAdded()
            dismiss()
        } catch {
            isLoadingAddButton = false
            requestError = error.localizedDescription
        }
    }
}
