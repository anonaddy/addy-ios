import SwiftUI
import addy_shared

struct CertificatePasswordView: View {
    @State private var password = ""
    @Binding var certificateData: Data?
    @Binding var certificatePass: String?
    
    @Environment(\.dismiss) var dismiss
    
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(String(localized: "enter_certificate_password")), footer:
                    Group {
                        if let error = error {
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
                ) {
                    SecureField(String(localized: "password"), text: $password)
                }
            }
            .navigationTitle(String(localized: "certificate_password"))
            .toolbar(content: {
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
            })
            
        }
    }
    
    private func saveButton() -> some View {
        Button(String(localized: "save")) {
            guard let data = certificateData else { return }
                verifyPassword(certificateData: data, password: password) { success in
                    if success {
                        certificatePass = password
                        dismiss()
                    }
            }
        }
    }
    
    private func verifyPassword(certificateData: Data, password: String, completion: @escaping (Bool) -> Void) {
        self.isLoading = true
        self.error = nil

        DispatchQueue.global().async {
            let networkHelper = NetworkHelper(p12: certificateData, p12Password: password)
            let success = networkHelper.isCertificatePasswordCorrect()

            DispatchQueue.main.async {
                self.isLoading = false
                if !success {
                    self.error = String(localized: "invalid_password")
                }
                completion(success)
            }
        }
    }
}
