import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct CertificatePicker: UIViewControllerRepresentable {
    @Binding var certificateData: Data?

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pkcs12])
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: CertificatePicker

        init(_ parent: CertificatePicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            do {
                parent.certificateData = try Data(contentsOf: url)
            } catch {
                print("Error reading certificate data: \(error)")
            }
        }
    }
}
