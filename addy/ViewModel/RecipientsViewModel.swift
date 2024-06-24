//
//  AliasesViewModel.swift
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
        self.getRecipients()
    }
    
    func getRecipients(){
        if (!self.isLoading){
            self.isLoading = true
            self.networkError = ""
            
            let networkHelper = NetworkHelper()
            networkHelper.getRecipients(verifiedOnly: verifiedOnly, completion: { recipients, error in
                    DispatchQueue.main.async {
                        self.isLoading = false

                        if let recipients = recipients {
                            self.recipients = recipients
                        } else {
                            self.networkError = String(format: String(localized: "details_about_error_s"),"\(error ?? String(localized: "error_unknown_refer_to_logs"))")
                        }
                    }
            })
        }
    }
}
