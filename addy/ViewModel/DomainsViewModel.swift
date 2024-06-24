//
//  DomainsViewModel.swift
//  addy
//
//  Created by Stijn van de Water on 01/06/2024.
//

import SwiftUI
import Combine
import addy_shared

class DomainsViewModel: ObservableObject{
    
    @Published var domains: DomainsArray? = nil

    @Published var isLoading = false
    @Published var networkError:String = ""
    
    init(){
        self.getDomains()
    }
    
    func getDomains(){
        if (!self.isLoading){
            self.isLoading = true
            self.networkError = ""
            
            let networkHelper = NetworkHelper()
            networkHelper.getDomains(completion: { domains, error in
                    DispatchQueue.main.async {
                        self.isLoading = false

                        if let domains = domains {
                            self.domains = domains
                        } else {
                            self.networkError = String(format: String(localized: "details_about_error_s"),"\(error ?? String(localized: "error_unknown_refer_to_logs"))")
                        }
                    }
            })
        }
    }
}
