//
//  ShareViewControllerPendingUrlView.swift
//  addy
//
//  Created by Stijn van de Water on 20/07/2024.
//

import SwiftUI

struct ShareViewControllerPendingUrlView: View {
    
    @State var pendingURLFromShareViewController: IdentifiableURL
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack() {
            Text(String(localized: "shareviewcontroller_pending_url_open")).padding(.bottom)
            Button(String(localized: "send_mail")) {
                UIApplication.shared.open(pendingURLFromShareViewController.url, options: [:], completionHandler: {_ in dismiss()
                })
            }.buttonStyle(.borderedProminent).controlSize(.large)

            
        }.padding()
            .navigationTitle(String(localized: "integration_mailto_alias"))
            .pickerStyle(.navigationLink)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text(String(localized: "cancel"))
                    }
                    
                }
            })
    }
}

#Preview {
    ShareViewControllerPendingUrlView(pendingURLFromShareViewController: IdentifiableURL(url: URL(string: "https://stjin.dev")!))
}
