//
//  AddLabelBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 24/06/2026.
//

import addy_shared
import SwiftUI
import WrappingHStack

struct AddLabelBottomSheet: View {
    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""
    @State private var colour: String = "#06b6d4"
    @State private var nameValidationError: String?
    @State private var requestError: String?
    @State private var isLoadingAddButton: Bool = false
    
    let onAdded: (Labels?) -> Void
    
    private let predefinedColours = ["#06b6d4", "#22c55e", "#eab308", "#f97316", "#ef4444", "#8b5cf6", "#64748b", "#ec4899", "#14b8a6", "#3b82f6"]

    var body: some View {
        Form {
            Section {
                ValidatingTextField(value: $name, placeholder: .constant(String(localized: "label_name")), fieldType: .text, error: $nameValidationError)
                
                WrappingHStack(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
                    ForEach(predefinedColours, id: \.self) { hexColour in
                        Rectangle()
                            .fill(Color(hex: hexColour))
                            .frame(width: 40, height: 40)
                            .cornerRadius(self.colour == hexColour ? 20 : 8)
                            .overlay(
                                self.colour == hexColour ?
                                    Image(systemName: "checkmark").foregroundColor(.white) : nil
                            )
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    self.colour = hexColour
                                }
                            }
                    }
                }
                .padding(.vertical)
                
            } header: {
                VStack {
                    Text(String(localized: "label_add_desc"))
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                }.frame(maxWidth: .infinity, alignment: .center)
            } footer: {
                if let error = requestError, !error.isEmpty {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .onAppear {
                            HapticHelper.playHapticFeedback(hapticType: .error)
                        }
                }
            }
            .textCase(nil)
        }
        .navigationTitle(String(localized: "add_label"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if #available(iOS 26.0, *) {
                    saveButton().buttonStyle(.glassProminent)
                } else {
                    saveButton()
                }
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
                Button(String(localized: "add")) {
                    if nameValidationError == nil && !name.isEmpty {
                        isLoadingAddButton = true
                        Task {
                            await self.addLabelToAccount()
                        }
                    } else {
                        HapticHelper.playHapticFeedback(hapticType: .error)
                    }
                }
            }
        }
    }
    
    private func addLabelToAccount() async {
        requestError = nil
        let networkHelper = NetworkHelper()
        do {
            if let newLabel = try await networkHelper.createLabel(label: NewLabel(name: name, colour: colour)) {
                onAdded(newLabel)
                dismiss()
            } else {
                let error = "Failed to create label."
                requestError = error
                isLoadingAddButton = false
                onAdded(nil)
            }
        } catch {
            isLoadingAddButton = false
            requestError = error.localizedDescription
            onAdded(nil)
        }
    }
}
