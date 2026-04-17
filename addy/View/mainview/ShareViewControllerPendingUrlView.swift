//
//  ShareViewControllerPendingUrlView.swift
//  addy
//
//  Created by Stijn van de Water on 20/07/2024.
//

import SwiftUI
import addy_shared

struct ShareViewControllerPendingUrlView: View {
    @Environment(\.dismiss) var dismiss

    @State var pendingURLFromShareViewController: IdentifiableURL

    var body: some View {
        VStack {
            Text(String(localized: "shareviewcontroller_pending_url_open")).padding(.bottom)
            Button(String(localized: "send_mail")) {
                UIApplication.shared.open(pendingURLFromShareViewController.url, options: [:], completionHandler: { _ in dismiss()
                })
            }.buttonStyle(.borderedProminent).controlSize(.large)

        }.padding()
            .navigationTitle(String(localized: "integration_mailto_alias"))
            .pickerStyle(.navigationLink)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
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

#Preview {
    ShareViewControllerPendingUrlView(pendingURLFromShareViewController: IdentifiableURL(url: URL(string: "https://stjin.dev")!))
}
