//
//  RecipientsViewModel.swift
//  addy
//
//  Created by Stijn van de Water on 09/05/2024.
//

import SwiftUI
import Combine
import addy_shared

class RecipientsViewModel: ObservableObject{
    
    @Published var recipients: [Recipients]? = nil

    @Published var verifiedOnly = false
    @Published var isLoading = false
    @Published var networkError:String = ""
    
    init(){
        Task{
            await self.getRecipients()
        }
    }
    
    func getRecipients() async {
        if !self.isLoading {
            DispatchQueue.main.async {
                self.isLoading = true
                self.networkError = ""
            }
            let networkHelper = NetworkHelper()
            do {
                let recipients = try await networkHelper.getRecipients(verifiedOnly: verifiedOnly)
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.recipients = recipients
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.networkError = String(format: String(localized: "details_about_error_s"), "\(error.localizedDescription)")
                }
            }
        }
    }


}
