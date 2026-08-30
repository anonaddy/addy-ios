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

    var labelToEdit: Labels? = nil
    @State private var name: String = ""
    @State private var colour: String = "#06b6d4"
    @State private var nameValidationError: String?
    @State private var requestError: String?
    @State private var isLoadingSaveButton: Bool = false
    
    let onSaved: ((Labels?) -> Void)?
    
    init(labelToEdit: Labels? = nil, onSaved: ((Labels?) -> Void)? = nil) {
        self.labelToEdit = labelToEdit
        self.onSaved = onSaved
        _name = State(initialValue: labelToEdit?.name ?? "")
        _colour = State(initialValue: labelToEdit?.colour ?? "#06b6d4")
    }
    
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
                    Text(labelToEdit != nil ? String(localized: "label_add_desc") : String(localized: "label_add_desc"))
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
        .navigationTitle(labelToEdit != nil ? String(localized: "edit_label") : String(localized: "add_label"))
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
            if isLoadingSaveButton {
                ProgressView().progressViewStyle(.circular)
            } else {
                Button(labelToEdit != nil ? String(localized: "save") : String(localized: "add")) {
                    if nameValidationError == nil && !name.isEmpty {
                        isLoadingSaveButton = true
                        Task {
                            if let labelToEdit = labelToEdit {
                                await self.updateLabelInAccount(labelId: labelToEdit.id)
                            } else {
                                await self.addLabelToAccount()
                            }
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
        do {
            let newLabel = try await LabelRepository.shared.createLabel(label: NewLabel(name: name, colour: colour))
            onSaved?(newLabel)
            dismiss()
        } catch {
            isLoadingSaveButton = false
            requestError = error.localizedDescription
        }
    }

    private func updateLabelInAccount(labelId: String) async {
        requestError = nil
        do {
            let result = try await LabelRepository.shared.updateLabel(labelId: labelId, name: name, colour: colour)
            if result == "200" {
                onSaved?(nil)
                dismiss()
            } else {
                isLoadingSaveButton = false
                requestError = result
            }
        } catch {
            isLoadingSaveButton = false
            requestError = error.localizedDescription
        }
    }
}
