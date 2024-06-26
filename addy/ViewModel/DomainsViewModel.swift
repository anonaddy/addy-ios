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
        Task {
            await self.getDomains()
        }
    }
    
    func getDomains() async {
        if !self.isLoading {
            DispatchQueue.main.async {
                self.isLoading = true
                self.networkError = ""
            }
            let networkHelper = NetworkHelper()
            do {
                let domains = try await networkHelper.getDomains()
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.domains = domains
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
